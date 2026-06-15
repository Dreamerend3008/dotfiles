import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, readFileSync, readdirSync } from "node:fs";
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

type BudgetRule = {
  warnUsd?: number;
  limitUsd?: number;
};

type BudgetConfig = {
  session?: BudgetRule;
  monthly?: BudgetRule;
};

type SettingsData = {
  modelPricing?: Record<string, PriceInfo>;
  budgetLimits?: BudgetConfig;
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

type SessionSummary = {
  allModels: Totals;
  byModel: Record<string, Totals>;
  totalCost: number;
  costByModel: Record<string, number>;
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
};

type BudgetLevel = "ok" | "warn" | "limit";

const ModelCostParams = Type.Object({});

const STATIC_PRICING: Record<string, PriceInfo> = {
  "gpt-5.4": { inputUsdPer1M: 2.5, cachedInputUsdPer1M: 0.25, outputUsdPer1M: 15 },
  "gpt-5.4-mini": { inputUsdPer1M: 0.75, cachedInputUsdPer1M: 0.08, outputUsdPer1M: 4.5 },
};

let sessionBudgetNoticeLevel: BudgetLevel = "ok";
let monthlyBudgetNoticeLevel: BudgetLevel = "ok";
let monthlyBudgetNoticeLabel = "";

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
  };
}

function getPrice(modelId: string, ctx: any, settingsPricing: Record<string, PriceInfo>): PriceInfo {
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
  const price = getPrice(modelId, ctx, settingsPricing);

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
  if (typeof storedTotal === "number" && Number.isFinite(storedTotal) && storedTotal >= 0) {
    return storedTotal;
  }

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

function buildSessionSummary(ctx: any, settingsPricing: Record<string, PriceInfo>): SessionSummary {
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
    const cost = estimateCostFromTotals(modelId, totals, ctx, settingsPricing);
    costByModel[modelId] = cost;
    totalCost += cost;
  }

  return { allModels, byModel, totalCost, costByModel };
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
  const monthNumber = Number(match[2]);
  if (monthNumber < 1 || monthNumber > 12) return null;

  return {
    year,
    month: monthNumber - 1,
    label: `${match[1]}-${match[2]}`,
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

  const files: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walkSessionFiles(fullPath));
      continue;
    }
    if (entry.isFile() && entry.name.endsWith(".jsonl")) {
      files.push(fullPath);
    }
  }
  return files;
}

function collectMonthlySummary(ctx: any, spec: MonthSpec, settingsPricing: Record<string, PriceInfo>): MonthlySummary {
  const totals = emptyTotals();
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

      if (entry?.type !== "message") continue;
      if (entry?.message?.role !== "assistant") continue;
      if (!isSameMonth(entry.timestamp, spec)) continue;

      const messageKey = line.trim();
      if (seenMessages.has(messageKey)) continue;

      const usage = entry.message.usage as UsageLike | undefined;
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

      const modelId = String(entry.message.model ?? "unknown-model");
      totalCost += estimateCostFromUsage(modelId, usage, ctx, settingsPricing);
    }
  }

  return {
    label: spec.label,
    totals,
    totalCost,
    sessionFilesScanned: sessionFiles.length,
    assistantMessages,
  };
}

function getBudgetLevel(cost: number, rule: BudgetRule | undefined): BudgetLevel {
  if (!rule) return "ok";
  if (typeof rule.limitUsd === "number" && cost >= rule.limitUsd) return "limit";
  if (typeof rule.warnUsd === "number" && cost >= rule.warnUsd) return "warn";
  return "ok";
}

function levelRank(level: BudgetLevel): number {
  return level === "limit" ? 2 : level === "warn" ? 1 : 0;
}

function formatBudgetRule(rule: BudgetRule | undefined): string {
  if (!rule || (typeof rule.warnUsd !== "number" && typeof rule.limitUsd !== "number")) {
    return "no limits configured";
  }

  const parts: string[] = [];
  if (typeof rule.warnUsd === "number") parts.push(`warn ${fmtUsd(rule.warnUsd)}`);
  if (typeof rule.limitUsd === "number") parts.push(`limit ${fmtUsd(rule.limitUsd)}`);
  return parts.join(" · ");
}

function formatBudgetLine(label: string, cost: number, rule: BudgetRule | undefined): string {
  const level = getBudgetLevel(cost, rule);
  const suffix = level === "limit" ? "LIMIT" : level === "warn" ? "warning" : "ok";
  return `${label}: ${fmtUsd(cost)} (${formatBudgetRule(rule)}) · ${suffix}`;
}

function formatStatus(totalCost: number, level: BudgetLevel): string {
  if (level === "limit") return `spent ${fmtUsd(totalCost)} · limit`;
  if (level === "warn") return `spent ${fmtUsd(totalCost)} · warn`;
  return `spent ${fmtUsd(totalCost)}`;
}

function formatBudgetStatus(sessionCost: number, sessionRule: BudgetRule | undefined, monthly: MonthlySummary, monthlyRule: BudgetRule | undefined): string {
  const sessionPart = `session ${fmtUsd(sessionCost)}${typeof sessionRule?.limitUsd === "number" ? `/${fmtUsd(sessionRule.limitUsd)}` : ""}`;
  const monthPart = `${monthly.label} ${fmtUsd(monthly.totalCost)}${typeof monthlyRule?.limitUsd === "number" ? `/${fmtUsd(monthlyRule.limitUsd)}` : ""}`;
  return `${sessionPart} · ${monthPart}`;
}

