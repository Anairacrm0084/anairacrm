-- Phase 24: Real SEO Command Center / onboarding / automation support.
alter table public.crm_seo_sites
  add column if not exists verification_status text not null default 'pending',
  add column if not exists verification_method text,
  add column if not exists verified_at timestamptz,
  add column if not exists sitemap_url text,
  add column if not exists robots_url text,
  add column if not exists primary_gsc_property text,
  add column if not exists primary_ga4_property text,
  add column if not exists public_token text;
create unique index if not exists crm_seo_sites_public_token_uq on public.crm_seo_sites(public_token) where public_token is not null;
create table if not exists public.crm_seo_pagespeed_runs (id uuid primary key default gen_random_uuid(),site_id uuid not null,page_id uuid,url text not null,strategy text not null default 'mobile',performance numeric,accessibility numeric,best_practices numeric,seo numeric,lcp numeric,cls numeric,inp numeric,fcp numeric,ttfb numeric,response jsonb not null default '{}'::jsonb,created_at timestamptz not null default now());
create table if not exists public.crm_seo_score_history (id uuid primary key default gen_random_uuid(),site_id uuid not null,audit_id uuid,score numeric not null default 0,pages_scanned integer not null default 0,errors integer not null default 0,warnings integer not null default 0,notices integer not null default 0,created_at timestamptz not null default now());
create table if not exists public.crm_seo_automation_jobs (id uuid primary key default gen_random_uuid(),site_id uuid not null,job_type text not null,enabled boolean not null default true,interval_minutes integer not null default 1440,next_run_at timestamptz not null default now(),last_run_at timestamptz,settings jsonb not null default '{}'::jsonb,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(site_id,job_type));
create table if not exists public.crm_seo_automation_runs (id uuid primary key default gen_random_uuid(),job_id uuid not null,site_id uuid not null,job_type text not null,status text not null default 'running',result jsonb not null default '{}'::jsonb,error text,started_at timestamptz not null default now(),completed_at timestamptz);
