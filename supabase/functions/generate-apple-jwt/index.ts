import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { create, verify } from "https://deno.land/x/djwt@v2.8/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get environment variables
    const teamId = Deno.env.get('APPLE_TEAM_ID')
    const keyId = Deno.env.get('APPLE_KEY_ID')
    const clientId = Deno.env.get('APPLE_CLIENT_ID')
    const privateKey = Deno.env.get('APPLE_PRIVATE_KEY')

    if (!teamId || !keyId || !clientId || !privateKey) {
      throw new Error('Missing Apple configuration')
    }

    // Create JWT header
    const header = {
      alg: 'ES256',
      kid: keyId
    }

    // Create JWT payload
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: teamId,
      iat: now,
      exp: now + (6 * 60 * 60), // 6 hours
      aud: 'https://appleid.apple.com',
      sub: clientId
    }

    // Convert private key to proper format
    const key = await crypto.subtle.importKey(
      'pkcs8',
      new TextEncoder().encode(privateKey),
      {
        name: 'ECDSA',
        namedCurve: 'P-256'
      },
      false,
      ['sign']
    )

    // Create JWT
    const jwt = await create(header, payload, key)

    return new Response(
      JSON.stringify({ jwt }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
}) 