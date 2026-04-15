# HOSP or Not — Base Schema Notes

I checked the repo before packaging this.

## What exists in repo now
Existing SQL/docs in repo are all for the newer auth/actor migration work:
- `supabase-migration-auth-actor-plan.sql`
- `supabase-post-cutover-direct-insert-block.sql`
- `SUPABASE-LIVE-CHECKS.sql`
- `RPC-SMOKE-TESTS.sql`

## What does **not** exist in repo
There was no pre-existing dedicated base schema SQL file or migrations folder for the original HOSP schema.

That means the original database setup appears to have lived only in the README instructions.

## What I packaged
- `supabase-base-schema-from-readme.sql`

This is the README schema turned into a standalone SQL file so it can be reviewed/applied cleanly.

## Important order
If the target Supabase project does not already contain `posts` and `votes`, the order is:
1. apply `supabase-base-schema-from-readme.sql`
2. verify `posts` and `votes` exist
3. then apply `supabase-migration-auth-actor-plan.sql`
4. only later apply `supabase-post-cutover-direct-insert-block.sql`
