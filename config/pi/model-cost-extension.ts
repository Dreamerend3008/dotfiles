import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

type PriceInfo = {
  inputUsdPer1M: number;
  cachedInputUsdPer1M: number;
  outputUsdPer1M: number;
  reasoningUsdPer1M?: number;
};

type Totals = {
  inputTokens: number;
  outputTokens: number;
  reasoningTokens: number;
};

const ModelCostParams = Type.Object({});

const STATIC_PRICING: Record<string, PriceInfo> = {
  "gpt-5.4": { inputUsdPer1M: 2.5, cachedInputUsdPer1M: 0.25, outputUsdPer1M: 15 },
  "gpt-5.4-mini": { inputUsdPer1M: 0.75, cachedInputUsdPer1M: 0.08, outputUsdPer1M: 4.5 },
};

const totalsByModel: Record<string, Totals> = {};

function getPrice(modelId: string): PriceInfo {
  return STATIC_PRICING[modelId] ?? STATIC_PRICING["gpt-5.4-mini"];
}

function getTotals(modelId: string): Totals {
  totalsByModel[modelId] ??= { inputTokens: 0, outputTokens: 0, reasoningTokens: 0 };
  return totalsByModel[modelId];
}

function modelName(ctx: any, modelId: string): string {
  const models = ctx.modelRegistry?.getModels?.() ?? [];
  const found = models.find((m: any) => m?.id === modelId);
  return found?.name ?? modelId;
}

function formatCost(modelId: string, ctx: any): string {
  const price = getPrice(modelId);
  const totals = getTotals(modelId);

  const inputCost = (totals.inputTokens / 1_000_000) * price.inputUsdPer1M;
  const cachedCost = (totals.inputTokens / 1_000_000) * price.cachedInputUsdPer1M;
  const outputCost = (totals.outputTokens / 1_000_000) * price.outputUsdPer1M;
  const reasoningCost = (totals.reasoningTokens / 1_000_000) * (price.reasoningUsdPer1M ?? 0);
  const total = inputCost + cachedCost + outputCost + reasoningCost;

  return `${modelName(ctx, modelId)}: $${total.toFixed(6)}`;
}

export default function modelCostExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setStatus("cost", undefined);
  });

  pi.on("turn_end", (event, ctx) => {
    const modelId = (ctx as any).model?.id ?? (ctx as any).modelRegistry?.getDefaultModel?.()?.id ?? "gpt-5.4-mini";
    const usage = (event as any).message?.usage ?? (event as any).usage;
    if (!usage) return;

    const totals = getTotals(modelId);
    totals.inputTokens += usage.inputTokens ?? usage.promptTokens ?? 0;
    totals.outputTokens += usage.outputTokens ?? usage.completionTokens ?? 0;
    totals.reasoningTokens += usage.reasoningTokens ?? 0;

    ctx.ui.setStatus("cost", formatCost(modelId, ctx));
  });

  pi.registerTool({
    name: "model_cost",
    label: "Model Cost",
    description: "Show accumulated model cost for the current session.",
    promptSnippet: "Show the live accumulated model cost for the active session.",
    promptGuidelines: ["Use model_cost when the user asks about current spend or accumulated session cost."],
    parameters: ModelCostParams,
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      const modelId = (ctx as any).model?.id ?? (ctx as any).modelRegistry?.getDefaultModel?.()?.id ?? "gpt-5.4-mini";
      return {
        content: [{ type: "text", text: formatCost(modelId, ctx) }],
        details: { modelId, totals: getTotals(modelId), pricing: getPrice(modelId) },
      };
    },
  });
}
