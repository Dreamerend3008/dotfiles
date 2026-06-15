import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { Type } from "typebox";

type PriceInfo = {
  inputUsdPer1M: number;
  cachedInputUsdPer1M: number;
  outputUsdPer1M: number;
  cacheWriteUsdPer1M?: number;
  reasoningUsdPer1M?: number;
};

type UsageLike = {
  input?: number;
  output?: number;
  cacheRead?: number;
  cacheWrite?: number;
  inputTokens?: number;
  outputTokens?: number;
  promptTokens?: number;
  completionTokens?: number;
  reasoningTokens?: number;
};

type Totals = {
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheWriteTokens: number;
  reasoningTokens: number;
};

type SessionSummary = {
  allModels: Totals;
  byModel: Record<string, Totals>;
  totalCost: number;
  costByModel: Record<string, number>;
};

const ModelCostParams = Type.Object({});

const STATIC_PRICING: Record<string, PriceInfo> = {
  "gpt-5.4": { inputUsdPer1M: 2.5, cachedInputUsdPer1M: 0.25, outputUsdPer1M: 15 },
  "gpt-5.4-mini": { inputUsdPer1M: 0.75, cachedInputUsdPer1M: 0.08, outputUsdPer1M: 4.5 },
};

function emptyTotals(): Totals {
  return {
    inputTokens: 0,
    outputTokens: 0,
    cacheReadTokens: 0,
    cacheWriteTokens: 0,
    reasoningTokens: 0,
  };
}

