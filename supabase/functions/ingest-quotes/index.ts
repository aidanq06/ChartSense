// Supabase Edge Function: ingest-quotes
// Fetches quotes periodically and upserts into public.quotes_latest
// Schedule via: supabase functions deploy ingest-quotes --no-verify-jwt and cron on Supabase Dashboard

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

function json(body: unknown, init?: ResponseInit) {
  return new Response(JSON.stringify(body), { headers: { 'content-type': 'application/json' }, ...init })
}

type Quote = { price: number; tsIso: string } | null

async function fetchFinnhubQuote(symbol: string, token: string): Promise<Quote> {
  try {
    const url = `https://finnhub.io/api/v1/quote?symbol=${encodeURIComponent(symbol)}&token=${token}`
    const res = await fetch(url)
    if (!res.ok) throw new Error(String(res.status))
    const q: any = await res.json()
    const ts = typeof q.t === 'number' && q.t > 0 ? new Date(q.t * 1000).toISOString() : new Date().toISOString()
    if (typeof q.c !== 'number' || !isFinite(q.c)) return null
    return { price: q.c, tsIso: ts }
  } catch (_) {
    return null
  }
}

async function fetchFinnhubLastMinuteClose(symbol: string, token: string): Promise<Quote> {
  try {
  const nowSec = Math.floor(Date.now() / 1000)
  const from = nowSec - 60 * 60 * 8 // past 8 hours to capture extended sessions
    const url = `https://finnhub.io/api/v1/stock/candle?symbol=${encodeURIComponent(symbol)}&resolution=1&from=${from}&to=${nowSec}&token=${token}`
    const res = await fetch(url)
    if (!res.ok) throw new Error(String(res.status))
    const cndl: any = await res.json()
    if (cndl.s !== 'ok' || !Array.isArray(cndl.t) || !Array.isArray(cndl.c) || cndl.t.length === 0) return null
    // pick last non-null value
    for (let i = cndl.t.length - 1; i >= 0; i--) {
      const close = cndl.c[i]
      const t = cndl.t[i]
      if (typeof close === 'number' && isFinite(close) && typeof t === 'number') {
        return { price: close, tsIso: new Date(t * 1000).toISOString() }
      }
    }
    return null
  } catch (_) {
    return null
  }
}

function pickLatest(a: Quote, b: Quote): Quote {
  if (a && b) {
    return new Date(a.tsIso).getTime() >= new Date(b.tsIso).getTime() ? a : b
  }
  return a ?? b
}

type YahooTriplet = { regular: Quote; post: Quote; pre: Quote }

async function fetchYahooTriplet(symbol: string): Promise<YahooTriplet> {
  try {
    const url = `https://query1.finance.yahoo.com/v7/finance/quote?symbols=${encodeURIComponent(symbol)}`
    const res = await fetch(url)
    if (!res.ok) throw new Error(String(res.status))
    const data: any = await res.json()
    const q = data?.quoteResponse?.result?.[0]
    if (!q) return { regular: null, post: null, pre: null }
    const postPrice = typeof q.postMarketPrice === 'number' && isFinite(q.postMarketPrice) ? q.postMarketPrice : null
    const postTime = typeof q.postMarketTime === 'number' && q.postMarketTime > 0 ? new Date(q.postMarketTime * 1000).toISOString() : null
    const prePrice = typeof q.preMarketPrice === 'number' && isFinite(q.preMarketPrice) ? q.preMarketPrice : null
    const preTime = typeof q.preMarketTime === 'number' && q.preMarketTime > 0 ? new Date(q.preMarketTime * 1000).toISOString() : null
    const regPrice = typeof q.regularMarketPrice === 'number' && isFinite(q.regularMarketPrice) ? q.regularMarketPrice : null
    const regTime = typeof q.regularMarketTime === 'number' && q.regularMarketTime > 0 ? new Date(q.regularMarketTime * 1000).toISOString() : null
    const post: Quote = postPrice && postTime ? { price: postPrice, tsIso: postTime } : null
    const pre: Quote = prePrice && preTime ? { price: prePrice, tsIso: preTime } : null
    const reg: Quote = regPrice && regTime ? { price: regPrice, tsIso: regTime } : null
    return { regular: reg, post, pre }
  } catch (_) {
    return { regular: null, post: null, pre: null }
  }
}

