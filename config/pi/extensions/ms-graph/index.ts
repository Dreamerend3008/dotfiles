import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { spawn } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const EXT_DIR = join(homedir(), "dotfiles", "config", "pi", "extensions", "ms-graph");
const CLI_PATH = join(EXT_DIR, "ms_graph_cli.py");
const UV_PROJECT = EXT_DIR;
const SECRETS_FILES = [join(homedir(), ".secrets"), join(homedir(), ".secrets", "ms-graph.env")];

type EnvMap = Record<string, string>;

function loadEnvFile(path: string): EnvMap {
  if (!existsSync(path)) return {};
  const out: EnvMap = {};
  for (const line of readFileSync(path, "utf8").split("\n")) {
    let trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    if (trimmed.startsWith("export ")) trimmed = trimmed.slice(7).trim();
    const eq = trimmed.indexOf("=");
    if (eq <= 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    out[key] = value;
  }
  return out;
}

function loadSecrets(): EnvMap {
  return Object.assign({}, ...SECRETS_FILES.map(loadEnvFile));
}

async function runCli(command: string, payload: unknown) {
  const env = {
    ...process.env,
    ...loadSecrets(),
  };

  return await new Promise<any>((resolve, reject) => {
    const child = spawn("uv", ["run", "--project", UV_PROJECT, "python", CLI_PATH, command], {
      cwd: UV_PROJECT,
      env,
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk) => {
      stdout += String(chunk);
    });
    child.stderr.on("data", (chunk) => {
      stderr += String(chunk);
    });
    child.on("error", reject);
    child.on("close", (code) => {
      const text = stdout.trim();
      let parsed: any = undefined;
      if (text) {
        const lines = text.split("\n");
        parsed = JSON.parse(lines[lines.length - 1]!);
      }
      if (code === 0) return resolve(parsed);
      const parsedError = parsed && parsed.error ? parsed.error : undefined;
      reject(new Error(parsedError || stderr.trim() || `ms graph cli failed with code ${code}`));
    });

    child.stdin.write(JSON.stringify(payload == null ? {} : payload));
    child.stdin.end();
  });
}

function textResult(text: string, details: unknown = {}) {
  return {
    content: [{ type: "text", text }],
    details,
  };
}

export default function msGraphExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "graph_calendar_login",
    label: "Graph Calendar Login",
    description: "Authenticate Microsoft Graph via device code flow for the configured work tenant",
    parameters: Type.Object({}),
    promptGuidelines: ["Use graph_calendar_login when Microsoft Graph calendar tools fail due to missing authentication."],
    async execute() {
      const result = await runCli("login", {});
      const user = result.user;
      return textResult(`Logged in as ${user.displayName || "unknown"} (${user.userPrincipalName || "unknown"})`, result);
    },
  });

  pi.registerTool({
    name: "graph_calendar_me",
    label: "Graph Calendar Me",
    description: "Show the currently authenticated Microsoft Graph user",
    parameters: Type.Object({}),
    promptGuidelines: ["Use graph_calendar_me to verify which Microsoft account the calendar tools are using."],
    async execute() {
      const result = await runCli("me", {});
      const user = result.user;
      return textResult(`${user.displayName || "unknown"} <${user.userPrincipalName || user.mail || "unknown"}>`, result);
    },
  });

  pi.registerTool({
    name: "graph_calendar_list_events",
    label: "Graph Calendar List Events",
    description: "List upcoming Microsoft calendar events",
    parameters: Type.Object({
      days: Type.Optional(Type.Number({ description: "How many days ahead to search", default: 7 })),
      limit: Type.Optional(Type.Number({ description: "Max events to return", default: 10 })),
    }),
    promptGuidelines: ["Use graph_calendar_list_events to inspect upcoming events before creating or editing one."],
    async execute(_id, params) {
      const result = await runCli("list-events", params);
      const events = result.events || [];
      if (events.length === 0) return textResult("No upcoming events found.", result);
      const lines = events.map((event: any) => `- ${event.subject} | ${event.start?.dateTime} -> ${event.end?.dateTime} | id=${event.id}`);
      return textResult(lines.join("\n"), result);
    },
  });

  const eventSchema = Type.Object({
    subject: Type.String({ description: "Event title" }),
    start: Type.String({ description: "Start datetime in ISO format, e.g. 2026-07-02T15:30" }),
    end: Type.String({ description: "End datetime in ISO format, e.g. 2026-07-02T16:00" }),
    body: Type.Optional(Type.String({ description: "Optional event notes/body" })),
    location: Type.Optional(Type.String({ description: "Optional location" })),
    attendees: Type.Optional(Type.Array(Type.String({ description: "Attendee email" }))),
  });

  pi.registerTool({
    name: "graph_calendar_create_event",
    label: "Graph Calendar Create Event",
    description: "Create a Microsoft calendar event",
    parameters: eventSchema,
    promptGuidelines: ["Use graph_calendar_create_event when the user asks to schedule something on their Microsoft calendar."],
    async execute(_id, params) {
      const result = await runCli("create-event", params);
      const event = result.event;
      return textResult(`Created event ${event.subject} (${event.start?.dateTime} -> ${event.end?.dateTime})`, result);
    },
  });

  pi.registerTool({
    name: "graph_calendar_update_event",
    label: "Graph Calendar Update Event",
    description: "Update a Microsoft calendar event. For now, pass the full replacement subject/start/end.",
    parameters: Type.Composite([
      eventSchema,
      Type.Object({
        id: Type.String({ description: "Existing event id" }),
      }),
    ]),
    promptGuidelines: ["Use graph_calendar_update_event to change an existing event after identifying its id with graph_calendar_list_events."],
    async execute(_id, params) {
      const result = await runCli("update-event", params);
      return textResult(`Updated event ${params.id}`, result);
    },
  });

  pi.registerTool({
    name: "graph_calendar_delete_event",
    label: "Graph Calendar Delete Event",
    description: "Delete a Microsoft calendar event by id",
    parameters: Type.Object({
      id: Type.String({ description: "Event id" }),
    }),
    promptGuidelines: ["Use graph_calendar_delete_event only when the user explicitly asks to remove an event."],
    async execute(_id, params) {
      const result = await runCli("delete-event", params);
      return textResult(`Deleted event ${params.id}`, result);
    },
  });
}