function getSettingsFile(): string {
  return process.env.PI_CODING_AGENT_SETTINGS_FILE || join(process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent"), "settings.json");
}

function loadPricingFromSettings(): Record<string, PriceInfo> {
  try {
    const settings = JSON.parse(readFileSync(getSettingsFile(), "utf8")) as {
      modelPricing?: Record<string, PriceInfo>;
    };
    return settings.modelPricing ?? {};
  } catch {
    return {};
  }
}

function getModelRegistryPrice(modelId: string, ctx: any): PriceInfo | undefined {
  const models = ctx.modelRegistry?.getModels?.() ?? [];
  const model = models.find((m: any) => m?.id === modelId);
  const cost = model?.cost;
  if (!cost) return undefined;

  return {
    inputUsdPer1M: cost.input ?? 0,
    cachedInputUsdPer1M: cost.cacheRead ?? 0,
    outputUsdPer1M: cost.output ?? 0,
    cacheWriteUsdPer1M: cost.cacheWrite ?? 0,
  };
}

function getPrice(modelId: string, ctx: any): PriceInfo {
  const settingsPricing = loadPricingFromSettings();
  return settingsPricing[modelId] ?? getModelRegistryPrice(modelId, ctx) ?? STATIC_PRICING[modelId] ?? STATIC_PRICING["gpt-5.4-mini"];
}

function addUsage(totals: Totals, usage: UsageLike | undefined) {
  if (!usage) return;

  totals.inputTokens += usage.input ?? usage.inputTokens ?? usage.promptTokens ?? 0;
  totals.outputTokens += usage.output ?? usage.outputTokens ?? usage.completionTokens ?? 0;
  totals.cacheReadTokens += usage.cacheRead ?? 0;
  totals.cacheWriteTokens += usage.cacheWrite ?? 0;
  totals.reasoningTokens += usage.reasoningTokens ?? 0;
}

function estimateCostFromTotals(modelId: string, totals: Totals, ctx: any): number {
  const price = getPrice(modelId, ctx);

  const inputCost = (totals.inputTokens / 1_000_000) * price.inputUsdPer1M;
  const cacheReadCost = (totals.cacheReadTokens / 1_000_000) * price.cachedInputUsdPer1M;
  const cacheWriteCost = (totals.cacheWriteTokens / 1_000_000) * (price.cacheWriteUsdPer1M ?? 0);
  const outputCost = (totals.outputTokens / 1_000_000) * price.outputUsdPer1M;
  const reasoningCost = (totals.reasoningTokens / 1_000_000) * (price.reasoningUsdPer1M ?? 0);

  return inputCost + cacheReadCost + cacheWriteCost + outputCost + reasoningCost;
}

function fmtInt(value: number): string {
  return new Intl.NumberFormat("en-US").format(Math.round(value));
}

function fmtUsd(value: number): string {
  if (value >= 100) return `$${value.toFixed(2)}`;
  if (value >= 1) return `$${value.toFixed(2)}`;
  if (value >= 0.01) return `$${value.toFixed(4)}`;
  return `$${value.toFixed(6)}`;
}

function modelName(ctx: any, modelId: string): string {
  const models = ctx.modelRegistry?.getModels?.() ?? [];
  const found = models.find((m: any) => m?.id === modelId);
  return found?.name ?? modelId;
}

function buildSessionSummary(ctx: any): SessionSummary {
  const allModels = emptyTotals();
  const byModel: Record<string, Totals> = {};

  for (const entry of ctx.sessionManager?.getEntries?.() ?? []) {
    if (entry?.type !== "message") continue;
    if (entry?.message?.role !== "assistant") continue;

    const usage = entry.message.usage as UsageLike | undefined;
    const totalTokens =
      usage?.input ??
      usage?.inputTokens ??
      usage?.promptTokens ??
      usage?.output ??
      usage?.outputTokens ??
      usage?.completionTokens ??
      usage?.cacheRead ??
      usage?.cacheWrite ??
      usage?.reasoningTokens ??
      0;
    if (totalTokens <= 0) continue;

    const modelId = String(entry.message.model ?? "unknown-model");
    byModel[modelId] ??= emptyTotals();

    addUsage(allModels, usage);
    addUsage(byModel[modelId], usage);
  }

  const costByModel: Record<string, number> = {};
  let totalCost = 0;
  for (const [modelId, totals] of Object.entries(byModel)) {
    const cost = estimateCostFromTotals(modelId, totals, ctx);
    costByModel[modelId] = cost;
    totalCost += cost;
  }

  return { allModels, byModel, totalCost, costByModel };
}

function formatStatus(ctx: any): string {
  const summary = buildSessionSummary(ctx);
  return `spent ${fmtUsd(summary.totalCost)}`;
}

function formatReport(ctx: any): string {
  const summary = buildSessionSummary(ctx);
  const lines = [
    "Current session cost",
    `All models: ${fmtInt(summary.allModels.inputTokens + summary.allModels.outputTokens + summary.allModels.cacheReadTokens + summary.allModels.cacheWriteTokens)} total (${fmtInt(summary.allModels.inputTokens)} in, ${fmtInt(summary.allModels.outputTokens)} out, ${fmtInt(summary.allModels.cacheReadTokens)} cache read, ${fmtInt(summary.allModels.cacheWriteTokens)} cache write) · ${fmtUsd(summary.totalCost)}`,
  ];

  const models = Object.entries(summary.byModel).sort((a, b) => (summary.costByModel[b[0]] ?? 0) - (summary.costByModel[a[0]] ?? 0));
  if (models.length > 0) {
    lines.push("", "By model");
    for (const [modelId, totals] of models) {
      lines.push(
        `${modelName(ctx, modelId)}: ${fmtInt(totals.inputTokens + totals.outputTokens + totals.cacheReadTokens + totals.cacheWriteTokens)} total (${fmtInt(totals.inputTokens)} in, ${fmtInt(totals.outputTokens)} out, ${fmtInt(totals.cacheReadTokens)} cache read, ${fmtInt(totals.cacheWriteTokens)} cache write) · ${fmtUsd(summary.costByModel[modelId] ?? 0)}`,
      );
    }
  }

  return lines.join("\n");
}

function refreshStatus(ctx: any) {
  ctx.ui.setStatus("cost", formatStatus(ctx));
}

export default function modelCostExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    refreshStatus(ctx);
  });

  pi.on("turn_end", (_event, ctx) => {
    refreshStatus(ctx);
  });

  pi.registerTool({
    name: "model_cost",
    label: "Model Cost",
    description: "Show accumulated model cost for the current session across all models.",
    promptSnippet: "Show the live accumulated model cost for the active session.",
    promptGuidelines: ["Use model_cost when the user asks about current spend or accumulated session cost."],
    parameters: ModelCostParams,
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      const summary = buildSessionSummary(ctx);
      return {
        content: [{ type: "text", text: formatReport(ctx) }],
        details: summary,
      };
    },
  });
}
