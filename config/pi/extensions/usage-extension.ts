import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

type PriceInfo = {
  inputUsdPer1M: number;
  cachedInputUsdPer1M: number;
  outputUsdPer1M: number;
  cacheWriteUsdPer1M?: number;
  reasoningUsdPer1M?: number;
};

type SettingsData = {
  modelPricing?: Record<string, PriceInfo>;
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
  cost?: {
    total?: number;
  };
};

type Totals = {
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheWriteTokens: number;
  reasoningTokens: number;
};

type MonthSpec = {
  year: number;
  month: number;
  label: string;
};

type MonthlySummary = {
  label: string;
  totals: Totals;
  totalCost: number;
  sessionFilesScanned: number;
  assistantMessages: number;
  byModel: Record<string, Totals>;
  costByModel: Record<string, number>;
};

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

function getAgentDir(): string {
  return process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
}

function getSessionsDir(): string {
  return process.env.PI_CODING_AGENT_SESSION_DIR || join(getAgentDir(), "sessions");
}

function getSettingsFile(): string {
  return process.env.PI_CODING_AGENT_SETTINGS_FILE || join(getAgentDir(), "settings.json");
}

function loadSettingsData(): SettingsData {
  try {
    return JSON.parse(readFileSync(getSettingsFile(), "utf8")) as SettingsData;
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
    reasoningUsdPer1M: cost.reasoning ?? 0,
  };
}

