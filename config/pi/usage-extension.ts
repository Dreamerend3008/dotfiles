import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

type PriceInfo = {
  inputUsdPer1M?: number;
  cachedInputUsdPer1M?: number;
  outputUsdPer1M?: number;
  reasoningUsdPer1M?: number;
};

type Usage = {
  input?: number;
  output?: number;
  cacheRead?: number;
  cacheWrite?: number;
  totalTokens?: number;
  cost?: {
    total?: number;
  };
};

type Totals = {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  totalTokens: number;
  cost: number;
  assistantMessages: number;
};

type UsageSummary = {
  label: string;
  sessionRoot: string;
  sessionFilesScanned: number;
  uniqueAssistantMessages: number;
  totals: Totals;
  models: Array<{
    model: string;
    totals: Totals;
  }>;
};

const numberFormat = new Intl.NumberFormat("en-US");

function emptyTotals(): Totals {
  return {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    totalTokens: 0,
    cost: 0,
    assistantMessages: 0,
  };
}

function addUsage(totals: Totals, usage: Usage, cost: number) {
  const input = usage.input ?? 0;
  const output = usage.output ?? 0;
  const cacheRead = usage.cacheRead ?? 0;
  const cacheWrite = usage.cacheWrite ?? 0;
  const totalTokens = usage.totalTokens ?? (input + output + cacheRead + cacheWrite);

  totals.input += input;
  totals.output += output;
  totals.cacheRead += cacheRead;
  totals.cacheWrite += cacheWrite;
  totals.totalTokens += totalTokens;
  totals.cost += cost;
  totals.assistantMessages += 1;
}

function walkFiles(dir: string): string[] {
  if (!existsSync(dir)) return [];

  const files: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...walkFiles(fullPath));
      continue;
    }
    if (entry.isFile() && entry.name.endsWith(".jsonl")) {
      files.push(fullPath);
    }
  }
  return files;
}