function formatReport(ctx: any, settingsPricing: Record<string, PriceInfo>): string {
  const summary = buildSessionSummary(ctx, settingsPricing);
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

function formatBudgetReport(ctx: any, monthSpec: MonthSpec, settingsPricing: Record<string, PriceInfo>, budgetLimits: BudgetConfig): string {
  const sessionSummary = buildSessionSummary(ctx, settingsPricing);
  const monthlySummary = collectMonthlySummary(ctx, monthSpec, settingsPricing);

  return [
    `Budget status for ${monthSpec.label}`,
    formatBudgetLine("Current session", sessionSummary.totalCost, budgetLimits.session),
    formatBudgetLine(`Month ${monthlySummary.label}`, monthlySummary.totalCost, budgetLimits.monthly),
    `Month assistant turns: ${fmtInt(monthlySummary.assistantMessages)}`,
    `Session files scanned: ${fmtInt(monthlySummary.sessionFilesScanned)}`,
    `Session root: ${getSessionsDir()}`,
  ].join("\n");
}

function maybeNotifyBudget(ctx: any, sessionCost: number, sessionRule: BudgetRule | undefined, monthlySummary: MonthlySummary, monthlyRule: BudgetRule | undefined) {
  const sessionLevel = getBudgetLevel(sessionCost, sessionRule);
  if (levelRank(sessionLevel) > levelRank(sessionBudgetNoticeLevel)) {
    ctx.ui.notify(
      sessionLevel === "limit"
        ? `Session budget limit reached: ${fmtUsd(sessionCost)} (${formatBudgetRule(sessionRule)})`
        : `Session budget warning: ${fmtUsd(sessionCost)} (${formatBudgetRule(sessionRule)})`,
      sessionLevel === "limit" ? "error" : "warning",
    );
    sessionBudgetNoticeLevel = sessionLevel;
  }

  const monthlyLevel = getBudgetLevel(monthlySummary.totalCost, monthlyRule);
  if (monthlyBudgetNoticeLabel !== monthlySummary.label) {
    monthlyBudgetNoticeLabel = monthlySummary.label;
    monthlyBudgetNoticeLevel = "ok";
  }
  if (levelRank(monthlyLevel) > levelRank(monthlyBudgetNoticeLevel)) {
    ctx.ui.notify(
      monthlyLevel === "limit"
        ? `Monthly budget limit reached for ${monthlySummary.label}: ${fmtUsd(monthlySummary.totalCost)} (${formatBudgetRule(monthlyRule)})`
        : `Monthly budget warning for ${monthlySummary.label}: ${fmtUsd(monthlySummary.totalCost)} (${formatBudgetRule(monthlyRule)})`,
      monthlyLevel === "limit" ? "error" : "warning",
    );
    monthlyBudgetNoticeLevel = monthlyLevel;
  }
}

function refreshStatus(ctx: any) {
  const settings = loadSettingsData();
  const settingsPricing = settings.modelPricing ?? {};
  const budgetLimits = settings.budgetLimits ?? {};
  const sessionSummary = buildSessionSummary(ctx, settingsPricing);
  const monthlySummary = collectMonthlySummary(ctx, currentMonth(), settingsPricing);

  ctx.ui.setStatus("cost", formatStatus(sessionSummary.totalCost, getBudgetLevel(sessionSummary.totalCost, budgetLimits.session)));

  if (budgetLimits.session || budgetLimits.monthly) {
    ctx.ui.setStatus(
      "budget",
      formatBudgetStatus(sessionSummary.totalCost, budgetLimits.session, monthlySummary, budgetLimits.monthly),
    );
  } else {
    ctx.ui.setStatus("budget", undefined);
  }

  if (ctx.hasUI) {
    maybeNotifyBudget(ctx, sessionSummary.totalCost, budgetLimits.session, monthlySummary, budgetLimits.monthly);
  }
}

export default function modelCostExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    sessionBudgetNoticeLevel = "ok";
    monthlyBudgetNoticeLevel = "ok";
    monthlyBudgetNoticeLabel = currentMonth().label;
    refreshStatus(ctx);
  });

  pi.on("turn_end", (_event, ctx) => {
    refreshStatus(ctx);
  });

  pi.registerCommand("budget", {
    description: "Show current session and monthly budget status (usage: /budget [YYYY-MM])",
    handler: async (args, ctx) => {
      const month = parseMonthArg(args);
      if (!month) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /budget [YYYY-MM]", "warning");
        else console.log("Usage: /budget [YYYY-MM]");
        return;
      }

      if (!ctx.isIdle()) {
        await ctx.waitForIdle();
      }

      const settings = loadSettingsData();
      const report = formatBudgetReport(ctx, month, settings.modelPricing ?? {}, settings.budgetLimits ?? {});
      if (!ctx.hasUI) {
        console.log(report);
        return;
      }

      pi.sendMessage({
        customType: "budget-report",
        content: report,
        display: true,
        details: {
          month: month.label,
          settings: settings.budgetLimits ?? {},
        },
      });
    },
  });

  pi.registerTool({
    name: "model_cost",
    label: "Model Cost",
    description: "Show accumulated model cost for the current session across all models.",
    promptSnippet: "Show the live accumulated model cost for the active session.",
    promptGuidelines: ["Use model_cost when the user asks about current spend or accumulated session cost."],
    parameters: ModelCostParams,
    async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
      const settingsPricing = loadSettingsData().modelPricing ?? {};
      const summary = buildSessionSummary(ctx, settingsPricing);
      return {
        content: [{ type: "text", text: formatReport(ctx, settingsPricing) }],
        details: summary,
      };
    },
  });
}
