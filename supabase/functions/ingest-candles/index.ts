// Supabase Edge Function: ingest-candles
// Pulls 5m and 1d candles from Yahoo Finance and upserts into candles_5m and candles_1d
// Schedule via pg_cron every 15 minutes

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

function json(body: unknown, init?: ResponseInit) {
  return new Response(JSON.stringify(body), { headers: { 'content-type': 'application/json' }, ...init })
}

type Candle = { t: number; o: number; h: number; l: number; c: number; v: number }

async function fetchYahooChart(symbol: string, interval: string, range: string, includePrePost = true): Promise<Candle[]> {
  try {
    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(symbol)}?interval=${interval}&range=${range}&includePrePost=${includePrePost ? 'true' : 'false'}`
    const res = await fetch(url)
    if (!res.ok) throw new Error(String(res.status))
    const data: any = await res.json()
    const r = data?.chart?.result?.[0]
    const ts: number[] | undefined = r?.timestamp
    const q = r?.indicators?.quote?.[0]
    const opens: number[] | undefined = q?.open
    const highs: number[] | undefined = q?.high
    const lows: number[] | undefined = q?.low
    const closes: number[] | undefined = q?.close
    const vols: number[] | undefined = q?.volume
    if (!Array.isArray(ts) || !Array.isArray(opens) || !Array.isArray(highs) || !Array.isArray(lows) || !Array.isArray(closes)) return []
    const out: Candle[] = []
    for (let i = 0; i < ts.length; i++) {
      const o = opens[i]; const h = highs[i]; const l = lows[i]; const c = closes[i]
      if (typeof ts[i] === 'number' && [o, h, l, c].every(x => typeof x === 'number' && isFinite(x))) {
        out.push({ t: ts[i]!, o, h, l, c, v: typeof vols?.[i] === 'number' ? vols![i] : 0 })
      }
    }
    return out
  } catch (_) {
    return []
  }
}

async function chunkedUpsert<T>(rows: T[], size: number, fn: (chunk: T[]) => Promise<void>) {
  for (let i = 0; i < rows.length; i += size) {
    const chunk = rows.slice(i, i + size)
    await fn(chunk)
  }
}

export default async function handler(req: Request) {
  // Require bearer CRON secret if provided
  const cronSecret = Deno.env.get('CRON_SECRET')
  if (cronSecret) {
    const authHeader = req.headers.get('authorization') || ''
    const expected = `Bearer ${cronSecret}`
    if (authHeader !== expected) return json({ error: 'unauthorized' }, { status: 401 })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SERVICE_ROLE_KEY')!
  const { createClient } = await import('npm:@supabase/supabase-js')
  const admin = createClient(supabaseUrl, serviceKey)

  // Build universe from watchlists + baseline
  const baseline = ['AAPL', 'MSFT', 'SPY']
  const { data: wlItems } = await admin.from('watchlist_items').select('symbol')
  const symbols = Array.from(new Set([...(wlItems?.map(w => w.symbol) ?? []), ...baseline]))

  let updated5m = 0
  let updated1d = 0

  for (const symbol of symbols) {
    try {
      // 5m: last 5 days
      const intraday = await fetchYahooChart(symbol, '5m', '5d', true)
      const rows5m = intraday.map(c => ({
        symbol,
        ts: new Date(c.t * 1000).toISOString(),
        open: c.o,
        high: c.h,
        low: c.l,
        close: c.c,
        volume: c.v,
      }))
      await chunkedUpsert(rows5m, 400, async (chunk) => {
        await admin.from('candles_5m').upsert(chunk)
      })
      updated5m += rows5m.length

      // 1d: last 1 year
      const daily = await fetchYahooChart(symbol, '1d', '1y', true)
      const rows1d = daily.map(c => ({
        symbol,
        day: new Date(c.t * 1000).toISOString().slice(0, 10),
        open: c.o,
        high: c.h,
        low: c.l,
        close: c.c,
        volume: c.v,
      }))
      await chunkedUpsert(rows1d, 400, async (chunk) => {
        await admin.from('candles_1d').upsert(chunk)
      })
      updated1d += rows1d.length

      // Gentle pacing
      await new Promise((r) => setTimeout(r, 150))
    } catch (e) {
      console.log('candles error', symbol, String(e))
    }
  }

  return json({ updated_5m: updated5m, updated_1d: updated1d, symbols: symbols.length })
}

// @ts-ignore
Deno.serve(handler)


