begin;

alter table public.symbols add column if not exists is_baseline boolean not null default false;
create index if not exists idx_symbols_is_baseline on public.symbols(is_baseline);

commit;


