// Supabase Edge Function: image-analysis
// Enforces daily image analysis quota and returns a Gemini vision analysis.
// Deploy with: supabase functions deploy image-analysis

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
}

function json(body: unknown, init?: ResponseInit) {
  return new Response(JSON.stringify(body), { headers: { 'content-type': 'application/json', ...corsHeaders }, ...init })
}

const DAILY_FREE = 1
const DAILY_PREMIUM = 200
const GEMINI_MODEL = 'gemini-1.5-flash'
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

const SYSTEM_PROMPT = `
You are ChartSense AI. Analyze a financial chart image.
Rules:
- Educational only; not financial advice. Include a short disclaimer.
- Provide sections: Pattern, Trend, Support/Resistance, Indicators (RSI/MACD/MAs), Risks, Levels (Entry/Exit/Invalidation), What to Watch.
- Be concise, markdown formatted, avoid speculation.
`

async function callGeminiVision(imageBase64: string, mimeType: string, userPrompt?: string): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`
  const parts: any[] = [
    { text: SYSTEM_PROMPT },
    { inline_data: { mime_type: mimeType, data: imageBase64 } }
  ]
  if (userPrompt) parts.push({ text: userPrompt })

  const body = {
    contents: [{ role: 'user', parts }],
    generationConfig: { temperature: 0.3, maxOutputTokens: 1024 }
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
  const out =
    data?.candidates?.[0]?.content?.parts?.map((p: any) => p.text).join('') ??
    data?.candidates?.[0]?.content?.parts?.[0]?.text ??
    'Sorry, I could not analyze the image.'
  return out
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

  const { image_base64, mime_type, prompt } = await req.json().catch(() => ({})) as { image_base64?: string; mime_type?: string; prompt?: string }
  if (!image_base64 || typeof image_base64 !== 'string') return json({ error: 'missing_image' }, { status: 400 })
  const mime = typeof mime_type === 'string' && mime_type.startsWith('image/') ? mime_type : 'image/jpeg'

  // Support data URLs: strip the prefix if present
  const cleanedBase64 = image_base64.includes(',') ? image_base64.split(',').pop()! : image_base64

  // Determine subscription and enforce limits
  const { data: sub } = await supabase.from('subscriptions')
    .select('tier, status, expires_at')
    .eq('user_id', user.id)
    .order('renewed_at', { ascending: false, nullsFirst: false })
    .limit(1)
    .maybeSingle()

  const now = new Date()
  const active = sub && sub.status === 'active' && (!sub.expires_at || new Date(sub.expires_at) > now)
  const limit = active ? DAILY_PREMIUM : DAILY_FREE

  const { data: ok, error: rpcErr } = await supabaseAdmin.rpc('increment_image_analysis_usage', { p_user_id: user.id, p_limit: limit })
  if (rpcErr || ok !== true) return json({ error: 'daily_limit_reached' }, { status: 429 })

  try {
    const analysis = await callGeminiVision(cleanedBase64, mime, prompt)
    return json({ analysis })
  } catch (e: any) {
    return json({ error: 'llm_error', details: e?.message ?? String(e) }, { status: 502 })
  }
}

// @ts-ignore
Deno.serve(handler)


