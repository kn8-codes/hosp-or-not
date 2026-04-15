-- HOSP or Not
-- Base schema packaged from the current repo README
-- Use this only if the target Supabase project does not already have the base HOSP tables.

create extension if not exists pgcrypto;

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  photo_url text not null,
  description text not null,
  exif_verified boolean default false,
  exif_data jsonb,
  status text default 'open' check (status in ('open', 'closed')),
  outcome text,
  created_at timestamptz default now(),
  closed_at timestamptz
);

create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.posts(id) on delete cascade,
  vote boolean not null,
  blurb text,
  created_at timestamptz default now()
);

-- Storage bucket note from README:
-- Create a public storage bucket named `photos`.
-- Add RLS policies for anonymous access to both tables and the storage bucket.
