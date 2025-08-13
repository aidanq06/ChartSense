-- AI chat dual-limit tracking (messages + images) and RPC
begin;

-- Add columns to track separate usage if they don't exist
do $$ begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'ai_chat_usage_daily' and column_name = 'messages_used'
  ) then
    alter table public.ai_chat_usage_daily add column messages_used integer not null default 0;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'ai_chat_usage_daily' and column_name = 'images_used'
  ) then
    alter table public.ai_chat_usage_daily add column images_used integer not null default 0;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'ai_chat_usage_daily' and column_name = 'text_daily_limit'
  ) then
    alter table public.ai_chat_usage_daily add column text_daily_limit integer not null default 5;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'ai_chat_usage_daily' and column_name = 'image_daily_limit'
  ) then
    alter table public.ai_chat_usage_daily add column image_daily_limit integer not null default 1;
  end if;
end $$;

-- Backfill new limits from existing daily_limit if present (best-effort)
update public.ai_chat_usage_daily
set text_daily_limit = coalesce(nullif(daily_limit, 0), 5),
    image_daily_limit = 1
where true;

-- New RPC that atomically increments the appropriate counters.
drop function if exists public.increment_ai_usage(uuid, integer, integer, boolean);
create or replace function public.increment_ai_usage(
  p_user_id uuid,
  p_text_limit integer,
  p_image_limit integer,
  p_is_image boolean
) returns boolean language plpgsql as $$
declare
  r public.ai_chat_usage_daily;
begin
  -- Ensure row exists for today with provided limits
  insert into public.ai_chat_usage_daily(user_id, day, used, daily_limit, messages_used, images_used, text_daily_limit, image_daily_limit)
  values (p_user_id, current_date, 0, p_text_limit, 0, 0, p_text_limit, p_image_limit)
  on conflict(user_id, day) do update
    set text_daily_limit = excluded.text_daily_limit,
        image_daily_limit = excluded.image_daily_limit,
        daily_limit = excluded.text_daily_limit; -- keep old column in sync for compatibility

  if p_is_image then
    update public.ai_chat_usage_daily
    set used = used + 1,
        messages_used = messages_used + 1,
        images_used = images_used + 1
    where user_id = p_user_id
      and day = current_date
      and messages_used < text_daily_limit
      and images_used < image_daily_limit
    returning * into r;
  else
    update public.ai_chat_usage_daily
    set used = used + 1,
        messages_used = messages_used + 1
    where user_id = p_user_id
      and day = current_date
      and messages_used < text_daily_limit
    returning * into r;
  end if;

  if not found then
    return false;
  end if;
  return true;
end; $$;

grant execute on function public.increment_ai_usage(uuid, integer, integer, boolean) to anon, authenticated;

commit;



