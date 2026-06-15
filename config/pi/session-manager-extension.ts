import { DynamicBorder, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Container, SelectList, Text, type SelectItem } from "@earendil-works/pi-tui";
import { basename, join } from "node:path";
import { existsSync, readFileSync, readdirSync, statSync, unlinkSync } from "node:fs";

type SessionFileEntry = {
  type?: string;
  timestamp?: string | number;
  cwd?: string;
  name?: string;
  message?: {
    role?: string;
    content?: string | Array<{ type?: string; text?: string }>;
  };
};

type SessionSummary = {
  path: string;
  cwd: string;
  name?: string;
  firstMessage: string;
  messageCount: number;
  modified: Date;
};

function getSessionsDir(): string {
  return process.env.PI_CODING_AGENT_SESSION_DIR || `${process.env.HOME || ""}/.pi/agent/sessions`;
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

function compactWhitespace(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function getTitleCandidate(text: string): string {
  const compact = compactWhitespace(text);
  if (!compact) return "";
  if (compact.includes("<skill ")) return "";
  return compact;
}

function extractTextContent(content: SessionFileEntry["message"]["content"]): string {
  if (typeof content === "string") return compactWhitespace(content);
  if (!Array.isArray(content)) return "";
  return compactWhitespace(
    content
      .filter((block) => block?.type === "text" && typeof block.text === "string")
      .map((block) => block.text)
      .join(" "),
  );
}

function summarizeSession(path: string): SessionSummary {
  let cwd = "";
  let name = "";
  let firstMessage = "";
  let messageCount = 0;
  let modified = statSync(path).mtime;

  for (const line of readFileSync(path, "utf8").split("\n")) {
    if (!line.trim()) continue;

    let entry: SessionFileEntry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }

    const timestamp = new Date(entry.timestamp ?? 0);
    if (!Number.isNaN(timestamp.getTime()) && timestamp > modified) {
      modified = timestamp;
    }

    if (entry.type === "session") {
      cwd = entry.cwd ?? cwd;
      continue;
    }

    if (entry.type === "session_info") {
      name = compactWhitespace(entry.name ?? "") || name;
      continue;
    }

    if (entry.type !== "message") continue;
    messageCount += 1;

    if (!firstMessage && entry.message?.role === "user") {
      const candidate = getTitleCandidate(extractTextContent(entry.message.content));
      if (candidate) firstMessage = candidate;
    }
  }

  return { path, cwd, name: name || undefined, firstMessage, messageCount, modified };
}

function getSessionTitle(session: SessionSummary): string {
  const explicitName = compactWhitespace(session.name ?? "");
  if (explicitName) return explicitName;

  const firstMessage = compactWhitespace(session.firstMessage);
  if (!firstMessage) return basename(session.path, ".jsonl");
  if (firstMessage.length <= 72) return firstMessage;
  return `${firstMessage.slice(0, 69).trimEnd()}...`;
}

function formatTimestamp(date: Date): string {
  return Number.isNaN(date.getTime()) ? "unknown" : date.toISOString().replace("T", " ").replace(/\.\d{3}Z$/, "Z");
}

function formatSessionLine(session: SessionSummary, index: number): string {
  return `${index + 1}. ${getSessionTitle(session)}\n   path: ${session.path}\n   cwd: ${session.cwd || "unknown cwd"}\n   messages: ${session.messageCount}\n   updated: ${formatTimestamp(session.modified)}`;
}

function formatList(sessions: SessionSummary[]): string {
  if (sessions.length === 0) return "No saved sessions found.";
  return sessions.map(formatSessionLine).join("\n");
}

function formatSelectItem(session: SessionSummary, currentSessionPath?: string): SelectItem {
  const current = currentSessionPath && currentSessionPath === session.path ? " [current]" : "";
  return {
    value: session.path,
    label: `${getSessionTitle(session)}${current}`,
    description: `${session.cwd || "unknown cwd"} · ${formatTimestamp(session.modified)} · ${session.messageCount} messages`,
  };
}

async function pickSession(ctx: any, sessions: SessionSummary[], title: string): Promise<SessionSummary | undefined> {
  const currentSessionPath = ctx.sessionManager.getSessionFile();
  const items = sessions.map((session) => formatSelectItem(session, currentSessionPath));

  const selectedPath = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
    const container = new Container();
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
    container.addChild(new Text(theme.fg("accent", title), 1, 0));

    const selectList = new SelectList(items, Math.min(items.length, 12), {
      selectedPrefix: (text) => theme.bg("selectedBg", theme.fg("accent", text)),
      selectedText: (text) => theme.bg("selectedBg", theme.fg("text", text)),
      description: (text) => theme.fg("muted", text),
      scrollInfo: (text) => theme.fg("dim", text),
      noMatch: (text) => theme.fg("warning", text),
    });

    selectList.onSelect = (item) => done(item.value);
    selectList.onCancel = () => done(null);
    container.addChild(selectList);
    container.addChild(new Text(theme.fg("dim", "↑↓ navigate • enter select • esc cancel"), 1, 0));
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

    return {
      render: (width) => container.render(width),
      invalidate: () => container.invalidate(),
      handleInput: (data) => {
        selectList.handleInput(data);
        tui.requestRender();
      },
    };
  });

  if (!selectedPath) return undefined;
  return sessions.find((session) => session.path === selectedPath);
}

