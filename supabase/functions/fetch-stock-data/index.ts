import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

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
    const { symbol } = await req.json()
    
    if (!symbol) {
      return new Response(
        JSON.stringify({ error: 'Symbol is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check cache first
    const cacheKey = `stock_${symbol.toUpperCase()}`
    const cached = await getFromCache(cacheKey)
    
    if (cached) {
      return new Response(
        JSON.stringify(cached),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Fetch from Alpha Vantage (free tier)
    const apiKey = Deno.env.get('ALPHA_VANTAGE_API_KEY')
    if (!apiKey) {
      throw new Error('Alpha Vantage API key not configured')
    }

    const response = await fetch(
      `https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=${symbol.toUpperCase()}&apikey=${apiKey}`
    )

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status}`)
    }

    const data = await response.json()
    
    if (data['Error Message']) {
      throw new Error(data['Error Message'])
    }

    const quote = data['Global Quote']
    if (!quote || Object.keys(quote).length === 0) {
      throw new Error('No data found for symbol')
    }

    // Transform the response
    const stockData = {
      symbol: quote['01. symbol'],
      companyName: quote['01. symbol'], // Alpha Vantage doesn't provide company name in this endpoint
      currentPrice: parseFloat(quote['05. price'] || '0'),
      dailyChange: parseFloat(quote['09. change'] || '0'),
      dailyChangePercent: parseFloat(quote['10. change percent']?.replace('%', '') || '0'),
      volume: parseInt(quote['06. volume'] || '0'),
      lastUpdated: new Date().toISOString()
    }

    // Cache the result for 5 minutes
    await setCache(cacheKey, stockData, 300)

    return new Response(
      JSON.stringify(stockData),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error fetching stock data:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Failed to fetch stock data',
        symbol: req.body?.symbol 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// Simple in-memory cache (in production, use Redis or Supabase cache)
const cache = new Map()

async function getFromCache(key: string) {
  const cached = cache.get(key)
  if (cached && Date.now() < cached.expiry) {
    return cached.data
  }
  cache.delete(key)
  return null
}

async function setCache(key: string, data: any, ttlSeconds: number) {
  cache.set(key, {
    data,
    expiry: Date.now() + (ttlSeconds * 1000)
  })
  
  // Clean up old entries
  for (const [k, v] of cache.entries()) {
    if (Date.now() > v.expiry) {
      cache.delete(k)
    }
  }
} 