function parseMonthArg(arg: string): { year: number; month: number; label: string } | null {
  const trimmed = arg.trim();
  if (!trimmed) {
    const now = new Date();
    return {
      year: now.getFullYear(),
      month: now.getMonth(),
      label: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`,
    };
  }

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

function isSameMonth(timestamp: unknown, year: number, month: number): boolean {
  if (typeof timestamp !== "string" && typeof timestamp !== "number") return false;
  const date = new Date(timestamp);
  if (Number.isNaN(date.getTime())) return false;
  return date.getFullYear() === year && date.getMonth() === month;
}

function getAgentDir(): string {
  return process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
}

function getDefaultSessionsDir(): string {
  return process.env.PI_CODING_AGENT_SESSION_DIR || join(getAgentDir(), "sessions");
}

function getSettingsFile(): string {
  return join(getAgentDir(), "settings.json");
}

function loadModelPricing(): Record<string, PriceInfo> {
  try {
    const settings = JSON.parse(readFileSync(getSettingsFile(), "utf8")) as {
      modelPricing?: Record<string, PriceInfo>;
    };
    return settings.modelPricing ?? {};
  } catch {
    return {};
  }
}

function estimateCost(modelId: string, usage: Usage, pricing: Record<string, PriceInfo>): number {
  const storedTotal = usage.cost?.total;
  if (typeof storedTotal === "number" && Number.isFinite(storedTotal) && storedTotal > 0) {
    return storedTotal;
  }

  const price = pricing[modelId];
  if (!price) return 0;

  return (
    ((usage.input ?? 0) / 1_000_000) * (price.inputUsdPer1M ?? 0) +
    ((usage.cacheRead ?? 0) / 1_000_000) * (price.cachedInputUsdPer1M ?? 0) +
    ((usage.output ?? 0) / 1_000_000) * (price.outputUsdPer1M ?? 0)
  );
}

function getSessionRoot(ctx: any): string {
  const currentSessionFile = ctx.sessionManager?.getSessionFile?.();
  if (typeof currentSessionFile === "string" && currentSessionFile) {
    return dirname(dirname(currentSessionFile));
  }
  return getDefaultSessionsDir();
}

function collectUsage(sessionRoot: string, label: string, year: number, month: number): UsageSummary {
  const pricing = loadModelPricing();
  const sessionFiles = walkFiles(sessionRoot);
  const seenMessages = new Set<string>();
  const totals = emptyTotals();
  const perModel = new Map<string, Totals>();

  for (const sessionFile of sessionFiles) {
    const content = readFileSync(sessionFile, "utf8");
    const lines = content.split("\n");

    for (const line of lines) {
      if (!line.trim()) continue;

      let entry: any;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }

      if (entry?.type !== "message") continue;
      if (entry?.message?.role !== "assistant") continue;
      if (!isSameMonth(entry.timestamp, year, month)) continue;
      const messageKey = line.trim();
      if (seenMessages.has(messageKey)) continue;

      const usage = (entry.message.usage ?? {}) as Usage;
      const usageTotal = usage.totalTokens ?? ((usage.input ?? 0) + (usage.output ?? 0) + (usage.cacheRead ?? 0) + (usage.cacheWrite ?? 0));
      if (usageTotal <= 0) continue;

      seenMessages.add(messageKey);

      const modelId = String(entry.message.model ?? "unknown-model");
      const cost = estimateCost(modelId, usage, pricing);

      addUsage(totals, usage, cost);

      const modelTotals = perModel.get(modelId) ?? emptyTotals();
      addUsage(modelTotals, usage, cost);
      perModel.set(modelId, modelTotals);
    }
  }

  const models = Array.from(perModel.entries())
    .map(([model, modelTotals]) => ({ model, totals: modelTotals }))
    .sort((a, b) => b.totals.cost - a.totals.cost || b.totals.totalTokens - a.totals.totalTokens);

  return {
    label,
    sessionRoot,
    sessionFilesScanned: sessionFiles.length,
    uniqueAssistantMessages: seenMessages.size,
    totals,
    models,
  };
}

function fmtInt(value: number): string {
  return numberFormat.format(Math.round(value));
}

function fmtUsd(value: number): string {
  if (value >= 100) return `$${value.toFixed(2)}`;
  if (value >= 1) return `$${value.toFixed(2)}`;
  if (value >= 0.01) return `$${value.toFixed(4)}`;
  return `$${value.toFixed(6)}`;
}

function formatBreakdownLine(label: string, totals: Totals): string {
  return `${label}: ${fmtInt(totals.totalTokens)} total (${fmtInt(totals.input)} in, ${fmtInt(totals.output)} out, ${fmtInt(totals.cacheRead)} cache read, ${fmtInt(totals.cacheWrite)} cache write) · ${fmtUsd(totals.cost)}`;
}

function formatReport(summary: UsageSummary): string {
  const lines = [
    `Pi usage for ${summary.label}`,
    `Unique assistant turns: ${fmtInt(summary.uniqueAssistantMessages)}`,
    `Session files scanned: ${fmtInt(summary.sessionFilesScanned)}`,
    `Session root: ${summary.sessionRoot}`,
    "",
    "Totals",
    formatBreakdownLine("All models", summary.totals),
  ];

  if (summary.models.length > 0) {
    lines.push("", "By model");
    for (const entry of summary.models) {
      lines.push(formatBreakdownLine(entry.model, entry.totals));
    }
  }

  return lines.join("\n");
}

export default function usageExtension(pi: ExtensionAPI) {
  pi.registerCommand("usage", {
    description: "Show monthly token usage and estimated cost across all Pi sessions",
    handler: async (args, ctx) => {
      const month = parseMonthArg(args);
      if (!month) {
        if (ctx.hasUI) {
          ctx.ui.notify("Usage: /usage [YYYY-MM]", "warning");
        } else {
          console.log("Usage: /usage [YYYY-MM]");
        }
        return;
      }

      if (!ctx.isIdle()) {
        await ctx.waitForIdle();
      }

      const summary = collectUsage(getSessionRoot(ctx), month.label, month.year, month.month);
      const report = formatReport(summary);

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
