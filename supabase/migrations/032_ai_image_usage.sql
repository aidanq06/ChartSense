-- Image analysis daily usage tracking and quota RPC

create table if not exists public.image_analysis_usage_daily (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  used integer not null default 0,
  daily_limit integer not null default 1,
  primary key(user_id, day)
);
create index if not exists idx_image_analysis_usage_daily_user on public.image_analysis_usage_daily(user_id);

alter table public.image_analysis_usage_daily enable row level security;

drop policy if exists image_analysis_usage_read_own on public.image_analysis_usage_daily;
create policy image_analysis_usage_read_own
  on public.image_analysis_usage_daily
  for select using (auth.uid() = user_id);

-- RPC to increment image analysis usage atomically (server-enforced quotas)
create or replace function public.increment_image_analysis_usage(p_user_id uuid, p_limit integer)
returns boolean language plpgsql as $$
declare
  r public.image_analysis_usage_daily;
begin
  insert into public.image_analysis_usage_daily(user_id, day, used, daily_limit)
  values (p_user_id, current_date, 0, p_limit)
  on conflict(user_id, day) do update set daily_limit = excluded.daily_limit;

  update public.image_analysis_usage_daily
  set used = used + 1
  where user_id = p_user_id and day = current_date and used < daily_limit
  returning * into r;

  if not found then
    return false;
  end if;
  return true;
end; $$;
grant execute on function public.increment_image_analysis_usage(uuid, integer) to anon, authenticated;

commit;


