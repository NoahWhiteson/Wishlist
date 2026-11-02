# Coolify deploy (Wishlist API)

## Required Git settings

Use **exactly one** of these pairs. Mixing them breaks `COPY` paths.

### Option A — monorepo root (recommended)

| Setting | Value |
|---------|--------|
| Base Directory | `/` or empty |
| Dockerfile | `/Dockerfile` |
| Build Pack | **Dockerfile** (not Nixpacks) |

### Option B — API folder only

| Setting | Value |
|---------|--------|
| Base Directory | `/api` |
| Dockerfile | `/api/Dockerfile` |
| Build Pack | **Dockerfile** |

Do **not** set Base Directory to `/api` while pointing Dockerfile to `/Dockerfile` (root). That copies `api/package.json` from a context that has no `api/` prefix and the build fails.

## Environment variables

| Key | Example |
|-----|---------|
| `DATABASE_URL` | `postgresql://wishlist_api:PASSWORD@supabase-db:5432/postgres` |
| `API_KEY` | long random string |
| `PORT` | `8787` |

## After deploy

`GET https://your-domain/health` → `{"ok":true}`
