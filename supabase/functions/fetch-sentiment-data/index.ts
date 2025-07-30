import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SentimentData {
  symbol: string;
  overall_rating: string;
  score: number;
  confidence: number;
  key_drivers: string[];
  news_positive: number;
  news_negative: number;
  news_neutral: number;
  analyst_sentiment: number;
  social_sentiment: number;
  technical_indicators: number;
}

// Sentiment rating mappings
const SENTIMENT_RATINGS = {
  STRONGLY_BULLISH: { min: 0.7, max: 1.0, rating: 'stronglyBullish' },
  BULLISH: { min: 0.4, max: 0.7, rating: 'bullish' },
  CAUTIOUSLY_OPTIMISTIC: { min: 0.1, max: 0.4, rating: 'cautiouslyOptimistic' },
  NEUTRAL: { min: -0.1, max: 0.1, rating: 'neutral' },
  BEARISH_UNDERCURRENTS: { min: -0.4, max: -0.1, rating: 'bearishUndercurrents' },
  BEARISH: { min: -0.7, max: -0.4, rating: 'bearish' },
  HIGHLY_NEGATIVE: { min: -1.0, max: -0.7, rating: 'highlyNegative' }
}

function getSentimentRating(score: number): string {
  for (const [_, config] of Object.entries(SENTIMENT_RATINGS)) {
    if (score >= config.min && score <= config.max) {
      return config.rating
    }
  }
  return 'neutral'
}

function generateKeyDrivers(rating: string, newsData: any[]): string[] {
  const positiveDrivers = [
    "Strong earnings beat with revenue up 15% YoY",
    "Positive analyst upgrades from major firms",
    "New product launches driving market excitement",
    "Expansion into emerging markets showing promise",
    "AI integration boosting operational efficiency",
    "Strong cash flow generation and balance sheet",
    "Market share gains in key segments",
    "Successful cost reduction initiatives"
  ]

  const negativeDrivers = [
    "Concerns about rising production costs",
    "Regulatory challenges in key markets",
    "Increased competition pressuring margins",
    "Supply chain disruptions affecting delivery",
    "Macroeconomic headwinds impacting demand",
    "Management guidance disappointment",
    "Declining market share in core business",
    "Elevated debt levels raising concerns"
  ]

  const neutralDrivers = [
    "Mixed earnings results with some bright spots",
    "Ongoing strategic transformation initiatives",
    "Market consolidation creating uncertainty",
    "Seasonal factors affecting performance",
    "Investor focus on long-term growth prospects",
    "Awaiting clarity on regulatory developments",
    "Balancing growth investments with profitability"
  ]

  let drivers: string[]
  if (rating.includes('bullish') || rating === 'cautiouslyOptimistic') {
    drivers = positiveDrivers.sort(() => 0.5 - Math.random()).slice(0, 3)
  } else if (rating.includes('bearish') || rating === 'highlyNegative') {
    drivers = negativeDrivers.sort(() => 0.5 - Math.random()).slice(0, 3)
  } else {
    drivers = neutralDrivers.sort(() => 0.5 - Math.random()).slice(0, 2)
  }

  return drivers
}

