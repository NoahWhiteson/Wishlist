import "dotenv/config";
import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { getPool } from "./db.js";
import { productsRoute } from "./routes/products.js";

const app = new Hono();

app.use(
  "*",
  cors({
    origin: "*",
    allowHeaders: ["Authorization", "Content-Type", "X-API-Key"],
  }),
);

app.use("/v1/*", async (c, next) => {
  const expected = process.env.API_KEY;
  if (!expected) {
    return c.json({ error: "API_KEY is not configured on server" }, 500);
  }

  const provided = c.req.header("X-API-Key");
  if (provided !== expected) {
    return c.json({ error: "Unauthorized" }, 401);
  }

  await next();
});

app.get("/health", async (c) => {
  try {
    await getPool().query("SELECT 1");
    return c.json({ ok: true });
  } catch {
    return c.json({ ok: false }, 503);
  }
});

app.route("/v1/products", productsRoute);

const port = Number(process.env.PORT ?? 8787);

serve({ fetch: app.fetch, port }, () => {
  console.log(`wishlist-api listening on :${port}`);
});
