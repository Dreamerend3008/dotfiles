import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const MAX_QUERY_LENGTH = 200;
const PRICE_REFRESH_MS = 1000 * 60 * 60 * 24;
const WEB_SEARCH_ENDPOINT = "https://html.duckduckgo.com/html/";

const ModelCostParams = Type.Object({
  useDefaultModel: Type.Optional(Type.Boolean({ default: true })),
});

type PriceInfo = {
  inputUsdPer1M?: number;
  outputUsdPer1M?: number;
  reasoningUsdPer1M?: number;
  context?: string;
  source?: string;
  fetchedAt?: string;
};

type ModelEntry = {
  provider: string;
  modelId: string;
  modelName: string;
  reasoning?: boolean;
};

type CostState = {
  prices: Record<string, PriceInfo>;
  totals: Record<string, { inputTokens: number; outputTokens: number; reasoningTokens: number }>;
};

const state: CostState = { prices: {}, totals: {} };

function clean(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

async function webSearch(query: string, signal: AbortSignal): Promise<string> {
  const body = new URLSearchParams({ q: query, kl: "us-en", kp: "-1" });
  const response = await fetch(WEB_SEARCH_ENDPOINT, {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded",
      "user-agent": "Mozilla/5.0 (compatible; pi-cost/1.0)",
      accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
    body,
    signal,
  });
  if (!response.ok) throw new Error(`Search failed: ${response.status} ${response.statusText}`);
  return await response.text();
}

function parseUsd(value: string): number | undefined {
  const n = Number(value.replace(/[^0-9.]/g, ""));
  return Number.isFinite(n) ? n : undefined;
}

function inferModelEntries(ctx: any): ModelEntry[] {
  const provider = ctx.modelRegistry?.getDefaultProvider?.() ?? "azure-foundry";
  const registryModels = ctx.modelRegistry?.getModels?.() ?? [];
  const entries: ModelEntry[] = [];
  for (const m of registryModels) {
    if (!m?.id) continue;
    entries.push({ provider, modelId: m.id, modelName: m.name ?? m.id, reasoning: !!m.reasoning });
  }
  return entries.length ? entries : [
    { provider, modelId: "gpt-5.4-mini", modelName: "GPT-5.4 Mini", reasoning: false },
    { provider, modelId: "gpt-5.4", modelName: "GPT-5.4", reasoning: true },
  ];
}

async function fetchPriceForModel(model: ModelEntry, signal: AbortSignal): Promise<PriceInfo | undefined> {
  const queries = [
    `${model.modelId} pricing input output per 1m tokens`,
    `${model.modelName} pricing`,
    `${model.provider} ${model.modelId} price tokens`,
  ];

  for (const query of queries) {
    const html = await webSearch(query.slice(0, MAX_QUERY_LENGTH), signal);
    const matches = [...html.matchAll(/\$\s?([0-9]+(?:\.[0-9]+)?)(?:\s*\/\s*1M|\s*per\s*1M|\s*\/\s*million)?[^\n<]{0,120}(input|prompt|cached input|output|completion|reasoning)/gi)];
    const prices: PriceInfo = { source: query, fetchedAt: new Date().toISOString() };
    for (const m of matches) {
      const price = parseUsd(m[1]);
      const label = m[2].toLowerCase();
      if (price == null) continue;
      if (label.includes("reasoning")) prices.reasoningUsdPer1M = price;
      else if (label.includes("output") || label.includes("completion")) prices.outputUsdPer1M = price;
      else prices.inputUsdPer1M = price;
    }
    if (prices.inputUsdPer1M != null || prices.outputUsdPer1M != null || prices.reasoningUsdPer1M != null) return prices;
  }
  return undefined;
}

function formatLiveCost(model: ModelEntry, price: PriceInfo, totals: { inputTokens: number; outputTokens: number; reasoningTokens: number }): string {
  const inputCost = (totals.inputTokens / 1_000_000) * (price.inputUsdPer1M ?? 0);
  const outputCost = (totals.outputTokens / 1_000_000) * (price.outputUsdPer1M ?? 0);
  const reasoningCost = (totals.reasoningTokens / 1_000_000) * (price.reasoningUsdPer1M ?? 0);
  const total = inputCost + outputCost + reasoningCost;
  return [
    `${model.modelName} (${model.modelId})`,
    `  input: ${totals.inputTokens} tokens @ $${price.inputUsdPer1M ?? 0}/1M = $${inputCost.toFixed(6)}`,
    `  output: ${totals.outputTokens} tokens @ $${price.outputUsdPer1M ?? 0}/1M = $${outputCost.toFixed(6)}`,
    price.reasoningUsdPer1M != null ? `  reasoning: ${totals.reasoningTokens} tokens @ $${price.reasoningUsdPer1M}/1M = $${reasoningCost.toFixed(6)}` : `  reasoning: ${totals.reasoningTokens} tokens`,
    `  total: $${total.toFixed(6)}`,
  ].join("\n");
}

export default function modelCostExtension(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const entries = inferModelEntries(ctx);
    for (const model of entries) {
      const cached = state.prices[model.modelId];
      if (!cached || !cached.fetchedAt || Date.now() - Date.parse(cached.fetchedAt) > PRICE_REFRESH_MS) {
        try {
          const price = await fetchPriceForModel(model, ctx.signal ?? new AbortController().signal);
          if (price) state.prices[model.modelId] = price;
        } catch {
          // ignore; keep stale/empty pricing
        }
      }
      state.totals[model.modelId] ??= { inputTokens: 0, outputTokens: 0, reasoningTokens: 0 };
    }
    ctx.ui.notify("Model cost tracking enabled", "info");
  });

  pi.on("turn_end", async (event, ctx) => {
    const modelId = (ctx as any).model?.id ?? (ctx as any).modelRegistry?.getDefaultModel?.()?.id ?? "gpt-5.4-mini";
    const usage = (event as any).message?.usage ?? (event as any).usage;
    if (!usage) return;
    const totals = state.totals[modelId] ??= { inputTokens: 0, outputTokens: 0, reasoningTokens: 0 };
    totals.inputTokens += usage.inputTokens ?? usage.promptTokens ?? 0;
    totals.outputTokens += usage.outputTokens ?? usage.completionTokens ?? 0;
    totals.reasoningTokens += usage.reasoningTokens ?? 0;

    const model = inferModelEntries(ctx).find((m) => m.modelId === modelId) ?? { provider: "azure-foundry", modelId, modelName: modelId };
    const price = state.prices[modelId];
    if (!price) return;
    ctx.ui.setStatus?.(formatLiveCost(model, price, totals));
  });

  pi.registerTool({
    name: "model_cost",
    label: "Model Cost",
    description: "Show live accumulated model cost using current pricing.",
    promptSnippet: "Report live model spend and per-turn cost.",
    promptGuidelines: ["Use model_cost when the user asks about spend, pricing, or live cost tracking for the active model."],
    parameters: ModelCostParams,
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      const entries = inferModelEntries(ctx);
      const lines: string[] = [];
      for (const model of entries) {
        const totals = state.totals[model.modelId] ?? { inputTokens: 0, outputTokens: 0, reasoningTokens: 0 };
        const price = state.prices[model.modelId];
        lines.push(price ? formatLiveCost(model, price, totals) : `${model.modelName} (${model.modelId})\n  pricing not yet loaded`);
      }
      return { content: [{ type: "text", text: lines.join("\n\n") }], details: { prices: state.prices, totals: state.totals } };
    },
  });
}