async function fetchYahooChartLast(symbol: string): Promise<Quote> {
  try {
    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(symbol)}?interval=1m&range=1d&includePrePost=true`
    const res = await fetch(url)
    if (!res.ok) throw new Error(String(res.status))
    const data: any = await res.json()
    const ts: number[] | undefined = data?.chart?.result?.[0]?.timestamp
    const closes: number[] | undefined = data?.chart?.result?.[0]?.indicators?.quote?.[0]?.close
    if (!Array.isArray(ts) || !Array.isArray(closes) || ts.length === 0) return null
    for (let i = ts.length - 1; i >= 0; i--) {
      const v = closes[i]
      const t = ts[i]
      if (typeof v === 'number' && isFinite(v) && typeof t === 'number') {
        return { price: v, tsIso: new Date(t * 1000).toISOString() }
      }
    }
    return null
  } catch (_) {
    return null
  }
}

async function fetchPolygonLastTrade(symbol: string, apiKey?: string): Promise<Quote> {
  if (!apiKey) return null
  try {
    const url = `https://api.polygon.io/v2/last/trade/${encodeURIComponent(symbol)}?apiKey=${apiKey}`
    const res = await fetch(url)
    if (!res.ok) throw new Error(String(res.status))
    const data: any = await res.json()
    const p = data?.results?.p ?? data?.results?.price
    const t = data?.results?.t ?? data?.results?.sip_timestamp
    if (typeof p === 'number' && typeof t === 'number') {
      // Polygon timestamp is in nanoseconds
      return { price: p, tsIso: new Date(Math.floor(t / 1_000_000)).toISOString() }
    }
    return null
  } catch (_) {
    return null
  }
}

async function fetchAlpacaLastTrade(symbol: string, key?: string, secret?: string): Promise<Quote> {
  if (!key || !secret) return null
  try {
    const url = `https://data.alpaca.markets/v2/stocks/${encodeURIComponent(symbol)}/trades/latest`
    const res = await fetch(url, { headers: { 'APCA-API-KEY-ID': key, 'APCA-API-SECRET-KEY': secret } })
    if (!res.ok) throw new Error(String(res.status))
    const data: any = await res.json()
    const p = data?.trade?.p
    const t = data?.trade?.t // ISO 8601
    if (typeof p === 'number' && typeof t === 'string') {
      return { price: p, tsIso: t }
    }
    return null
  } catch (_) {
    return null
  }
}

