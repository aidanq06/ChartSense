import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FinnhubQuoteResponse {
  c: number;  // Current price
  d: number;  // Change
  dp: number; // Percent change
  h: number;  // High price of the day
  l: number;  // Low price of the day
  o: number;  // Open price of the day
  pc: number; // Previous close price
  v?: number; // Volume
}

interface StockData {
  symbol: string;
  current_price: number;
  daily_change: number;
  daily_change_percent: number;
  volume?: number;
  last_updated: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get Finnhub API key
    const finnhubApiKey = Deno.env.get('FINNHUB_API_KEY')
    if (!finnhubApiKey) {
      throw new Error('FINNHUB_API_KEY environment variable is required')
    }

    // Parse request
    const { symbol, symbols } = await req.json()
    
    if (!symbol && !symbols) {
      return new Response(
        JSON.stringify({ error: 'Either symbol or symbols array is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Handle single symbol or array of symbols
    const symbolsToFetch = symbols || [symbol]
    const results: StockData[] = []
    const errors: string[] = []

    // Process each symbol
    for (const sym of symbolsToFetch) {
      try {
        console.log(`Fetching data for ${sym}`)
        
        // Fetch from Finnhub API
        const finnhubUrl = `https://finnhub.io/api/v1/quote?symbol=${sym.toUpperCase()}&token=${finnhubApiKey}`
        const response = await fetch(finnhubUrl)

    if (!response.ok) {
          if (response.status === 429) {
            errors.push(`Rate limit exceeded for ${sym}`)
            continue
          }
          throw new Error(`Finnhub API error: ${response.status}`)
    }

        const data: FinnhubQuoteResponse = await response.json()
    
        // Validate data
        if (!data.c || data.c === 0) {
          errors.push(`No data available for ${sym}`)
          continue
        }

        // Prepare stock data
        const stockData: StockData = {
          symbol: sym.toUpperCase(),
          current_price: data.c,
          daily_change: data.d,
          daily_change_percent: data.dp,
          volume: data.v,
          last_updated: new Date().toISOString()
        }

        // Get or create stock record
        const { data: existingStock, error: stockError } = await supabaseClient
          .from('stocks')
          .select('id')
          .eq('symbol', sym.toUpperCase())
          .single()

        if (stockError && stockError.code !== 'PGRST116') {
          console.error(`Error fetching stock ${sym}:`, stockError)
          errors.push(`Database error for ${sym}: ${stockError.message}`)
          continue
    }

        // If stock doesn't exist, create it
        if (!existingStock) {
          const { error: insertError } = await supabaseClient
            .from('stocks')
            .insert({
              symbol: sym.toUpperCase(),
              company_name: `${sym.toUpperCase()} Corporation`, // Will be updated later with real company data
              is_active: true
            })

          if (insertError) {
            console.error(`Error creating stock ${sym}:`, insertError)
            errors.push(`Failed to create stock record for ${sym}`)
            continue
          }
        }

        // Upsert stock price data
        const { error: priceError } = await supabaseClient
          .from('stock_prices')
          .upsert({
            symbol: stockData.symbol,
            current_price: stockData.current_price,
            daily_change: stockData.daily_change,
            daily_change_percent: stockData.daily_change_percent,
            volume: stockData.volume,
            last_updated: stockData.last_updated
          }, {
            onConflict: 'symbol'
          })

        if (priceError) {
          console.error(`Error updating price for ${sym}:`, priceError)
          errors.push(`Failed to update price for ${sym}: ${priceError.message}`)
          continue
        }

        // Store historical data point
        const { error: historyError } = await supabaseClient
          .from('stock_history')
          .upsert({
            symbol: stockData.symbol,
            date_time: stockData.last_updated,
            open_price: data.o,
            high_price: data.h,
            low_price: data.l,
            close_price: data.c,
            volume: data.v || 0,
            period: '1d'
          }, {
            onConflict: 'symbol,date_time,period'
          })

        if (historyError) {
          console.log(`Warning: Could not store historical data for ${sym}:`, historyError.message)
        }

        results.push(stockData)
        console.log(`Successfully processed ${sym}`)

        // Add small delay to avoid rate limiting
        if (symbolsToFetch.length > 1) {
          await new Promise(resolve => setTimeout(resolve, 200))
        }

      } catch (error) {
        console.error(`Error processing ${sym}:`, error)
        errors.push(`Failed to process ${sym}: ${error.message}`)
      }
    }

    // Return results
    const response = {
      success: results.length > 0,
      data: results,
      errors: errors.length > 0 ? errors : undefined,
      processed: results.length,
      failed: errors.length,
      timestamp: new Date().toISOString()
    }

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: results.length > 0 ? 200 : 207 // 207 Multi-Status if some failed
      }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

/* Usage Examples:

1. Fetch single stock:
POST /functions/v1/fetch-stock-data
{
  "symbol": "AAPL"
}

2. Fetch multiple stocks:
POST /functions/v1/fetch-stock-data
{
  "symbols": ["AAPL", "TSLA", "GOOGL"]
}

3. Scheduled execution (via cron):
This function can be called automatically every minute via pg_cron:
SELECT cron.schedule('fetch-popular-stocks', '* * * * *', $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/fetch-stock-data',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}',
    body := '{"symbols": ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA"]}'
  );
$$);

*/ 