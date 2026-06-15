import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, readFileSync, readdirSync, unlinkSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import { Type } from "typebox";

type SessionEntry = {
  type?: string;
  timestamp?: string | number;
  message?: {
    role?: string;
  };
  label?: string;
  title?: string;
  name?: string;
  session?: {
    name?: string;
  };
};

const ListParams = Type.Object({});
const DeleteParams = Type.Object({
  sessionFile: Type.String({ minLength: 1, description: "Absolute or relative path to a session JSONL file" }),
});

function getAgentDir(): string {
  return process.env.PI_CODING_AGENT_DIR || join(process.env.HOME || "", ".pi", "agent");
}

function getSessionsDir(): string {
  return process.env.PI_CODING_AGENT_SESSION_DIR || join(getAgentDir(), "sessions");
}

function walkSessions(dir: string): string[] {
  if (!existsSync(dir)) return [];
  const files: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) files.push(...walkSessions(fullPath));
    else if (entry.isFile() && entry.name.endsWith(".jsonl")) files.push(fullPath);
  }
  return files;
}

function summarizeSession(filePath: string) {
  let lastLabel = "";
  let firstTimestamp: Date | null = null;
  let lastTimestamp: Date | null = null;
  let assistantTurns = 0;
  let userTurns = 0;

  for (const line of readFileSync(filePath, "utf8").split("\n")) {
    if (!line.trim()) continue;
    let entry: SessionEntry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }

    const ts = new Date(entry.timestamp ?? 0);
    if (!Number.isNaN(ts.getTime())) {
      if (!firstTimestamp || ts < firstTimestamp) firstTimestamp = ts;
      if (!lastTimestamp || ts > lastTimestamp) lastTimestamp = ts;
    }

    if (entry.label || entry.title || entry.name || entry.session?.name) {
      lastLabel = entry.label ?? entry.title ?? entry.name ?? entry.session?.name ?? lastLabel;
    }

    if (entry.type === "message") {
      if (entry.message?.role === "assistant") assistantTurns += 1;
      if (entry.message?.role === "user") userTurns += 1;
    }
  }

  return {
    filePath,
    fileName: basename(filePath),
    label: lastLabel || basename(filePath, ".jsonl"),
    firstTimestamp: firstTimestamp?.toISOString() ?? null,
    lastTimestamp: lastTimestamp?.toISOString() ?? null,
    assistantTurns,
    userTurns,
  };
}

function formatList(items: Array<ReturnType<typeof summarizeSession>>): string {
  if (items.length === 0) return "No saved sessions found.";
  return items
    .map((item, index) => {
      const range = item.firstTimestamp && item.lastTimestamp ? `${item.firstTimestamp} → ${item.lastTimestamp}` : "unknown dates";
      return `${index + 1}. ${item.label}\n   file: ${item.fileName}\n   path: ${item.filePath}\n   turns: ${item.userTurns} user / ${item.assistantTurns} assistant\n   range: ${range}`;
    })
    .join("\n");
}

export default function sessionManagerExtension(pi: ExtensionAPI) {
  pi.registerCommand("list-sessions", {
    description: "List saved Pi sessions with names, timestamps, and file paths.",
    async execute(ctx) {
      const sessionsDir = getSessionsDir();
      const sessions = walkSessions(sessionsDir).map(summarizeSession).sort((a, b) => (b.lastTimestamp ?? "").localeCompare(a.lastTimestamp ?? ""));
      const text = `Saved sessions under ${sessionsDir}\n\n${formatList(sessions)}`;
      ctx.ui.appendMessage({ type: "custom", customType: "session-manager", content: text, display: true, details: { sessionsDir, sessions }, timestamp: new Date().toISOString() } as any);
      return { content: [{ type: "text", text }], details: { sessionsDir, sessions } };
    },
  });

  pi.registerCommand("delete-session", {
    description: "Delete a saved Pi session by path.",
    async execute(ctx, args: string[]) {
      const sessionFile = args.join(" ").trim();
      if (!sessionFile) {
        return { content: [{ type: "text", text: "Usage: /delete-session <session-file-path>" }] };
      }
      const target = sessionFile.startsWith("/") ? sessionFile : join(getSessionsDir(), sessionFile);
      if (!existsSync(target)) {
        return { content: [{ type: "text", text: `Session not found: ${target}` }], details: { target, deleted: false } };
      }
      unlinkSync(target);
      return { content: [{ type: "text", text: `Deleted session: ${target}` }], details: { target, deleted: true } };
    },
  });
}
