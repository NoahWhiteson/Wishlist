ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS external_id text,
    ADD COLUMN IF NOT EXISTS catalog_meta jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE UNIQUE INDEX IF NOT EXISTS products_external_id_idx
    ON public.products (external_id)
    WHERE external_id IS NOT NULL;
