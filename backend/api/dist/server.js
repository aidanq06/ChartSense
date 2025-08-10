import Fastify from 'fastify';
import dotenv from 'dotenv';
import { Pool } from 'pg';
import { z } from 'zod';
import fastifySensible from '@fastify/sensible';
import { signAccessToken, verifyAccessToken, hashPassword, verifyPassword, generateRefreshToken, createSession, findUserIdByRefreshToken, revokeSessionByToken, } from './auth.js';
dotenv.config({ path: process.env.DOTENV_PATH || undefined });
const app = Fastify({ logger: true });
await app.register(fastifySensible);
// Database
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
// Auth: Prefer Authorization: Bearer <jwt>; fallback to X-User-Id in dev
app.addHook('preHandler', async (request) => {
    const openRoutes = new Set([
        '/healthz',
        '/v1/auth/register',
        '/v1/auth/login',
        '/v1/auth/refresh',
    ]);
    const route = request.routerPath ?? '';
    if (openRoutes.has(route))
        return;
    const auth = request.headers['authorization'];
    if (auth && auth.startsWith('Bearer ')) {
        const token = auth.slice(7);
        const claims = verifyAccessToken(token);
        if (!claims?.sub)
            throw app.httpErrors.unauthorized('Invalid token');
        request.userId = claims.sub;
        return;
    }
    const devUser = request.headers['x-user-id'];
    if (devUser) {
        request.userId = devUser;
        return;
    }
    throw app.httpErrors.unauthorized('Unauthorized');
});
// Utility: determine user's chat limit from subscription
async function getUserChatLimit(userId) {
    const sql = `
    select s.tier, s.expires_at, s.status
    from subscriptions s
    where s.user_id = $1
    order by coalesce(s.renewed_at, s.created_at) desc
    limit 1;
  `;
    const { rows } = await pool.query(sql, [userId]);
    const sub = rows[0];
    const now = new Date();
    const active = sub && sub.status === 'active' && (!sub.expires_at || new Date(sub.expires_at) > now);
    return active && (sub.tier === 'premium' || sub.tier === 'pro') ? 200 : 20;
}
// Enforce and increment AI chat daily usage in a race-safe way
async function requireAndIncrementDailyChatAllowance(userId) {
    const limit = await getUserChatLimit(userId);
    // Ensure row exists with the correct limit
    await pool.query('insert into ai_chat_usage_daily (user_id, day, used, daily_limit) values ($1, current_date, 0, $2) on conflict (user_id, day) do update set daily_limit = excluded.daily_limit', [userId, limit]);
    // Increment if under limit
    const { rows, rowCount } = await pool.query('update ai_chat_usage_daily set used = used + 1 where user_id = $1 and day = current_date and used < daily_limit returning used, daily_limit', [userId]);
    if (rowCount === 0) {
        const { rows: cur } = await pool.query('select used, daily_limit from ai_chat_usage_daily where user_id = $1 and day = current_date', [userId]);
        const r = cur[0];
        if (!r)
            throw new Error('quota_check_failed');
        throw app.httpErrors.tooManyRequests('AI chat daily limit reached');
    }
}
// Routes
app.get('/healthz', async () => ({ ok: true }));
// Auth routes
app.post('/v1/auth/register', async (request) => {
    const schema = z.object({ email: z.string().email(), password: z.string().min(8), display_name: z.string().optional() });
    const body = schema.parse(request.body ?? {});
    const passwordHash = await hashPassword(body.password);
    const { rows } = await pool.query('insert into users (email, password_hash, display_name) values ($1,$2,$3) returning id', [body.email.toLowerCase(), passwordHash, body.display_name ?? null]);
    const userId = rows[0].id;
    const refreshToken = generateRefreshToken();
    await createSession(pool, userId, refreshToken);
    return { access_token: signAccessToken(userId), refresh_token: refreshToken };
});
app.post('/v1/auth/login', async (request, reply) => {
    const schema = z.object({ email: z.string().email(), password: z.string().min(8) });
    const body = schema.parse(request.body ?? {});
    const { rows } = await pool.query('select id, password_hash from users where email = $1', [body.email.toLowerCase()]);
    if (!rows.length || !rows[0].password_hash)
        return reply.unauthorized('Invalid credentials');
    const ok = await verifyPassword(rows[0].password_hash, body.password);
    if (!ok)
        return reply.unauthorized('Invalid credentials');
    const userId = rows[0].id;
    const refreshToken = generateRefreshToken();
    await createSession(pool, userId, refreshToken);
    return { access_token: signAccessToken(userId), refresh_token: refreshToken };
});
app.post('/v1/auth/refresh', async (request, reply) => {
    const schema = z.object({ refresh_token: z.string().min(10) });
    const body = schema.parse(request.body ?? {});
    const userId = await findUserIdByRefreshToken(pool, body.refresh_token);
    if (!userId)
        return reply.unauthorized('Invalid refresh token');
    return { access_token: signAccessToken(userId) };
});
app.post('/v1/auth/logout', async (request, reply) => {
    const schema = z.object({ refresh_token: z.string().min(10) });
    const body = schema.parse(request.body ?? {});
    const userId = request.userId;
    await revokeSessionByToken(pool, userId, body.refresh_token);
    return { ok: true };
});
// Watchlists
app.get('/v1/watchlists', async (request) => {
    const userId = request.userId;
    const { rows } = await pool.query('select w.id, w.name, w.is_default, w.position, coalesce(json_agg(json_build_object(\'symbol\', wi.symbol, \'position\', wi.position) order by wi.position) filter (where wi.symbol is not null), \'[]\'::json) as items from watchlists w left join watchlist_items wi on wi.watchlist_id = w.id where w.user_id = $1 group by w.id order by w.position', [userId]);
    return { watchlists: rows };
});
app.post('/v1/watchlists', async (request) => {
    const userId = request.userId;
    const name = request.body?.name ?? 'Watchlist';
    const { rows } = await pool.query('insert into watchlists (user_id, name, is_default, position) values ($1, $2, false, 0) returning id, name, is_default, position', [userId, name]);
    return rows[0];
});
app.post('/v1/watchlists/:id/items', async (request, reply) => {
    const userId = request.userId;
    const watchlistId = request.params.id;
    const { symbol, position } = request.body;
    // Ensure watchlist belongs to user
    const { rows: w } = await pool.query('select 1 from watchlists where id = $1 and user_id = $2', [watchlistId, userId]);
    if (!w.length)
        return reply.notFound('Watchlist not found');
    await pool.query('insert into watchlist_items (watchlist_id, symbol, position) values ($1, $2, coalesce($3, 0)) on conflict (watchlist_id, symbol) do update set position = excluded.position', [watchlistId, symbol, position ?? 0]);
    return { ok: true };
});
app.delete('/v1/watchlists/:id/items/:symbol', async (request) => {
    const userId = request.userId;
    const { id, symbol } = request.params;
    await pool.query('delete from watchlist_items using watchlists w where watchlist_items.watchlist_id = w.id and w.user_id = $1 and w.id = $2 and watchlist_items.symbol = $3', [userId, id, symbol]);
    return { ok: true };
});
// Alerts
app.post('/v1/alerts', async (request) => {
    const userId = request.userId;
    const { symbol, type, threshold, window_minutes, channel } = request.body;
    const { rows } = await pool.query('insert into alert_rules (user_id, symbol, type, threshold, window_minutes, channel) values ($1, $2, $3::alert_type, $4, $5, coalesce($6, \'{push}\')) returning id', [userId, symbol, type, threshold, window_minutes ?? null, channel ?? ['push']]);
    return { id: rows[0].id };
});
// Market data (served from cache tables)
app.get('/v1/market/quote', async (request, reply) => {
    const symbol = request.query.symbol;
    if (!symbol)
        return reply.badRequest('symbol required');
    const { rows } = await pool.query('select * from quotes_latest where symbol = $1', [symbol]);
    if (!rows.length)
        return reply.notFound('quote not found');
    return rows[0];
});
app.get('/v1/market/candles', async (request, reply) => {
    const { symbol, timeframe = '5m', from, to } = request.query;
    if (!symbol)
        return reply.badRequest('symbol required');
    const table = timeframe === '1d' ? 'candles_1d' : 'candles_5m';
    const clauses = ['symbol = $1'];
    const params = [symbol];
    if (from) {
        clauses.push(timeframe === '1d' ? 'day >= $2::date' : 'ts >= $2::timestamptz');
        params.push(from);
    }
    if (to) {
        clauses.push(timeframe === '1d' ? 'day <= $3::date' : 'ts <= $3::timestamptz');
        params.push(to);
    }
    const where = clauses.join(' and ');
    const { rows } = await pool.query(`select * from ${table} where ${where} order by ${timeframe === '1d' ? 'day' : 'ts'}`, params);
    return { candles: rows };
});
// AI chat endpoint (quota enforced; you will call your LLM provider from here)
app.post('/v1/ai/chat', async (request) => {
    const userId = request.userId;
    await requireAndIncrementDailyChatAllowance(userId);
    // TODO: call LLM provider (e.g., OpenAI) and return response.
    return { reply: 'This is a placeholder AI response.' };
});
// Notification settings
app.get('/v1/notification-settings', async (request) => {
    const userId = request.userId;
    const { rows } = await pool.query('select push_enabled, email_enabled, quiet_hours_start, quiet_hours_end from notification_settings where user_id = $1', [userId]);
    if (!rows.length) {
        return { push_enabled: true, email_enabled: false, quiet_hours_start: null, quiet_hours_end: null };
    }
    return rows[0];
});
app.put('/v1/notification-settings', async (request) => {
    const schema = z.object({
        push_enabled: z.boolean().optional(),
        email_enabled: z.boolean().optional(),
        quiet_hours_start: z
            .string()
            .regex(/^\d{2}:\d{2}(?::\d{2})?$/)
            .nullable()
            .optional(),
        quiet_hours_end: z
            .string()
            .regex(/^\d{2}:\d{2}(?::\d{2})?$/)
            .nullable()
            .optional(),
    });
    const body = schema.parse(request.body ?? {});
    const userId = request.userId;
    const { push_enabled, email_enabled, quiet_hours_start, quiet_hours_end } = body;
    await pool.query(`insert into notification_settings (user_id, push_enabled, email_enabled, quiet_hours_start, quiet_hours_end)
     values ($1, coalesce($2,true), coalesce($3,false), $4::time, $5::time)
     on conflict (user_id) do update set
       push_enabled = coalesce(excluded.push_enabled, notification_settings.push_enabled),
       email_enabled = coalesce(excluded.email_enabled, notification_settings.email_enabled),
       quiet_hours_start = excluded.quiet_hours_start,
       quiet_hours_end = excluded.quiet_hours_end`, [userId, push_enabled ?? null, email_enabled ?? null, quiet_hours_start ?? null, quiet_hours_end ?? null]);
    return { ok: true };
});
// Device registration (for push notifications)
app.post('/v1/devices', async (request) => {
    const schema = z.object({ platform: z.enum(['ios', 'android', 'web']), push_token: z.string().min(10), locale: z.string().optional() });
    const body = schema.parse(request.body ?? {});
    const userId = request.userId;
    await pool.query(`insert into devices (user_id, platform, push_token, locale)
     values ($1, $2, $3, $4)
     on conflict (push_token) do update set user_id = excluded.user_id, platform = excluded.platform, locale = excluded.locale`, [userId, body.platform, body.push_token, body.locale ?? null]);
    return { ok: true };
});
// Subscription info
app.get('/v1/me/subscription', async (request) => {
    const userId = request.userId;
    const { rows } = await pool.query(`select tier, status, expires_at from subscriptions where user_id = $1 order by coalesce(renewed_at, created_at) desc limit 1`, [userId]);
    return rows[0] ?? { tier: 'free', status: 'inactive', expires_at: null };
});
app.post('/v1/me/subscription', async (request) => {
    const schema = z.object({
        tier: z.enum(['free', 'premium', 'pro']),
        provider: z.string().min(2),
        product_id: z.string().min(1).optional(),
        status: z.string().default('active'),
        expires_at: z.string().datetime().nullable().optional(),
    });
    const body = schema.parse(request.body ?? {});
    const userId = request.userId;
    const { tier, provider, product_id, status, expires_at } = body;
    const { rows } = await pool.query(`insert into subscriptions (user_id, tier, provider, product_id, status, expires_at, renewed_at)
     values ($1,$2,$3,$4,$5,$6, now())
     returning id`, [userId, tier, provider, product_id ?? null, status, expires_at ?? null]);
    return { id: rows[0].id };
});
const port = Number(process.env.PORT || 8080);
app
    .listen({ port, host: '0.0.0.0' })
    .then((addr) => app.log.info(`API listening on ${addr}`))
    .catch((err) => {
    app.log.error(err);
    process.exit(1);
});
