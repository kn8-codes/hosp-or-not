-- HOSP or Not
-- Post-cutover patch: block direct client inserts to votes
-- Run this ONLY after frontend RPC voting is confirmed working in production.

begin;

DROP POLICY IF EXISTS "votes_no_direct_insert" ON public.votes;
create policy "votes_no_direct_insert"
  on public.votes
  for insert
  to anon, authenticated
  with check (false);

commit;
