# Coolify deploy (Wishlist API)

## Required Git settings

| Setting | Value |
|---------|--------|
| Build Pack | **Dockerfile** (not Nixpacks) |
| Dockerfile | `/Dockerfile` |

**Base directory** can be `/` or `/api` — root `Dockerfile` auto-detects both layouts.

Optional: base `/api` + `/api/Dockerfile` also works.

## Environment variables

| Key | Example |
|-----|---------|
| `DATABASE_URL` | `postgresql://wishlist_api:PASSWORD@supabase-db:5432/postgres` |
| `API_KEY` | long random string |
| `PORT` | `8787` |

## After deploy

`GET https://your-domain/health` → `{"ok":true}`
