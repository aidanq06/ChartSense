# AI Backend (Supabase + Google Gemini)

This folder documents the AI backend so it’s crystal clear what powers the in‑app AI chat and image analysis. All runtime code lives under `supabase/` so Supabase can deploy it. This README tells you exactly what files exist, what they do, and how to deploy/test.

## What you get
- Text AI chat via Google Gemini Flash (cheap + vision capable).
- Vision image analysis for charts with server‑enforced quotas.
- Server‑side daily limits: Free users 5 text/day, 1 image/day; premium up to 200/day.

## Files added or updated
- `supabase/migrations/027_ai_image_usage.sql`
  - Adds `public.image_analysis_usage_daily` table
  - Adds `public.increment_image_analysis_usage(uuid, integer)` RPC
  - Enables RLS and owner‑read policy for that table
- `supabase/migrations/028_increment_ai_usage.sql`
  - Adds `public.increment_ai_usage(uuid, integer, integer, boolean)` RPC used by the functions to atomically enforce either text or image quotas
- `supabase/functions/ai-chat/index.ts` (updated)
  - Calls Gemini for text responses
  - Enforces daily text quotas via `ai_chat_usage_daily` (migration 010) and `increment_ai_usage`
- `supabase/functions/image-analysis/index.ts` (new)
  - Calls Gemini vision on a base64 chart image
  - Enforces image analysis quotas via `image_analysis_usage_daily` and `increment_ai_usage`

Nothing else in your iOS app was changed by these files. Once deployed, you can call these functions from the app using the user’s JWT.

## Environment secrets
Set these one time in your Supabase project (Project → Settings → Secrets or CLI):

```
supabase secrets set GOOGLE_API_KEY=YOUR_GEMINI_KEY
supabase secrets set SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY
```

Notes:
- Do not use the `SUPABASE_` prefix for your own secrets. `SERVICE_ROLE_KEY` is correct.
- The functions read `SUPABASE_URL` and `SUPABASE_ANON_KEY` automatically.

## Deploy steps
1) Apply database migrations
```
supabase db push
```
2) Deploy functions
```
supabase functions deploy ai-chat
supabase functions deploy image-analysis
```

## Test quickly with curl
Get a user JWT (sign in via app or REST). Then:

- Text chat
```
curl -sS -X POST \
  "https://YOUR_PROJECT_REF.functions.supabase.co/ai-chat" \
  -H "Authorization: Bearer USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"message":"Analyze AAPL"}'
```

- Image analysis (base64 of a small PNG/JPEG chart)
```
curl -sS -X POST \
  "https://YOUR_PROJECT_REF.functions.supabase.co/image-analysis" \
  -H "Authorization: Bearer USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"image_base64":"<BASE64>","mime_type":"image/png"}'
```

If you see 429, your daily limit is reached. If 401, you likely didn’t pass a valid user JWT. If 502, check `GOOGLE_API_KEY`.

## How quotas work
- Text: `ai_chat_usage_daily` (migration 010) + `increment_ai_usage(..., p_is_image = false)`.
- Images: `image_analysis_usage_daily` (migration 027) + `increment_ai_usage(..., p_is_image = true)`.
- The functions call the RPC first. If it returns false, request is denied with 429.

## Tuning the assistant
- Change model: edit model constants in the functions (`gemini-2.5-flash` or `gemini-1.5-flash`).
- Adjust style: edit `SYSTEM_PROMPT` (or `system_prompt` request override).
- Cost control: keep `temperature` low and `maxOutputTokens` modest.

## iOS integration pointers
- Text: `POST /functions/v1/ai-chat` with `{ message }` and the user’s `Authorization: Bearer <JWT>` header.
- Image: `POST /functions/v1/image-analysis` with `{ image_base64, mime_type, prompt? }` and JWT header.
- You can keep local UX gating via `PremiumManager`, but server‑side limits are authoritative.

## Troubleshooting
- 401 Unauthorized: ensure you pass a real user JWT in `Authorization` (not anon key).
- 429 Limit reached: working as designed; limits reset daily (UTC).
- 502 LLM error: verify `GOOGLE_API_KEY`.
- Deploy errors: ensure Docker is running locally if the CLI requires it.

---
This README exists so future-you immediately knows where the AI backend lives and how to operate it. All runtime code is under `supabase/functions/` and schema under `supabase/migrations/`.
