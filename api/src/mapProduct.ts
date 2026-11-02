import { productTagSchema, type ProductDTO, type ProductRow } from "./types.js";

function parseTags(value: unknown) {
  const parsed = productTagSchema.array().safeParse(value);
  return parsed.success ? parsed.data : [];
}

function parseStringArray(value: unknown) {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

function parseUrlArray(value: unknown) {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

export function mapProduct(row: ProductRow): ProductDTO {
  return {
    id: row.id,
    title: row.title,
    brand: row.brand,
    descriptor: row.descriptor,
    price: row.price,
    isGiftPick: row.is_gift_pick,
    heroImageUrl: row.hero_image_url,
    galleryImageUrls: parseUrlArray(row.gallery_image_urls),
    quickTags: parseTags(row.quick_tags),
    about: row.about,
    highlights: parseStringArray(row.highlights),
    detailTags: parseTags(row.detail_tags),
  };
}
