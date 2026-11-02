# Coolify deploy (Wishlist API)

## Required Git settings

| Setting | Value |
|---------|--------|
| Build Pack | **Dockerfile** (not Nixpacks) |
| Base Directory | `/` (repo root) |
| Dockerfile | `/api/Dockerfile` or `/Dockerfile` |

Coolify clones the **whole repo** and uses that as the Docker build context. Both Dockerfiles expect paths under `api/`.

## Environment variables

| Key | Example |
|-----|---------|
| `DATABASE_URL` | `postgresql://wishlist_api:PASSWORD@supabase-db:5432/postgres` |
| `API_KEY` | long random string |
| `PORT` | `8787` |

## After deploy

`GET https://your-domain/health` → `{"ok":true}`
