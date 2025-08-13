-- Combined AI usage RPC to support both text and image quotas

create or replace function public.increment_ai_usage(
  p_user_id uuid,
  p_text_limit integer,
  p_image_limit integer,
  p_is_image boolean
)
returns boolean
language plpgsql
as $$
begin
  if p_is_image then
    -- Ensure image usage row exists and update limit
    insert into public.image_analysis_usage_daily(user_id, day, used, daily_limit)
    values (p_user_id, current_date, 0, p_image_limit)
    on conflict(user_id, day) do update set daily_limit = excluded.daily_limit;

    -- Increment if under limit
    update public.image_analysis_usage_daily
    set used = used + 1
    where user_id = p_user_id and day = current_date and used < daily_limit;
    if found then
      return true;
    else
      return false;
    end if;
  else
    -- Ensure text usage row exists and update limit
    insert into public.ai_chat_usage_daily(user_id, day, used, daily_limit)
    values (p_user_id, current_date, 0, p_text_limit)
    on conflict(user_id, day) do update set daily_limit = excluded.daily_limit;

    -- Increment if under limit
    update public.ai_chat_usage_daily
    set used = used + 1
    where user_id = p_user_id and day = current_date and used < daily_limit;
    if found then
      return true;
    else
      return false;
    end if;
  end if;
end; $$;

grant execute on function public.increment_ai_usage(uuid, integer, integer, boolean) to anon, authenticated;

commit;


