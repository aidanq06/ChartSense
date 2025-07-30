import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// 🔧 CONFIGURATION - Adjust these values
const UPDATE_INTERVAL_MINUTES = 60 // How often to update data
const CACHE_DURATION_MINUTES = 5   // How long to serve cached data
const MAX_RETRIES = 3              // Max API retry attempts
const RETRY_DELAY_MS = 1000        // Delay between retries

// 🔑 API Configuration
const FINNHUB_API_KEY = Deno.env.get('FINNHUB_API_KEY')
const ALPHA_VANTAGE_API_KEY = Deno.env.get('ALPHA_VANTAGE_API_KEY')

interface StockData {
  symbol: string
  companyName: string
  currentPrice: number
  previousClose: number
  dailyChange: number
  dailyChangePercent: number
  volume: number
  high: number
  low: number
  openPrice: number
  lastUpdated: string
  source: 'finnhub' | 'alphavantage'
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const startTime = Date.now()
  
  try {
    const { symbol } = await req.json()
    
    if (!symbol || typeof symbol !== 'string') {
      throw new Error('Valid symbol is required')
    }

    const normalizedSymbol = symbol.toUpperCase().trim()
    console.log(`🔍 Fetching data for ${normalizedSymbol}`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 📊 Check cache first (optimized query)
    const { data: cachedData, error: cacheError } = await supabase
      .from('stock_cache')
      .select('data, expires_at, created_at')
      .eq('symbol', normalizedSymbol)
      .single()

    // Return cached data if still valid
    if (cachedData && !isExpired(cachedData.expires_at)) {
      const responseTime = Date.now() - startTime
      console.log(`⚡ Cache hit for ${normalizedSymbol} (${responseTime}ms)`)
      
      return new Response(
        JSON.stringify({ 
          success: true, 
          data: cachedData.data,
          source: 'cache',
          cached_at: cachedData.created_at,
          response_time_ms: responseTime
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 🚀 Fetch fresh data with optimized API calls
    console.log(`🔄 Cache miss/expired for ${normalizedSymbol}, fetching fresh data`)
    const stockData = await fetchStockDataOptimized(normalizedSymbol)

    // 💾 Cache the new data (upsert for performance)
    const expiresAt = new Date(Date.now() + (CACHE_DURATION_MINUTES * 60 * 1000)).toISOString()
    
    const { error: upsertError } = await supabase
      .from('stock_cache')
      .upsert({
        symbol: normalizedSymbol,
        data: stockData,
        expires_at: expiresAt,
        updated_at: new Date().toISOString()
      }, {
        onConflict: 'symbol'
      })

    if (upsertError) {
      console.error('❌ Cache error:', upsertError.message)
    }

    const responseTime = Date.now() - startTime
    console.log(`✅ Fresh data for ${normalizedSymbol} (${responseTime}ms)`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: stockData,
        source: 'api',
        cached_at: new Date().toISOString(),
        response_time_ms: responseTime
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    const responseTime = Date.now() - startTime
    console.error(`❌ Error (${responseTime}ms):`, error.message)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        response_time_ms: responseTime
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})

async function fetchStockDataOptimized(symbol: string): Promise<StockData> {
  // Priority: Finnhub (free, reliable) -> Alpha Vantage (backup)
  const apis = [
    { name: 'finnhub', fn: () => fetchFromFinnhub(symbol) },
    { name: 'alphavantage', fn: () => fetchFromAlphaVantage(symbol) }
  ]

  for (const api of apis) {
    try {
      console.log(`🔌 Trying ${api.name} for ${symbol}`)
      const data = await retryWithBackoff(api.fn, MAX_RETRIES)
      
      if (data) {
        console.log(`✅ Success with ${api.name} for ${symbol}`)
        return data
      }
    } catch (error) {
      console.warn(`⚠️ ${api.name} failed for ${symbol}:`, error.message)
      continue
    }
  }

  throw new Error(`All APIs failed for ${symbol}`)
}

async function fetchFromFinnhub(symbol: string): Promise<StockData | null> {
  if (!FINNHUB_API_KEY) {
    throw new Error('Finnhub API key not configured')
  }

  const url = `https://finnhub.io/api/v1/quote?symbol=${symbol}&token=${FINNHUB_API_KEY}`
  
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'ChartSenseApp/1.0'
    }
  })

  if (!response.ok) {
    throw new Error(`Finnhub API error: ${response.status}`)
  }

  const data = await response.json()

  // Check for API errors
  if (data.error) {
    throw new Error(`Finnhub: ${data.error}`)
  }

  // Validate required fields
  if (!data.c || data.c === 0) {
    return null // No data available
  }

  const currentPrice = data.c
  const previousClose = data.pc
  const dailyChange = currentPrice - previousClose
  const dailyChangePercent = previousClose > 0 ? (dailyChange / previousClose) * 100 : 0

  // Get company name (separate API call, cached)
  const companyName = await getCompanyNameFinnhub(symbol)

  return {
    symbol,
    companyName,
    currentPrice,
    previousClose,
    dailyChange,
    dailyChangePercent,
    volume: data.v || 0,
    high: data.h || currentPrice,
    low: data.l || currentPrice,
    openPrice: data.o || previousClose,
    lastUpdated: new Date().toISOString(),
    source: 'finnhub'
  }
}

async function fetchFromAlphaVantage(symbol: string): Promise<StockData | null> {
  if (!ALPHA_VANTAGE_API_KEY) {
    throw new Error('Alpha Vantage API key not configured')
  }

  const url = `https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=${symbol}&apikey=${ALPHA_VANTAGE_API_KEY}`
  
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'ChartSenseApp/1.0'
    }
  })