function calculateSentimentFromNews(newsData: any[]): {
  positive: number;
  negative: number;
  neutral: number;
  overallScore: number;
} {
  if (newsData.length === 0) {
    return { positive: 0.33, negative: 0.33, neutral: 0.34, overallScore: 0 }
  }

  let totalSentiment = 0
  let positiveCount = 0
  let negativeCount = 0
  let neutralCount = 0

  for (const article of newsData) {
    const sentiment = article.sentiment_score || 0
    totalSentiment += sentiment

    if (sentiment > 0.1) positiveCount++
    else if (sentiment < -0.1) negativeCount++
    else neutralCount++
  }

  const total = newsData.length
  return {
    positive: positiveCount / total,
    negative: negativeCount / total,
    neutral: neutralCount / total,
    overallScore: totalSentiment / total
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { symbol, symbols } = await req.json()
    
    if (!symbol && !symbols) {
      return new Response(
        JSON.stringify({ error: 'Either symbol or symbols array is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const symbolsToProcess = symbols || [symbol]
    const results: SentimentData[] = []
    const errors: string[] = []

    for (const sym of symbolsToProcess) {
      try {
        console.log(`Generating sentiment analysis for ${sym}`)

        // Fetch recent news for this symbol
        const { data: newsData, error: newsError } = await supabaseClient
          .from('news_articles')
          .select('*')
          .contains('symbols', [sym.toUpperCase()])
          .gte('published_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()) // Last 7 days
          .order('published_at', { ascending: false })
          .limit(50)

        if (newsError) {
          console.error(`Error fetching news for ${sym}:`, newsError)
        }

        // Calculate sentiment from news
        const newsSentiment = calculateSentimentFromNews(newsData || [])

        // Generate additional sentiment components (mock data for now)
        const analystSentiment = (Math.random() - 0.5) * 2 // -1 to 1
        const socialSentiment = (Math.random() - 0.5) * 2  // -1 to 1
        const technicalIndicators = (Math.random() - 0.5) * 2 // -1 to 1

        // Calculate overall sentiment score (weighted average)
        const overallScore = (
          newsSentiment.overallScore * 0.4 +
          analystSentiment * 0.3 +
          socialSentiment * 0.2 +
          technicalIndicators * 0.1
        )

        // Determine sentiment rating
        const overallRating = getSentimentRating(overallScore)
        
        // Generate key drivers
        const keyDrivers = generateKeyDrivers(overallRating, newsData || [])

        // Calculate confidence based on data availability
        const confidence = Math.min(0.95, 0.6 + (newsData?.length || 0) * 0.01)

        const sentimentData: SentimentData = {
          symbol: sym.toUpperCase(),
          overall_rating: overallRating,
          score: Math.round(overallScore * 1000) / 1000, // Round to 3 decimal places
          confidence: Math.round(confidence * 1000) / 1000,
          key_drivers: keyDrivers,
          news_positive: Math.round(newsSentiment.positive * 1000) / 1000,
          news_negative: Math.round(newsSentiment.negative * 1000) / 1000,
          news_neutral: Math.round(newsSentiment.neutral * 1000) / 1000,
          analyst_sentiment: Math.round(analystSentiment * 1000) / 1000,
          social_sentiment: Math.round(socialSentiment * 1000) / 1000,
          technical_indicators: Math.round(technicalIndicators * 1000) / 1000
        }

        // Get stock ID
        const { data: stockData, error: stockError } = await supabaseClient
          .from('stocks')
          .select('id')
          .eq('symbol', sym.toUpperCase())
          .single()

        if (stockError) {
          console.error(`Error fetching stock ${sym}:`, stockError)
          errors.push(`Stock not found: ${sym}`)
          continue
        }

        // Upsert sentiment analysis
        const { error: sentimentError } = await supabaseClient
          .from('sentiment_analysis')
          .upsert({
            stock_id: stockData.id,
            symbol: sentimentData.symbol,
            overall_rating: sentimentData.overall_rating,
            score: sentimentData.score,
            confidence: sentimentData.confidence,
            key_drivers: sentimentData.key_drivers,
            news_positive: sentimentData.news_positive,
            news_negative: sentimentData.news_negative,
            news_neutral: sentimentData.news_neutral,
            analyst_sentiment: sentimentData.analyst_sentiment,
            social_sentiment: sentimentData.social_sentiment,
            technical_indicators: sentimentData.technical_indicators,
            last_updated: new Date().toISOString()
          }, {
            onConflict: 'symbol'
          })

        if (sentimentError) {
          console.error(`Error updating sentiment for ${sym}:`, sentimentError)
          errors.push(`Failed to update sentiment for ${sym}: ${sentimentError.message}`)
          continue
        }

        results.push(sentimentData)
        console.log(`Successfully generated sentiment for ${sym}: ${overallRating} (${overallScore})`)

        // Small delay to avoid overwhelming the system
        if (symbolsToProcess.length > 1) {
          await new Promise(resolve => setTimeout(resolve, 100))
        }

      } catch (error) {
        console.error(`Error processing sentiment for ${sym}:`, error)
        errors.push(`Failed to process sentiment for ${sym}: ${error.message}`)
      }
    }

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
        status: results.length > 0 ? 200 : 207
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