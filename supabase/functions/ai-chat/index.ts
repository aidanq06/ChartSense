// Supabase Edge Function: ai-chat
// Enforces daily AI chat quota and returns a placeholder response.
// Deploy with: supabase functions deploy ai-chat

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
}

function json(body: unknown, init?: ResponseInit) {
  return new Response(JSON.stringify(body), { headers: { 'content-type': 'application/json', ...corsHeaders }, ...init })
}

const DAILY_FREE = 20
const DAILY_PREMIUM = 200

export default async function handler(req: Request) {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization') || ''
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const supabaseAdminKey = Deno.env.get('SERVICE_ROLE_KEY')!

  const { createClient } = await import('npm:@supabase/supabase-js')
  const supabase = createClient(supabaseUrl, supabaseKey, { global: { headers: { Authorization: authHeader } } })
  const supabaseAdmin = createClient(supabaseUrl, supabaseAdminKey)

  const { data: { user }, error: userErr } = await supabase.auth.getUser()
  if (userErr || !user) {
    return json({ error: 'unauthorized' }, { status: 401 })
  }

  // Determine subscription tier
  const { data: sub } = await supabase.from('subscriptions')
    .select('tier, status, expires_at')
    .eq('user_id', user.id)
    .order('renewed_at', { ascending: false, nullsFirst: false })
    .limit(1)
    .maybeSingle()

  const now = new Date()
  const active = sub && sub.status === 'active' && (!sub.expires_at || new Date(sub.expires_at) > now)
  const limit = active && (sub.tier === 'premium' || sub.tier === 'pro') ? DAILY_PREMIUM : DAILY_FREE

  // Increment usage atomically via RPC
  const { data: ok, error: rpcErr } = await supabaseAdmin.rpc('increment_ai_chat_usage', { p_user_id: user.id, p_limit: limit })
  if (rpcErr || ok !== true) {
    return json({ error: 'daily_limit_reached' }, { status: 429 })
  }

  // TODO: call your LLM provider with user prompt
  const { message } = await req.json().catch(() => ({ message: '' }))
  const reply = message ? `Echo: ${message}` : 'Hello from ChartSense AI.'
  return json({ reply })
}

// @ts-ignore
Deno.serve(handler)


