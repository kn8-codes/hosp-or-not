-- HOSP or Not — live schema/policy checks before migration
-- Read-only inspection queries.

-- ------------------------------------------------------------
-- 1. table columns
-- ------------------------------------------------------------
select table_name, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name in ('posts', 'votes', 'profiles', 'actors', 'guest_sessions')
order by table_name, ordinal_position;

-- ------------------------------------------------------------
-- 2. constraints on votes
-- ------------------------------------------------------------
select
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name as foreign_table_name,
  ccu.column_name as foreign_column_name
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
  and tc.table_schema = kcu.table_schema
left join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name
  and tc.table_schema = ccu.table_schema
where tc.table_schema = 'public'
  and tc.table_name = 'votes'
order by tc.constraint_type, tc.constraint_name;

-- ------------------------------------------------------------
-- 3. indexes on votes
-- ------------------------------------------------------------
select indexname, indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'votes';

-- ------------------------------------------------------------
-- 4. policies on key tables
-- ------------------------------------------------------------
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('posts', 'votes', 'profiles', 'actors', 'guest_sessions')
order by tablename, policyname;

-- ------------------------------------------------------------
-- 5. triggers on key tables
-- ------------------------------------------------------------
select event_object_table as table_name, trigger_name, action_timing, event_manipulation, action_statement
from information_schema.triggers
where trigger_schema = 'public'
  and event_object_table in ('posts', 'votes', 'profiles', 'actors', 'guest_sessions')
order by event_object_table, trigger_name;

-- ------------------------------------------------------------
-- 6. quick row counts
-- ------------------------------------------------------------
select 'posts' as table_name, count(*) from public.posts
union all
select 'votes' as table_name, count(*) from public.votes;