  if (!response.ok) {
    throw new Error(`Alpha Vantage API error: ${response.status}`)
  }

  const data = await response.json()

  if (data['Error Message']) {
    throw new Error(`Alpha Vantage: ${data['Error Message']}`)
  }

  if (data['Information']) {
    throw new Error('Alpha Vantage rate limit exceeded')
  }

  const quote = data['Global Quote']
  if (!quote || !quote['05. price']) {
    return null
  }

  const currentPrice = parseFloat(quote['05. price'])
  const previousClose = parseFloat(quote['08. previous close'])
  const dailyChange = parseFloat(quote['09. change'])
  const dailyChangePercent = parseFloat(quote['10. change percent'].replace('%', ''))

  return {
    symbol,
    companyName: symbol, // Alpha Vantage doesn't provide company name in quote
    currentPrice,
    previousClose,
    dailyChange,
    dailyChangePercent,
    volume: parseInt(quote['06. volume'] || '0'),
    high: parseFloat(quote['03. high']),
    low: parseFloat(quote['04. low']),
    openPrice: parseFloat(quote['02. open']),
    lastUpdated: new Date().toISOString(),
    source: 'alphavantage'
  }
}

async function getCompanyNameFinnhub(symbol: string): Promise<string> {
  if (!FINNHUB_API_KEY) {
    return symbol
  }

  try {
    const url = `https://finnhub.io/api/v1/stock/profile2?symbol=${symbol}&token=${FINNHUB_API_KEY}`
    const response = await fetch(url)
    
    if (response.ok) {
      const data = await response.json()
      return data.name || symbol
    }
  } catch (error) {
    console.warn(`Failed to get company name for ${symbol}:`, error.message)
  }

  return symbol
}

async function retryWithBackoff<T>(
  fn: () => Promise<T>, 
  maxRetries: number, 
  delay: number = RETRY_DELAY_MS
): Promise<T> {
  let lastError: Error

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error
      
      if (attempt === maxRetries) {
        throw lastError
      }

      console.warn(`Attempt ${attempt} failed, retrying in ${delay}ms...`)
      await new Promise(resolve => setTimeout(resolve, delay))
      delay *= 2 // Exponential backoff
    }
  }

  throw lastError!
}

function isExpired(expiresAt: string): boolean {
  return new Date(expiresAt) < new Date()
} 