function getSortedSessions(): SessionSummary[] {
  return walkSessions(getSessionsDir())
    .map(summarizeSession)
    .sort((a, b) => b.modified.getTime() - a.modified.getTime());
}

export default function sessionManagerExtension(pi: ExtensionAPI) {
  pi.registerCommand("list-sessions", {
    description: "List saved sessions and pick one to resume.",
    handler: async (_args, ctx) => {
      const sessionsDir = getSessionsDir();
      const sessions = getSortedSessions();
      const text = `Saved sessions under ${sessionsDir}\n\n${formatList(sessions)}`;

      if (!ctx.hasUI) {
        console.log(text);
        return;
      }

      if (sessions.length === 0) {
        ctx.ui.notify("No saved sessions found.", "info");
        return;
      }

      if (!ctx.isIdle()) {
        await ctx.waitForIdle();
      }

      const currentSessionPath = ctx.sessionManager.getSessionFile();
      const selected = await pickSession(ctx, sessions, "Pick a session to resume");
      if (!selected) return;

      if (selected.path === currentSessionPath) {
        ctx.ui.notify(`Already in: ${getSessionTitle(selected)}`, "info");
        return;
      }

      await ctx.switchSession(selected.path, {
        withSession: async (nextCtx) => {
          if (nextCtx.hasUI) nextCtx.ui.notify(`Resumed: ${getSessionTitle(selected)}`, "info");
          else console.log(`Resumed: ${selected.path}`);
        },
      });
    },
  });

  pi.registerCommand("delete-session", {
    description: "Delete a saved Pi session by path, or pick one interactively.",
    handler: async (args, ctx) => {
      const sessions = getSortedSessions();
      let target = args.trim();

      if (!target && ctx.hasUI) {
        if (sessions.length === 0) {
          ctx.ui.notify("No saved sessions found.", "info");
          return;
        }

        const selected = await pickSession(ctx, sessions, "Pick a session to delete");
        if (!selected) return;

        const confirmed = await ctx.ui.confirm("Delete session", `${getSessionTitle(selected)}\n\n${selected.path}`);
        if (!confirmed) return;
        target = selected.path;
      }

      if (!target) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /delete-session <session-file-path>", "warning");
        else console.log("Usage: /delete-session <session-file-path>");
        return;
      }

      const resolvedTarget = target.startsWith("/") ? target : `${getSessionsDir()}/${target}`;
      if (!existsSync(resolvedTarget)) {
        if (ctx.hasUI) ctx.ui.notify(`Session not found: ${resolvedTarget}`, "warning");
        else console.log(`Session not found: ${resolvedTarget}`);
        return;
      }

      unlinkSync(resolvedTarget);

      if (ctx.hasUI) ctx.ui.notify(`Deleted session: ${resolvedTarget}`, "info");
      else console.log(`Deleted session: ${resolvedTarget}`);
    },
  });
}
