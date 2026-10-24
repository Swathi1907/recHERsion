
-- SHIELD Evidence Vault
-- Stores evidence metadata, not the actual media files.

create table if not exists public.evidence_items (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null
        references auth.users(id) on delete cascade,

    title text not null
        check (char_length(trim(title)) between 1 and 200),

    evidence_type text not null
        check (evidence_type in ('photo', 'audio', 'video', 'note')),

    description text,

    -- Private storage object path; never store a public file URL here.
    storage_path text unique,

    -- SHA-256 hex digest, calculated by the trusted application.
    sha256 text
        check (sha256 is null or sha256 ~ '^[a-f0-9]{64}$'),

    captured_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    -- Hash verification is not the same as proving an incident occurred.
    verification_status text not null default 'pending'
        check (
            verification_status in (
                'pending',
                'verified',
                'mismatch',
                'unavailable'
            )
        )
);

create index if not exists evidence_items_user_created_idx
    on public.evidence_items (user_id, created_at desc);

-- Enable row-level security.
alter table public.evidence_items enable row level security;

-- Remove default access for unauthenticated users.
revoke all on table public.evidence_items from anon;

-- Signed-in users may perform operations only allowed by policies below.
grant select, insert, update, delete
    on table public.evidence_items to authenticated;

create policy "Users can view their own evidence"
    on public.evidence_items
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

create policy "Users can add their own evidence"
    on public.evidence_items
    for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

create policy "Users can update their own evidence"
    on public.evidence_items
    for update
    to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

create policy "Users can delete their own evidence"
    on public.evidence_items
    for delete
    to authenticated
    using ((select auth.uid()) = user_id);
