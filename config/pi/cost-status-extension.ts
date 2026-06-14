import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Pricing = {
  inputUsdPer1M: number;
  cachedInputUsdPer1M: number;
  outputUsdPer1M: number;
};

const PRICING: Record<string, Pricing> = {
  "gpt-5.4": { inputUsdPer1M: 2.5, cachedInputUsdPer1M: 0.25, outputUsdPer1M: 15 },
  "gpt-5.4-mini": { inputUsdPer1M: 0.75, cachedInputUsdPer1M: 0.08, outputUsdPer1M: 4.5 },
};

function getModelId(ctx: any): string {
  return ctx.model?.id ?? ctx.modelRegistry?.getDefaultModel?.()?.id ?? "gpt-5.4-mini";
}

function getUsage(source: any) {
  return source?.usage ?? source?.message?.usage ?? source?.details?.usage;
}

function formatCost(modelId: string, usage: any): string {
  const p = PRICING[modelId];
  if (!p || !usage) return "cost: unavailable";
  const inputTokens = usage.inputTokens ?? usage.promptTokens ?? 0;
  const cachedInputTokens = usage.cachedInputTokens ?? usage.cacheReadTokens ?? 0;
  const outputTokens = usage.outputTokens ?? usage.completionTokens ?? 0;

  const inputCost = (inputTokens / 1_000_000) * p.inputUsdPer1M;
  const cachedCost = (cachedInputTokens / 1_000_000) * p.cachedInputUsdPer1M;
  const outputCost = (outputTokens / 1_000_000) * p.outputUsdPer1M;
  const total = inputCost + cachedCost + outputCost;

  return `${modelId}: $${total.toFixed(6)} total  (in $${inputCost.toFixed(6)} | cached $${cachedCost.toFixed(6)} | out $${outputCost.toFixed(6)})`;
}

export default function costStatusExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    const modelId = getModelId(ctx);
    ctx.ui.setStatus("cost", `${modelId}: cost tracking ready`);
  });

  pi.on("turn_end", (event, ctx) => {
    const modelId = getModelId(ctx);
    const usage = getUsage(event);
    if (!usage) return;
    ctx.ui.setStatus("cost", formatCost(modelId, usage));
  });

  pi.on("model_select", (_event, ctx) => {
    const modelId = getModelId(ctx);
    ctx.ui.setStatus("cost", `${modelId}: selected`);
  });
}
