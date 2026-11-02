-- Wishlist: run once in Supabase SQL editor (or as postgres).
-- Replace the wishlist_api password before running in production.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.products (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    brand text NOT NULL,
    descriptor text NOT NULL DEFAULT '',
    price text NOT NULL,
    is_gift_pick boolean NOT NULL DEFAULT false,
    hero_image_url text NOT NULL,
    gallery_image_urls jsonb NOT NULL DEFAULT '[]'::jsonb,
    quick_tags jsonb NOT NULL DEFAULT '[]'::jsonb,
    about text NOT NULL DEFAULT '',
    highlights jsonb NOT NULL DEFAULT '[]'::jsonb,
    detail_tags jsonb NOT NULL DEFAULT '[]'::jsonb,
    sort_order integer NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    external_id text,
    catalog_meta jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS products_active_sort_idx ON public.products (is_active, sort_order DESC);

CREATE UNIQUE INDEX IF NOT EXISTS products_external_id_idx
    ON public.products (external_id)
    WHERE external_id IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wishlist_api') THEN
        CREATE ROLE wishlist_api LOGIN PASSWORD 'replace-with-strong-password';
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO wishlist_api;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO wishlist_api;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wishlist_api;

-- Optional: grant tooling admin if you use a separate DB user for Wishlist-Tooling
-- GRANT ALL ON public.products TO your_tooling_role;
