import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const ModelCostParams = Type.Object({
  useDefaultModel: Type.Optional(Type.Boolean({ default: true })),
});

const STATIC_PRICING: Record<string, { inputUsdPer1M: number; cachedInputUsdPer1M: number; outputUsdPer1M: number }> = {
  "gpt-5.4": { inputUsdPer1M: 2.5, cachedInputUsdPer1M: 0.25, outputUsdPer1M: 15 },
  "gpt-5.4-mini": { inputUsdPer1M: 0.75, cachedInputUsdPer1M: 0.08, outputUsdPer1M: 4.5 },
};

type PriceInfo = {
  inputUsdPer1M: number;
  cachedInputUsdPer1M: number;
  outputUsdPer1M: number;
  reasoningUsdPer1M?: number;
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

function inferModelEntries(ctx: any): ModelEntry[] {
  const provider = ctx.modelRegistry?.getDefaultProvider?.() ?? "azure-foundry";
  const registryModels = ctx.modelRegistry?.getModels?.() ?? [];
  const entries: ModelEntry[] = [];
  for (const m of registryModels) {
    if (!m?.id) continue;
    entries.push({ provider, modelId: m.id, modelName: m.name ?? m.id, reasoning: !!m.reasoning });
  }
  return entries.length ? entries : Object.keys(STATIC_PRICING).map((modelId) => ({
    provider,
    modelId,
    modelName: modelId,
    reasoning: modelId === "gpt-5.4",
  }));
}

function formatLiveCost(model: ModelEntry, price: PriceInfo, totals: { inputTokens: number; outputTokens: number; reasoningTokens: number }): string {
  const inputCost = (totals.inputTokens / 1_000_000) * price.inputUsdPer1M;
  const cachedCost = (totals.inputTokens / 1_000_000) * price.cachedInputUsdPer1M;
  const outputCost = (totals.outputTokens / 1_000_000) * price.outputUsdPer1M;
  const reasoningCost = (totals.reasoningTokens / 1_000_000) * (price.reasoningUsdPer1M ?? 0);
  const total = inputCost + cachedCost + outputCost + reasoningCost;
  return `${model.modelName} (${model.modelId}): $${total.toFixed(6)} total (in $${inputCost.toFixed(6)} | cached $${cachedCost.toFixed(6)} | out $${outputCost.toFixed(6)}${price.reasoningUsdPer1M != null ? ` | reasoning $${reasoningCost.toFixed(6)}` : ""})`;
}

export default function modelCostExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    const entries = inferModelEntries(ctx);
    for (const model of entries) {
      state.prices[model.modelId] = STATIC_PRICING[model.modelId] ?? STATIC_PRICING["gpt-5.4-mini"];
      state.totals[model.modelId] ??= { inputTokens: 0, outputTokens: 0, reasoningTokens: 0 };
    }
    ctx.ui.setStatus("cost", undefined);
  });

  pi.on("turn_end", (event, ctx) => {
    const modelId = (ctx as any).model?.id ?? (ctx as any).modelRegistry?.getDefaultModel?.()?.id ?? "gpt-5.4-mini";
    const usage = (event as any).message?.usage ?? (event as any).usage;
    if (!usage) return;
    const totals = state.totals[modelId] ??= { inputTokens: 0, outputTokens: 0, reasoningTokens: 0 };
    totals.inputTokens += usage.inputTokens ?? usage.promptTokens ?? 0;
    totals.outputTokens += usage.outputTokens ?? usage.completionTokens ?? 0;
    totals.reasoningTokens += usage.reasoningTokens ?? 0;

    const model = inferModelEntries(ctx).find((m) => m.modelId === modelId) ?? { provider: "azure-foundry", modelId, modelName: modelId };
    const price = state.prices[modelId] ?? STATIC_PRICING[modelId] ?? STATIC_PRICING["gpt-5.4-mini"];
    ctx.ui.setStatus("cost", formatLiveCost(model, price, totals));
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
        const price = state.prices[model.modelId] ?? STATIC_PRICING[model.modelId] ?? STATIC_PRICING["gpt-5.4-mini"];
        lines.push(formatLiveCost(model, price, totals));
      }
      return { content: [{ type: "text", text: lines.join("\n\n") }], details: { prices: state.prices, totals: state.totals } };
    },
  });
}
