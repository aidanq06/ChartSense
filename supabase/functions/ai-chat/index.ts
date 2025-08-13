// Supabase Edge Function: ai-chat
// Enforces daily AI chat quota and returns a Gemini-generated response.
// Deploy with: supabase functions deploy ai-chat

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
}

function json(body: unknown, init?: ResponseInit) {
  return new Response(JSON.stringify(body), { headers: { 'content-type': 'application/json', ...corsHeaders }, ...init })
}

const DAILY_FREE = 5
const DAILY_PREMIUM = 200
const GEMINI_MODEL = 'gemini-1.5-flash'
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!
const OUTPUT_CHAR_LIMIT = 220

const SYSTEM_PROMPT = `
You are ChartSense AI, a financial information assistant.
Rules:
- Plain text only; no markdown, lists, emojis, or line breaks.
- Two sentences max; under ~220 characters.
- Start with a stance: Bullish:, Bearish:, or Neutral:, then 1 key driver.
- If info is limited, default to Neutral: with a cautious driver; do NOT say "Uncertain" unless the prompt is unrelated or nonsensical.
- Use qualitative wording if numbers are unknown; never invent data or news.
- No personalized advice, trade instructions, allocations, or price targets.
- Default to US market context unless specified.
`

function sanitizeAndConstrain(raw: string): string {
  let t = String(raw || '')
  t = t.replace(/\r?\n+/g, ' ')
  t = t.replace(/[\*_`#>~|]/g, ' ')
  t = t.replace(/[•·▪︎●]/g, ' ')
  t = t.replace(/\s+/g, ' ').trim()
  // Enforce length
  if (t.length > OUTPUT_CHAR_LIMIT) t = t.slice(0, OUTPUT_CHAR_LIMIT).trim()
  if (!/[.!?]$/.test(t) && t.length > 0) t += '.'
  return t
}

async function callGeminiText(message: string): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`
  const body = {
    contents: [
      { role: 'user', parts: [{ text: SYSTEM_PROMPT }] },
      { role: 'user', parts: [{ text: message }] }
    ],
    generationConfig: {
      temperature: 0.25,
      topP: 0.9,
      maxOutputTokens: 140
    }
  }

  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body)
  })

  if (!resp.ok) {
    const errText = await resp.text().catch(() => '')
    throw new Error(`Gemini error: ${resp.status} ${errText}`)
  }

  const data = await resp.json()
  const reply =
    data?.candidates?.[0]?.content?.parts?.map((p: any) => p.text).join('') ??
    data?.candidates?.[0]?.content?.parts?.[0]?.text ??
    'Uncertain: no response.'
  return sanitizeAndConstrain(reply)
}

export default async function handler(req: Request) {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const authHeader = req.headers.get('Authorization') || ''
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const supabaseAdminKey = Deno.env.get('SERVICE_ROLE_KEY')!

  const { createClient } = await import('npm:@supabase/supabase-js')
  const supabase = createClient(supabaseUrl, supabaseKey, { global: { headers: { Authorization: authHeader } } })
  const supabaseAdmin = createClient(supabaseUrl, supabaseAdminKey)

  const { data: { user }, error: userErr } = await supabase.auth.getUser()
  if (userErr || !user) return json({ error: 'unauthorized' }, { status: 401 })

  // Determine subscription tier
  const { data: sub } = await supabase
    .from('subscriptions')
    .select('tier, status, expires_at, renewed_at')
    .eq('user_id', user.id)
    .order('expires_at', { ascending: false, nullsFirst: false })
    .order('renewed_at', { ascending: false, nullsFirst: true })
    .limit(1)
    .maybeSingle()

  const now = new Date()
  const active = sub && sub.status === 'active' && (!sub.expires_at || new Date(sub.expires_at) > now)
  const isPremiumTier = sub && (sub.tier === 'premium' || sub.tier === 'pro')
  const limit = active && isPremiumTier ? DAILY_PREMIUM : DAILY_FREE

  // Increment usage atomically
  const { data: ok, error: rpcErr } = await supabaseAdmin.rpc('increment_ai_chat_usage', { p_user_id: user.id, p_limit: limit })
  if (rpcErr || ok !== true) return json({ error: 'daily_limit_reached' }, { status: 429 })

  const { message } = await req.json().catch(() => ({ message: '' })) as { message?: string }
  if (!message || typeof message !== 'string') return json({ error: 'invalid_message' }, { status: 400 })

  try {
    const reply = await callGeminiText(message)
    return json({ reply })
  } catch (e: any) {
    return json({ error: 'llm_error', details: e?.message ?? String(e) }, { status: 502 })
  }
}

// @ts-ignore
Deno.serve(handler)


