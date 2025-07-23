import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
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
    const cacheKey = `sentiment_${symbol.toUpperCase()}`
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

    // For now, generate mock sentiment data
    // In production, integrate with OpenAI API or other sentiment analysis services
    const sentimentData = generateMockSentiment(symbol)

    // Cache for 1 hour (sentiment doesn't change as frequently as price)
    await setCache(cacheKey, sentimentData, 3600)

    return new Response(
      JSON.stringify(sentimentData),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error fetching sentiment data:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Failed to fetch sentiment data',
        symbol: req.body?.symbol 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

function generateMockSentiment(symbol: string) {
  const ratings = ['strongly_bullish', 'bullish', 'cautiously_optimistic', 'neutral', 'bearish_undercurrents', 'bearish', 'highly_negative']
  const randomRating = ratings[Math.floor(Math.random() * ratings.length)]
  
  let score: number
  switch (randomRating) {
    case 'strongly_bullish':
      score = Math.random() * 0.3 + 0.7 // 0.7 - 1.0
      break
    case 'bullish':
      score = Math.random() * 0.3 + 0.4 // 0.4 - 0.7
      break
    case 'cautiously_optimistic':
      score = Math.random() * 0.3 + 0.1 // 0.1 - 0.4
      break
    case 'neutral':
      score = Math.random() * 0.2 - 0.1 // -0.1 - 0.1
      break
    case 'bearish_undercurrents':
      score = Math.random() * 0.3 - 0.4 // -0.4 - -0.1
      break
    case 'bearish':
      score = Math.random() * 0.3 - 0.7 // -0.7 - -0.4
      break
    case 'highly_negative':
      score = Math.random() * 0.3 - 1.0 // -1.0 - -0.7
      break
    default:
      score = 0
  }

  return {
    symbol: symbol.toUpperCase(),
    overallRating: randomRating,
    score: parseFloat(score.toFixed(3)),
    confidence: Math.random() * 0.25 + 0.7, // 0.7 - 0.95
    lastUpdated: new Date().toISOString()
  }
}

// Simple in-memory cache
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