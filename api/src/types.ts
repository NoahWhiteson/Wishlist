import { z } from "zod";

export const productTagSchema = z.object({
  label: z.string(),
  systemImage: z.string(),
  emphasized: z.boolean().optional().default(false),
});

export const productSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  brand: z.string(),
  descriptor: z.string(),
  price: z.string(),
  isGiftPick: z.boolean(),
  heroImageUrl: z.string().url(),
  galleryImageUrls: z.array(z.string().url()),
  quickTags: z.array(productTagSchema),
  about: z.string(),
  highlights: z.array(z.string()),
  detailTags: z.array(productTagSchema),
});

export type ProductDTO = z.infer<typeof productSchema>;

export type ProductRow = {
  id: string;
  title: string;
  brand: string;
  descriptor: string;
  price: string;
  is_gift_pick: boolean;
  hero_image_url: string;
  gallery_image_urls: unknown;
  quick_tags: unknown;
  about: string;
  highlights: unknown;
  detail_tags: unknown;
};
