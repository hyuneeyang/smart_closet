// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type RawTrendSignal = {
  keyword: string;
  score: number;
  source: string;
  region?: string;
  date?: string;
  season_hint?: string | null;
};

type TrendProvider = {
  name: string;
  fetchSignals: (input: {
    region: string;
    keywords: string[];
  }) => Promise<RawTrendSignal[]>;
};

const KEYWORDS = [
  "minimal",
  "casual",
  "street",
  "athleisure",
  "sporty",
  "formal",
  "classic",
  "oldmoney",
  "gorp",
  "cleanfit",
];

function todayKstIsoDate() {
  const now = new Date();
  const kstMillis = now.getTime() + 9 * 60 * 60 * 1000;
  return new Date(kstMillis).toISOString().slice(0, 10);
}

function normalizeScore(score: number) {
  if (!Number.isFinite(score)) return 0;
  if (score <= 0) return 0;
  if (score <= 1) return Number(score.toFixed(2));
  return Number((Math.min(score, 100) / 100).toFixed(2));
}

function dedupeLatest(signals: RawTrendSignal[]) {
  const latest = new Map<string, RawTrendSignal>();
  for (const signal of signals) {
    if (!signal.keyword || latest.has(signal.keyword)) continue;
    latest.set(signal.keyword, signal);
  }
  return [...latest.values()];
}

function buildInternalDictionaryProvider(): TrendProvider {
  const defaults: Record<string, number> = {
    minimal: 0.84,
    classic: 0.82,
    cleanfit: 0.8,
    casual: 0.74,
    sporty: 0.61,
    athleisure: 0.58,
    gorp: 0.56,
    street: 0.52,
    oldmoney: 0.49,
    formal: 0.43,
  };

  return {
    name: "internal_dictionary",
    async fetchSignals({ region, keywords }) {
      return keywords.map((keyword) => ({
        keyword,
        region,
        source: "internal_dictionary",
        score: defaults[keyword] ?? 0.35,
        date: todayKstIsoDate(),
        season_hint: "all",
      }));
    },
  };
}

function buildJsonEndpointProvider(args: {
  name: string;
  endpointEnv: string;
  tokenEnv?: string;
  scoreField?: string;
}): TrendProvider | null {
  const endpoint = Deno.env.get(args.endpointEnv);
  if (!endpoint) return null;

  return {
    name: args.name,
    async fetchSignals({ region, keywords }) {
      const token = args.tokenEnv ? Deno.env.get(args.tokenEnv) : null;
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          ...(token ? { authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({ region, keywords }),
      });

      if (!response.ok) {
        throw new Error(`${args.name} failed with ${response.status}`);
      }

      const json = await response.json() as { data?: any[] };
      const rows = json.data ?? [];
      return rows.map((row) => ({
        keyword: String(row.keyword ?? ""),
        region: String(row.region ?? region),
        source: String(row.source ?? args.name),
        score: Number(row[args.scoreField ?? "score"] ?? 0),
        date: row.date ? String(row.date) : todayKstIsoDate(),
        season_hint: row.season_hint ? String(row.season_hint) : null,
      }));
    },
  };
}

async function collectSignals(region: string) {
  const providers = [
    buildJsonEndpointProvider({
      name: "google_trends",
      endpointEnv: "GOOGLE_TRENDS_ENDPOINT",
      tokenEnv: "GOOGLE_TRENDS_TOKEN",
    }),
    buildJsonEndpointProvider({
      name: "pinterest_trends",
      endpointEnv: "PINTEREST_TRENDS_ENDPOINT",
      tokenEnv: "PINTEREST_TRENDS_TOKEN",
    }),
    buildJsonEndpointProvider({
      name: "tiktok_trends",
      endpointEnv: "TIKTOK_TRENDS_ENDPOINT",
      tokenEnv: "TIKTOK_TRENDS_TOKEN",
    }),
    buildInternalDictionaryProvider(),
  ].filter(Boolean) as TrendProvider[];

  const collected: RawTrendSignal[] = [];
  const providerErrors: string[] = [];

  for (const provider of providers) {
    try {
      collected.push(
        ...(await provider.fetchSignals({
          region,
          keywords: KEYWORDS,
        })),
      );
    } catch (error) {
      providerErrors.push(`${provider.name}: ${error}`);
    }
  }

  return {
    providerErrors,
    signals: dedupeLatest(
      collected
        .filter((item) => item.keyword && item.score > 0)
        .sort((a, b) => String(b.date ?? "").localeCompare(String(a.date ?? ""))),
    ),
  };
}

function toRows(signals: RawTrendSignal[], region: string) {
  return signals.map((signal) => ({
    keyword: signal.keyword,
    region: signal.region ?? region,
    date: signal.date ?? todayKstIsoDate(),
    score: normalizeScore(signal.score),
    source: signal.source,
    season_hint: signal.season_hint ?? "all",
  }));
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRole) {
    return Response.json(
      { error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" },
      { status: 500 },
    );
  }

  const body = await request.json().catch(() => ({}));
  const region = String(body.region ?? "KR");

  const { signals, providerErrors } = await collectSignals(region);
  const rows = toRows(signals, region);

  const supabase = createClient(supabaseUrl, serviceRole);
  if (rows.isNotEmpty) {
    const { error } = await supabase.from("trend_signals").upsert(rows, {
      onConflict: "keyword,region,date",
      ignoreDuplicates: false,
    });
    if (error) {
      return Response.json({ error: error.message, providerErrors }, { status: 500 });
    }
  }

  return Response.json({
    ok: true,
    region,
    inserted: rows.length,
    providerErrors,
  });
});
