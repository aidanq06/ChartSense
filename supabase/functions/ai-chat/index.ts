import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ChatRequest {
  message: string;
  conversation_id?: string;
  message_type?: 'text' | 'image_analysis' | 'chart_analysis';
  metadata?: Record<string, any>;
}

interface ChatResponse {
  success: boolean;
  conversation_id: string;
  message_id: string;
  response: string;
  usage_remaining?: number;
  error?: string;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from auth header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extract user from token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid authentication token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { message, conversation_id, message_type = 'text', metadata = {} }: ChatRequest = await req.json()

    if (!message || message.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Message content is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user profile and check usage limits
    const { data: userProfile, error: profileError } = await supabaseClient
      .from('user_profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profileError || !userProfile) {
      return new Response(
        JSON.stringify({ error: 'User profile not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if user can send AI messages
    if (!userProfile.is_premium && userProfile.ai_messages_used_today >= userProfile.ai_messages_limit) {
      return new Response(
        JSON.stringify({ 
          error: 'Daily AI message limit reached. Upgrade to premium for unlimited messages.',
          usage_remaining: 0
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get or create conversation
    let conversationId = conversation_id
    if (!conversationId) {
      const { data: newConversation, error: convError } = await supabaseClient
        .from('ai_conversations')
        .insert({
          user_id: user.id,
          title: message.substring(0, 50) + (message.length > 50 ? '...' : '')
        })
        .select('id')
        .single()

      if (convError || !newConversation) {
        return new Response(
          JSON.stringify({ error: 'Failed to create conversation' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      conversationId = newConversation.id
    }

    // Store user message
    const { data: userMessage, error: userMsgError } = await supabaseClient
      .from('ai_messages')
      .insert({
        conversation_id: conversationId,
        user_id: user.id,
        content: message,
        is_user: true,
        message_type,
        metadata
      })
      .select('id')
      .single()

    if (userMsgError || !userMessage) {
      return new Response(
        JSON.stringify({ error: 'Failed to store user message' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate AI response
    let aiResponse: string
    
    // Check if OpenAI API key is available
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    
    if (openaiApiKey) {
      // Use OpenAI API for real AI responses
      try {
        const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${openaiApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'gpt-3.5-turbo',
            messages: [
              {
                role: 'system',
                content: 'You are a helpful financial AI assistant for ChartSense app. Provide accurate, helpful financial advice and stock analysis. Keep responses concise but informative.'
              },
              {
                role: 'user',
                content: message
              }
            ],
            max_tokens: 500,
            temperature: 0.7
          })
        })

        if (openaiResponse.ok) {
          const openaiData = await openaiResponse.json()
          aiResponse = openaiData.choices[0]?.message?.content || 'I apologize, but I could not generate a response at this time.'
        } else {
          throw new Error('OpenAI API request failed')
        }
      } catch (error) {
        console.error('OpenAI API error:', error)
        aiResponse = generateMockResponse(message)
      }
    } else {
      // Use mock responses when OpenAI is not available
      aiResponse = generateMockResponse(message)
    }

    // Store AI response
    const { data: aiMessage, error: aiMsgError } = await supabaseClient
      .from('ai_messages')
      .insert({
        conversation_id: conversationId,
        user_id: user.id,
        content: aiResponse,
        is_user: false,
        message_type,
        metadata: { ...metadata, generated_at: new Date().toISOString() }
      })
      .select('id')
      .single()

    if (aiMsgError || !aiMessage) {
      return new Response(
        JSON.stringify({ error: 'Failed to store AI response' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update user usage tracking (only for non-premium users)
    if (!userProfile.is_premium) {
      const { error: usageError } = await supabaseClient
        .from('user_profiles')
        .update({
          ai_messages_used_today: userProfile.ai_messages_used_today + 1
        })
        .eq('id', user.id)

      if (usageError) {
        console.error('Error updating usage:', usageError)
      }

      // Track usage in usage_tracking table
      await supabaseClient.rpc('increment_usage_tracking', {
        p_user_id: user.id,
        p_feature_type: 'ai_message',
        p_metadata: { message_type, conversation_id: conversationId }
      })
    }

    // Calculate remaining usage
    const usageRemaining = userProfile.is_premium ? 
      999999 : 
      Math.max(0, userProfile.ai_messages_limit - (userProfile.ai_messages_used_today + 1))

    const response: ChatResponse = {
      success: true,
      conversation_id: conversationId,
      message_id: aiMessage.id,
      response: aiResponse,
      usage_remaining: usageRemaining
    }

    return new Response(
      JSON.stringify(response),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('AI Chat function error:', error)
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

function generateMockResponse(message: string): string {
  const lowerMessage = message.toLowerCase()
  
  // Stock analysis responses
  if (lowerMessage.includes('aapl') || lowerMessage.includes('apple')) {
    return `📱 **Apple (AAPL) Analysis**

**Current Performance:**
• Strong fundamentals with consistent revenue growth
• Services segment showing impressive expansion  
• iPhone sales remain stable despite market challenges

**Key Strengths:**
• Robust ecosystem lock-in
• Strong brand loyalty
• Excellent cash flow generation

**Considerations:**
• High valuation multiples
• Dependency on iPhone sales
• Regulatory risks in various markets

**Recommendation:** Apple remains a solid long-term investment, but consider dollar-cost averaging given current valuations.`
  }
  
  if (lowerMessage.includes('market') && lowerMessage.includes('trend')) {
    return `📊 **Current Market Trends**

**Leading Sectors:**
• **Technology:** AI and cloud computing driving growth
• **Healthcare:** Biotech innovations and aging population
• **Energy:** Clean energy transition accelerating

**Market Sentiment:**
• Cautious optimism amid economic uncertainty
• Focus on quality companies with strong fundamentals
• Interest rate sensitivity remains a key factor

**Investment Strategy:**
Consider a balanced approach with exposure to growth sectors while maintaining defensive positions.`
  }
  
  if (lowerMessage.includes('portfolio') || lowerMessage.includes('diversify')) {
    return `💼 **Portfolio Diversification Strategy**

**Recommended Allocation:**
• **40% Large Cap Growth:** AAPL, MSFT, GOOGL
• **25% Value Stocks:** JNJ, PG, KO
• **20% International:** VXUS, IEFA
• **10% Bonds:** BND, AGG
• **5% Alternative:** Gold, REITs

**Key Principles:**
• Don't put all eggs in one basket
• Rebalance quarterly
• Consider your risk tolerance
• Think long-term (5+ years)

**Next Steps:** Start with index funds for broad exposure, then add individual stocks gradually.`
  }
  
  if (lowerMessage.includes('risk')) {
    return `⚠️ **Current Market Risks**

**Primary Concerns:**
• **Inflation:** Persistent price pressures
• **Interest Rates:** Fed policy uncertainty
• **Geopolitical:** Global tensions and trade wars
• **Valuation:** Elevated P/E ratios in some sectors

**Risk Mitigation:**
• Maintain emergency fund (6 months expenses)
• Diversify across asset classes
• Consider defensive stocks (utilities, consumer staples)
• Regular portfolio rebalancing

**Monitoring:** Keep an eye on economic indicators and adjust strategy accordingly.`
  }
  
  // Default response
  return `🤖 **ChartSense AI Assistant**

I'm here to help you with financial analysis and investment insights! I can:

• 📈 Analyze individual stocks and sectors
• 📊 Explain market trends and patterns  
• 💡 Provide portfolio recommendations
• ⚠️ Assess market risks and opportunities
• 📰 Interpret financial news and events

Try asking me about specific stocks, market trends, or investment strategies. I'm constantly learning and improving to provide you with the best financial insights!`
}

/* Usage Examples:

1. Send a chat message:
POST /functions/v1/ai-chat
Authorization: Bearer USER_JWT_TOKEN
{
  "message": "What do you think about Apple stock?",
  "message_type": "text"
}

2. Continue existing conversation:
POST /functions/v1/ai-chat
Authorization: Bearer USER_JWT_TOKEN
{
  "message": "What about Tesla?",
  "conversation_id": "existing-conversation-uuid",
  "message_type": "text"
}

3. Image analysis request:
POST /functions/v1/ai-chat
Authorization: Bearer USER_JWT_TOKEN
{
  "message": "Analyze this chart pattern",
  "message_type": "image_analysis",
  "metadata": {
    "image_url": "https://example.com/chart.png",
    "symbol": "AAPL"
  }
}

*/ 