function resolvePrice(modelId: string, ctx: any, settingsPricing: Record<string, PriceInfo>): PriceInfo {
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

function estimateCostFromTotals(modelId: string, totals: Totals, ctx: any, settingsPricing: Record<string, PriceInfo>): number {
  const price = resolvePrice(modelId, ctx, settingsPricing);
  const inputCost = (totals.inputTokens / 1_000_000) * price.inputUsdPer1M;
  const cacheReadCost = (totals.cacheReadTokens / 1_000_000) * price.cachedInputUsdPer1M;
  const cacheWriteCost = (totals.cacheWriteTokens / 1_000_000) * (price.cacheWriteUsdPer1M ?? 0);
  const outputCost = (totals.outputTokens / 1_000_000) * price.outputUsdPer1M;
  const reasoningCost = (totals.reasoningTokens / 1_000_000) * (price.reasoningUsdPer1M ?? 0);
  return inputCost + cacheReadCost + cacheWriteCost + outputCost + reasoningCost;
}

function estimateCostFromUsage(modelId: string, usage: UsageLike | undefined, ctx: any, settingsPricing: Record<string, PriceInfo>): number {
  if (!usage) return 0;
  const storedTotal = usage.cost?.total;
  if (typeof storedTotal === "number" && Number.isFinite(storedTotal)) return storedTotal;
  const totals = emptyTotals();
  addUsage(totals, usage);
  return estimateCostFromTotals(modelId, totals, ctx, settingsPricing);
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

function currentMonth(): MonthSpec {
  const now = new Date();
  return {
    year: now.getFullYear(),
    month: now.getMonth(),
    label: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`,
  };
}

function parseMonthArg(arg: string): MonthSpec | null {
  const trimmed = arg.trim();
  if (!trimmed) return currentMonth();

  const match = trimmed.match(/^(\d{4})-(\d{2})$/);
  if (!match) return null;

  const year = Number(match[1]);
  const monthOneBased = Number(match[2]);
  if (!Number.isInteger(year) || !Number.isInteger(monthOneBased) || monthOneBased < 1 || monthOneBased > 12) {
    return null;
  }

  return {
    year,
    month: monthOneBased - 1,
    label: `${year}-${String(monthOneBased).padStart(2, "0")}`,
  };
}

function isSameMonth(timestamp: unknown, spec: MonthSpec): boolean {
  if (typeof timestamp !== "string" && typeof timestamp !== "number") return false;
  const date = new Date(timestamp);
  if (Number.isNaN(date.getTime())) return false;
  return date.getFullYear() === spec.year && date.getMonth() === spec.month;
}

function walkSessionFiles(dir: string): string[] {
  if (!existsSync(dir)) return [];
  return (readdirSync(dir, { recursive: true }) as unknown as string[])
    .filter((name) => name.endsWith(".jsonl"))
    .map((name) => join(dir, name));
}

function collectMonthlySummary(ctx: any, spec: MonthSpec, settingsPricing: Record<string, PriceInfo>): MonthlySummary {
  const totals = emptyTotals();
  const byModel: Record<string, Totals> = {};
  const costByModel: Record<string, number> = {};
  const seenMessages = new Set<string>();
  const sessionFiles = walkSessionFiles(getSessionsDir());
  let totalCost = 0;
  let assistantMessages = 0;

  for (const sessionFile of sessionFiles) {
    const content = readFileSync(sessionFile, "utf8");
    for (const line of content.split("\n")) {
      if (!line.trim()) continue;

      let entry: any;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }

      // Support both current v3 session rows ({ type: "message", message: ... })
      // and older/direct message rows where role/usage/model live at the top level.
      const message = entry?.type === "message" ? entry?.message : entry;
      const timestamp = entry?.timestamp ?? message?.timestamp;
      if (message?.role !== "assistant") continue;
      if (!isSameMonth(timestamp, spec)) continue;

      const messageKey = String(entry?.id ?? message?.responseId ?? line.trim());
      if (seenMessages.has(messageKey)) continue;

      const usage = message.usage as UsageLike | undefined;
      const usageTotals = emptyTotals();
      addUsage(usageTotals, usage);
      const totalTokens =
        usageTotals.inputTokens +
        usageTotals.outputTokens +
        usageTotals.cacheReadTokens +
        usageTotals.cacheWriteTokens +
        usageTotals.reasoningTokens;
      if (totalTokens <= 0) continue;

      seenMessages.add(messageKey);
      assistantMessages += 1;
      addUsage(totals, usage);

      const modelId = String(message.model ?? "unknown-model");
      byModel[modelId] ??= emptyTotals();
      addUsage(byModel[modelId], usage);

      const cost = estimateCostFromUsage(modelId, usage, ctx, settingsPricing);
      costByModel[modelId] = (costByModel[modelId] ?? 0) + cost;
      totalCost += cost;
    }
  }

  return {
    label: spec.label,
    totals,
    totalCost,
    sessionFilesScanned: sessionFiles.length,
    assistantMessages,
    byModel,
    costByModel,
  };
}

function formatMonthlyReport(ctx: any, summary: MonthlySummary): string {
  const allTotals = summary.totals;
  const totalTokens = allTotals.inputTokens + allTotals.outputTokens + allTotals.cacheReadTokens + allTotals.cacheWriteTokens;
  const lines = [
    `Pi usage for ${summary.label}`,
    `Unique assistant turns: ${fmtInt(summary.assistantMessages)}`,
    `Session files scanned: ${fmtInt(summary.sessionFilesScanned)}`,
    `Session root: ${getSessionsDir()}`,
    "",
    "Totals",
    `All models: ${fmtInt(totalTokens)} total (${fmtInt(allTotals.inputTokens)} in, ${fmtInt(allTotals.outputTokens)} out, ${fmtInt(allTotals.cacheReadTokens)} cache read, ${fmtInt(allTotals.cacheWriteTokens)} cache write) · ${fmtUsd(summary.totalCost)}`,
  ];

  const models = Object.entries(summary.byModel).sort((a, b) => (summary.costByModel[b[0]] ?? 0) - (summary.costByModel[a[0]] ?? 0));
  if (models.length > 0) {
    lines.push("", "By model");
    for (const [modelId, totals] of models) {
      const modelTokens = totals.inputTokens + totals.outputTokens + totals.cacheReadTokens + totals.cacheWriteTokens;
      lines.push(
        `${modelName(ctx, modelId)}: ${fmtInt(modelTokens)} total (${fmtInt(totals.inputTokens)} in, ${fmtInt(totals.outputTokens)} out, ${fmtInt(totals.cacheReadTokens)} cache read, ${fmtInt(totals.cacheWriteTokens)} cache write) · ${fmtUsd(summary.costByModel[modelId] ?? 0)}`,
      );
    }
  }

  return lines.join("\n");
}

function refreshMonthlyCostStatus(ctx: any) {
  const settings = loadSettingsData();
  const summary = collectMonthlySummary(ctx, currentMonth(), settings.modelPricing ?? {});
  ctx.ui.setStatus("cost", fmtUsd(summary.totalCost));
}

export default function usageExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    refreshMonthlyCostStatus(ctx);
  });

  pi.on("turn_end", (_event, ctx) => {
    refreshMonthlyCostStatus(ctx);
  });

  pi.registerCommand("usage", {
    description: "Show monthly token usage and estimated cost across all Pi sessions",
    handler: async (args, ctx) => {
      const month = parseMonthArg(args);
      if (!month) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /usage [YYYY-MM]", "warning");
        else console.log("Usage: /usage [YYYY-MM]");
        return;
      }

      if (!ctx.isIdle()) {
        await ctx.waitForIdle();
      }

      const settings = loadSettingsData();
      const summary = collectMonthlySummary(ctx, month, settings.modelPricing ?? {});
      const report = formatMonthlyReport(ctx, summary);

      if (!ctx.hasUI) {
        console.log(report);
        return;
      }

      pi.sendMessage({
        customType: "usage-report",
        content: report,
        display: true,
        details: summary,
      });
    },
  });
}
