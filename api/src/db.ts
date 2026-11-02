import pg from "pg";
import { prepareDatabaseUrl } from "./pgSsl.js";

const { Pool } = pg;

let pool: pg.Pool | null = null;

export function getPool(): pg.Pool {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error("DATABASE_URL is required");
    }

    const prepared = prepareDatabaseUrl(connectionString);

    pool = new Pool({
      connectionString: prepared.connectionString,
      ssl: prepared.ssl,
      max: 10,
    });
  }

  return pool;
}

export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}
