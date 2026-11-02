# Wishlist API

Small backend for the iOS app. Connects to Postgres (Supabase on Coolify) with a **dedicated DB user**, not Supabase platform keys in the app.

## Which Postgres user?

| Role | Use |
|------|-----|
| `postgres` | Migrations, backups, one-time SQL in Coolify — **never** in the app or API env on client devices |
| Supabase `service_role` | Full bypass RLS — **server-only** if you use Supabase Auth/Storage SDK; do not embed in iOS |
| Supabase `anon` / `authenticated` | For **direct** PostgREST/Supabase client from clients — we are **not** doing that here |
| **`wishlist_api`** | **Use this** for this API service’s `DATABASE_URL` |

Create `wishlist_api` with `sql/001_init.sql` (or run the `CREATE ROLE` block with a strong password from Coolify secrets).

```text
DATABASE_URL=postgresql://wishlist_api:YOUR_PASSWORD@DB_HOST:5432/postgres
```

If Coolify Supabase exposes Supavisor pooler, use the pooler host/port it documents (often `6543` for transaction mode).

## Coolify

1. Deploy Supabase (Postgres) on Coolify.
2. Run `sql/001_init.sql` against the DB (Supabase SQL editor or `psql`).
3. New **Application** → this `api/` folder, Dockerfile build.
4. Env vars:
   - `DATABASE_URL` → `wishlist_api` connection string (internal Docker network hostname if API and DB are on same Coolify host).
   - `API_KEY` → long random string; iOS sends `X-API-Key` header.
   - `PORT` → `8787` (or what Coolify maps).
   - `PGSSL=true` only if your Postgres requires SSL from the API container.

## Local

```bash
cd api
cp .env.example .env
npm install
npm run dev
```

## Endpoints

- `GET /health` — no auth
- `GET /v1/products?limit=20&offset=0` — requires `X-API-Key`
- `GET /v1/products/:id` — requires `X-API-Key`

Response shape matches the app’s product fields (`heroImageUrl`, `isGiftPick`, tags as JSON, etc.).

## iOS

Store only:

- API base URL (e.g. `https://api.yourdomain.com`)
- `API_KEY` (prefer build config / obfuscation; rotate if leaked)

Never ship `DATABASE_URL` or `postgres` / `service_role` credentials in the app.
