import dotenv from 'dotenv';
import { Pool } from 'pg';
import Redis from 'ioredis';
import { randomUUID } from 'node:crypto';

dotenv.config({ path: process.env.DOTENV_PATH || undefined });

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const redis = process.env.REDIS_URL ? new Redis(process.env.REDIS_URL) : null;

async function fetchUniverse(): Promise<string[]> {
  // Pull all symbols the users care about + a core baseline
  const baseline = ['AAPL', 'MSFT', 'SPY'];
  const { rows } = await pool.query(
    `select distinct wi.symbol
     from watchlist_items wi
     join watchlists w on w.id = wi.watchlist_id
     where wi.symbol is not null`
  );
  const symbols = Array.from(new Set([...baseline, ...rows.map((r) => r.symbol as string)]));
  return symbols;
}

async function fetchQuotes(symbols: string[]) {
  const token = process.env.FINNHUB_TOKEN;
  if (!token || symbols.length === 0) return [];
  const out: Array<{ symbol: string; price: number; open?: number; high?: number; low?: number; previous_close?: number; change?: number; change_percent?: number; volume?: number; ts: Date }>
    = [];

  // Simple sequential fetch to start; can batch/parallelize later respecting rate limits
  for (const symbol of symbols) {
    try {
      const url = `https://finnhub.io/api/v1/quote?symbol=${encodeURIComponent(symbol)}&token=${token}`;
      const res = await fetch(url);
      if (!res.ok) throw new Error(`quote ${symbol} ${res.status}`);
      const q = (await res.json()) as any;
      const now = new Date();
      out.push({
        symbol,
        price: q.c,
        open: q.o,
        high: q.h,
        low: q.l,
        previous_close: q.pc,
        change: q.d,
        change_percent: q.dp,
        volume: q.v,
        ts: now,
      });
      // Optional: short sleep to respect API limits
      await new Promise((resolve: (value: unknown) => void) => setTimeout(resolve, 150));
    } catch (err) {
      console.error('fetchQuotes error', symbol, err);
    }
  }
  return out;
}

async function upsertQuotes(quotes: Awaited<ReturnType<typeof fetchQuotes>>) {
  if (!quotes.length) return;
  const client = await pool.connect();
  try {
    await client.query('begin');
    // Ensure symbols exist
    for (const q of quotes) {
      await client.query('insert into symbols (symbol) values ($1) on conflict (symbol) do nothing', [q.symbol]);
      await client.query(
        `insert into quotes_latest (symbol, price, open, high, low, previous_close, change, change_percent, volume, ts)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
         on conflict (symbol) do update set
           price = excluded.price,
           open = excluded.open,
           high = excluded.high,
           low = excluded.low,
           previous_close = excluded.previous_close,
           change = excluded.change,
           change_percent = excluded.change_percent,
           volume = excluded.volume,
           ts = excluded.ts`,
        [
          q.symbol,
          q.price,
          q.open ?? null,
          q.high ?? null,
          q.low ?? null,
          q.previous_close ?? null,
          q.change ?? null,
          q.change_percent ?? null,
          q.volume ?? null,
          q.ts,
        ]
      );
    }
    await client.query('commit');
  } catch (err) {
    await client.query('rollback');
    throw err;
  } finally {
    client.release();
  }
}

async function runCycle() {
  const runId = randomUUID();
  const start = Date.now();
  await pool.query('insert into ingest_runs(id, job_name, status) values ($1, $2, $3)', [runId, 'quotes_cycle', 'running']);
  try {
    const universe = await fetchUniverse();
    const quotes = await fetchQuotes(universe);
    await upsertQuotes(quotes);
    await pool.query('update ingest_runs set status=$2, finished_at=now(), details=$3 where id=$1', [runId, 'success', { count: quotes.length }]);
    console.log(`Cycle OK: ${quotes.length} quotes in ${Date.now() - start}ms`);
  } catch (err: any) {
    console.error('Cycle failed', err);
    await pool.query('update ingest_runs set status=$2, finished_at=now(), details=$3 where id=$1', [runId, 'failed', { error: String(err?.message || err) }]);
  }
}

const every = Number(process.env.INGEST_INTERVAL_MS || 5 * 60 * 1000);
runCycle().catch(console.error);
setInterval(() => runCycle().catch(console.error), every);