export default async function handler(req: Request) {
  // Optional HMAC-like header check to prevent public abuse when --no-verify-jwt is used
  const cronSecret = Deno.env.get('CRON_SECRET')
  if (cronSecret) {
    const authHeader = req.headers.get('authorization') || ''
    const expected = `Bearer ${cronSecret}`
    if (authHeader !== expected) {
      return json({ error: 'unauthorized' }, { status: 401 })
    }
  }
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SERVICE_ROLE_KEY')!
  const finnhub = Deno.env.get('FINNHUB_TOKEN')
  const polygonKey = Deno.env.get('POLYGON_API_KEY')
  const alpacaKey = Deno.env.get('ALPACA_KEY_ID')
  const alpacaSecret = Deno.env.get('ALPACA_SECRET_KEY')

  if (!finnhub) {
    return json({ error: 'missing FINNHUB_TOKEN' }, { status: 500 })
  }

  const { createClient } = await import('npm:@supabase/supabase-js')
  const admin = createClient(supabaseUrl, serviceKey)

  // Universe = watchlist symbols ∪ baseline from symbols.is_baseline=true
  const { data: baseRows } = await admin.from('symbols').select('symbol').eq('is_baseline', true).limit(500)
  const baseline = baseRows?.map(r => (r as any).symbol as string) ?? ['AAPL','MSFT','SPY']
  const { data: wlItems } = await admin.from('watchlist_items').select('symbol')
  const symbols = Array.from(new Set([...(wlItems?.map(w => (w as any).symbol as string) ?? []), ...baseline]))

  const results: any[] = []
  for (const symbol of symbols) {
    try {
      const [q, c1, ytri, ychart, poly, alp] = await Promise.all([
        fetchFinnhubQuote(symbol, finnhub),
        fetchFinnhubLastMinuteClose(symbol, finnhub),
        fetchYahooTriplet(symbol),
        fetchYahooChartLast(symbol),
        fetchPolygonLastTrade(symbol, polygonKey),
        fetchAlpacaLastTrade(symbol, alpacaKey, alpacaSecret)
      ])
      // Determine NY session to label only; selection is purely most-recent timestamp
      const parts = new Intl.DateTimeFormat('en-US', { timeZone: 'America/New_York', hour12: false, hour: '2-digit', minute: '2-digit', weekday: 'short' }).formatToParts(new Date())
      const hour = Number(parts.find(p => p.type === 'hour')?.value || '0')
      const minute = Number(parts.find(p => p.type === 'minute')?.value || '0')
      const weekday = String(parts.find(p => p.type === 'weekday')?.value || 'Mon')
      const mins = hour * 60 + minute
      const isWeekend = weekday === 'Sat' || weekday === 'Sun'
      const inRegular = !isWeekend && mins >= (9*60+30) && mins < (16*60)
      const inAfter = !isWeekend && mins >= (16*60) && mins < (20*60)
      
      // Pick the most recent across all candidates strictly by timestamp
      const candidates: Array<{ q: Quote; name: string }> = []
      if (q) candidates.push({ q, name: 'finnhub_quote' })
      if (c1) candidates.push({ q: c1, name: 'finnhub_candle_1m' })
      if (ytri.regular) candidates.push({ q: ytri.regular, name: 'yahoo_regular' })
      if (ytri.post) candidates.push({ q: ytri.post, name: 'yahoo_post' })
      if (ytri.pre) candidates.push({ q: ytri.pre, name: 'yahoo_pre' })
      if (ychart) candidates.push({ q: ychart, name: 'yahoo_chart_1m' })
      if (poly) candidates.push({ q: poly, name: 'polygon_last_trade' })
      if (alp) candidates.push({ q: alp, name: 'alpaca_last_trade' })

      candidates.sort((a, b) => new Date(b.q!.tsIso).getTime() - new Date(a.q!.tsIso).getTime())
      const top = candidates[0]
      const latest = top?.q ?? null
      if (latest) {
        const nowIso = new Date().toISOString()
        const post = ytri.post
        const pre = ytri.pre
        // Classify session preferring the source; otherwise derive from the latest timestamp in NY time
        let session: 'premarket' | 'regular' | 'extended' | 'unknown' = 'unknown'
        if (top?.name === 'yahoo_post') {
          session = 'extended'
        } else if (top?.name === 'yahoo_pre') {
          session = 'premarket'
        } else {
          const d = new Date(latest.tsIso)
          const parts2 = new Intl.DateTimeFormat('en-US', { timeZone: 'America/New_York', hour12: false, hour: '2-digit', minute: '2-digit', weekday: 'short' }).formatToParts(d)
          const hh = Number(parts2.find(p => p.type === 'hour')?.value || '0')
          const mm = Number(parts2.find(p => p.type === 'minute')?.value || '0')
          const wd = String(parts2.find(p => p.type === 'weekday')?.value || 'Mon')
          const m2 = hh * 60 + mm
          const weekend = wd === 'Sat' || wd === 'Sun'
          if (!weekend && m2 >= (4*60) && m2 < (9*60+30)) session = 'premarket'
          else if (!weekend && m2 >= (9*60+30) && m2 < (16*60)) session = 'regular'
          else if (!weekend && m2 >= (16*60) && m2 < (20*60)) session = 'extended'
          else session = 'unknown'
        }
        results.push({
          symbol,
          price: latest.price,
          ts: nowIso,
          extended_price: post?.price ?? null,
          extended_ts: post?.tsIso ?? null,
          premarket_price: pre?.price ?? null,
          premarket_ts: pre?.tsIso ?? null,
          price_source: top?.name ?? null,
          extended_source: post ? 'yahoo_post' : null,
          premarket_source: pre ? 'yahoo_pre' : null,
          session,
        })
      }
      // Rate-limit friendly (Finnhub free plan)
      await new Promise((r) => setTimeout(r, 150))
    } catch (e) {
      console.log('fetch error', symbol, String(e))
    }
  }

  for (const r of results) {
    await admin.from('symbols').upsert({ symbol: r.symbol })
    await admin.from('quotes_latest').upsert({
      symbol: r.symbol,
      price: r.price,
      open: null,
      high: null,
      low: null,
      previous_close: null,
      change: null,
      change_percent: null,
      volume: null,
      ts: r.ts,
      extended_price: r.extended_price,
      extended_ts: r.extended_ts,
      price_source: r.price_source,
      extended_source: r.extended_source,
      session: r.session,
    })
  }

  return json({ updated: results.length })
}

// @ts-ignore
Deno.serve(handler)


