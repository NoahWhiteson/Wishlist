import { Hono } from "hono";
import { getPool } from "../db.js";
import { mapProduct } from "../mapProduct.js";
import type { ProductRow } from "../types.js";

export const productsRoute = new Hono();

productsRoute.get("/", async (c) => {
  const limit = Math.min(Number(c.req.query("limit") ?? 20), 50);
  const offset = Math.max(Number(c.req.query("offset") ?? 0), 0);

  const result = await getPool().query<ProductRow>(
    `
      SELECT
        id, title, brand, descriptor, price, is_gift_pick,
        hero_image_url, gallery_image_urls, quick_tags,
        about, highlights, detail_tags
      FROM public.products
      WHERE is_active = true
      ORDER BY sort_order DESC, created_at DESC
      LIMIT $1 OFFSET $2
    `,
    [limit, offset],
  );

  return c.json({
    data: result.rows.map(mapProduct),
    pagination: { limit, offset, count: result.rowCount ?? 0 },
  });
});

productsRoute.get("/:id", async (c) => {
  const id = c.req.param("id");

  const result = await getPool().query<ProductRow>(
    `
      SELECT
        id, title, brand, descriptor, price, is_gift_pick,
        hero_image_url, gallery_image_urls, quick_tags,
        about, highlights, detail_tags
      FROM public.products
      WHERE id = $1 AND is_active = true
      LIMIT 1
    `,
    [id],
  );

  const row = result.rows[0];
  if (!row) {
    return c.json({ error: "Product not found" }, 404);
  }

  return c.json({ data: mapProduct(row) });
});
