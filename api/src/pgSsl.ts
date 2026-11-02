export function prepareDatabaseUrl(connectionString: string): {
  connectionString: string;
  ssl: { rejectUnauthorized: boolean } | undefined;
} {
  if (process.env.PGSSL === "false") {
    return { connectionString, ssl: undefined };
  }

  let hadSslMode = false;
  let cleaned = connectionString;

  try {
    const url = new URL(connectionString.replace(/^postgres:\/\//, "postgresql://"));
    hadSslMode = url.searchParams.has("sslmode") || url.searchParams.has("ssl");
    url.searchParams.delete("sslmode");
    url.searchParams.delete("ssl");
    url.searchParams.delete("sslcert");
    url.searchParams.delete("sslkey");
    url.searchParams.delete("sslrootcert");
    url.searchParams.delete("uselibpqcompat");
    cleaned = url.toString().replace(/^postgresql:/, "postgres:");
  } catch {
    /* keep raw string */
  }

  const urlRequestsSsl =
    hadSslMode ||
    /(?:^|[?&])sslmode=(require|verify-full|verify-ca|prefer|no-verify)/i.test(connectionString);

  const useSsl = process.env.PGSSL === "true" || urlRequestsSsl;

  return {
    connectionString: cleaned,
    ssl: useSsl
      ? { rejectUnauthorized: process.env.PGSSL_REJECT_UNAUTHORIZED === "true" }
      : undefined,
  };
}
