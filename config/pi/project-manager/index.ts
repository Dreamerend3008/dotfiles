import { DynamicBorder, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Container, SelectList, Text, type SelectItem } from "@earendil-works/pi-tui";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, extname, join, relative, resolve } from "node:path";
import {
  compactWhitespace,
  extractTextContent,
  formatTimestamp,
  getSessionsDir,
  getSessionTitle,
  getTitleCandidate,
  walkSessions as walkSessionFiles,
  summarizeSession,
  type SessionFileEntry,
  type SessionSummary,
} from "../session-manager-extension";

type ProjectManifest = {
  name: string;
  description?: string;
  memoryDir?: string;
  skillsDir?: string;
  defaultMemory?: string[];
  components?: Array<{
    name: string;
    description?: string;
    path?: string;
  }>;
  createdAt?: string;
  updatedAt?: string;
};

type RegistryProject = {
  name: string;
  path: string;
  description?: string;
  updatedAt?: string;
  openedAt?: string;
};

type ProjectRegistry = {
  version: 1;
  projects: RegistryProject[];
};

type MemoryFile = {
  name: string;
  title: string;
  relativePath: string;
  absolutePath: string;
  description: string;
  modified: Date;
};

type LaunchResult = {
  mode: "tmux-window" | "tmux-detached" | "printed";
  message: string;
  command: string;
};

const PROJECT_DIR = ".pi";
const PROJECT_MANIFEST = join(PROJECT_DIR, "project.json");
const DEFAULT_MEMORY_DIR = join(PROJECT_DIR, "memory");
const DEFAULT_SKILLS_DIR = join(PROJECT_DIR, "skills");
const MEMORY_INDEX_NAME = "INDEX.md";
const DEFAULT_MEMORY_FILES = ["overview.md", "active-context.md"];

function slugify(value: string): string {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");
}

function ensureMarkdownFileName(name: string): string {
  const trimmed = compactWhitespace(name);
  if (!trimmed) return "memory.md";
  const base = extname(trimmed).toLowerCase() === ".md" ? trimmed.slice(0, -3) : trimmed;
  const slug = slugify(base) || "memory";
  return `${slug}.md`;
}

function ensureSkillName(name: string): string {
  return slugify(name) || "project-skill";
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function nowIso(): string {
  return new Date().toISOString();
}

function getAgentDir(): string {
  return process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
}

function getProjectRegistryPath(): string {
  return join(getAgentDir(), "projects.json");
}

function getProjectManifestPath(cwd: string): string {
  return join(cwd, PROJECT_MANIFEST);
}

function getDefaultManifest(cwd: string, name: string, description?: string): ProjectManifest {
  const timestamp = nowIso();
  return {
    name,
    description: description || undefined,
    memoryDir: DEFAULT_MEMORY_DIR,
    skillsDir: DEFAULT_SKILLS_DIR,
    defaultMemory: [...DEFAULT_MEMORY_FILES],
    components: [],
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

function readJsonFile<T>(path: string): T | undefined {
  try {
    return JSON.parse(readFileSync(path, "utf8")) as T;
  } catch {
    return undefined;
  }
}

function writePrettyJson(path: string, value: unknown) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function loadProjectManifest(cwd: string): ProjectManifest | undefined {
  return readJsonFile<ProjectManifest>(getProjectManifestPath(cwd));
}

function saveProjectManifest(cwd: string, manifest: ProjectManifest) {
  const nextManifest: ProjectManifest = {
    ...manifest,
    memoryDir: manifest.memoryDir || DEFAULT_MEMORY_DIR,
    skillsDir: manifest.skillsDir || DEFAULT_SKILLS_DIR,
    defaultMemory: manifest.defaultMemory?.length ? manifest.defaultMemory : [...DEFAULT_MEMORY_FILES],
    updatedAt: nowIso(),
  };
  writePrettyJson(getProjectManifestPath(cwd), nextManifest);
}

function loadProjectRegistry(): ProjectRegistry {
  return readJsonFile<ProjectRegistry>(getProjectRegistryPath()) ?? { version: 1, projects: [] };
}

function saveProjectRegistry(registry: ProjectRegistry) {
  mkdirSync(getAgentDir(), { recursive: true });
  writePrettyJson(getProjectRegistryPath(), registry);
}

function upsertRegistryProject(project: RegistryProject) {
  const registry = loadProjectRegistry();
  const normalizedPath = resolve(project.path);
  const nextProject: RegistryProject = {
    ...project,
    path: normalizedPath,
    updatedAt: project.updatedAt || nowIso(),
  };

  const existingIndex = registry.projects.findIndex((entry) => resolve(entry.path) === normalizedPath);
  if (existingIndex >= 0) {
    registry.projects[existingIndex] = {
      ...registry.projects[existingIndex],
      ...nextProject,
    };
  } else {
    registry.projects.push(nextProject);
  }

  registry.projects.sort((a, b) => a.name.localeCompare(b.name) || a.path.localeCompare(b.path));
  saveProjectRegistry(registry);
}

function touchRegistryProject(projectPath: string) {
  const registry = loadProjectRegistry();
  const normalizedPath = resolve(projectPath);
  const existing = registry.projects.find((entry) => resolve(entry.path) === normalizedPath);
  if (!existing) return;
  existing.openedAt = nowIso();
  existing.updatedAt = existing.openedAt;
  saveProjectRegistry(registry);
}

function formatProject(project: RegistryProject, currentCwd?: string): string {
  const current = currentCwd && resolve(currentCwd) === resolve(project.path) ? " [current]" : "";
  const description = project.description ? `\n   ${project.description}` : "";
  return `${project.name}${current}\n   ${project.path}${description}`;
}

function getRegisteredProjects(): RegistryProject[] {
  return loadProjectRegistry().projects
    .map((project) => ({ ...project, path: resolve(project.path) }))
    .sort((a, b) => a.name.localeCompare(b.name) || a.path.localeCompare(b.path));
}

function getProjectMemoryDir(cwd: string, manifest: ProjectManifest): string {
  return resolve(cwd, manifest.memoryDir || DEFAULT_MEMORY_DIR);
}

function getProjectSkillsDir(cwd: string, manifest: ProjectManifest): string {
  return resolve(cwd, manifest.skillsDir || DEFAULT_SKILLS_DIR);
}

function readFrontDescription(text: string): string {
  const lines = text.replace(/\r/g, "").split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    if (trimmed.startsWith("#")) continue;
    if (["-", "*", "+"].includes(trimmed)) continue;
    return compactWhitespace(trimmed.replace(/^[-*+]\s+/, ""));
  }
  return "";
}

function readHeading(text: string, fallback: string): string {
  const match = text.match(/^#\s+(.+)$/m)?.[1];
  return compactWhitespace(match ?? fallback);
}

function walkMarkdownFiles(dir: string): string[] {
  if (!existsSync(dir)) return [];
  const paths: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      paths.push(...walkMarkdownFiles(fullPath));
    } else if (entry.isFile() && entry.name.toLowerCase().endsWith(".md")) {
      paths.push(fullPath);
    }
  }
  return paths.sort((a, b) => a.localeCompare(b));
}

function listProjectMemoryFiles(cwd: string, manifest: ProjectManifest): MemoryFile[] {
  const memoryDir = getProjectMemoryDir(cwd, manifest);
  return walkMarkdownFiles(memoryDir).map((absolutePath) => {
    const content = readFileSync(absolutePath, "utf8");
    const relativePath = relative(memoryDir, absolutePath) || basename(absolutePath);
    const title = readHeading(content, basename(absolutePath, ".md"));
    const description = readFrontDescription(content);
    return {
      name: relativePath,
      title,
      relativePath,
      absolutePath,
      description,
      modified: statSync(absolutePath).mtime,
    };
  });
}

function buildMemoryIndexContent(cwd: string, manifest: ProjectManifest): string {
  const files = listProjectMemoryFiles(cwd, manifest).filter((file) => file.relativePath !== MEMORY_INDEX_NAME);
  const lines = [
    "# Project Memory Index",
    "",
    `Project: ${manifest.name}`,
    "",
    "This file is generated by the Pi project manager extension.",
    "Use it as a quick map of project memory files.",
    "",
  ];

  if (files.length === 0) {
    lines.push("No project memory files exist yet.");
    return `${lines.join("\n")}\n`;
  }

  lines.push("## Files", "");
  for (const file of files) {
    const detail = file.description ? ` — ${file.description}` : "";
    lines.push(`- \`${file.relativePath}\` — **${file.title}**${detail}`);
  }

  return `${lines.join("\n")}\n`;
}

function updateProjectMemoryIndex(cwd: string, manifest: ProjectManifest) {
  const memoryDir = getProjectMemoryDir(cwd, manifest);
  mkdirSync(memoryDir, { recursive: true });
  writeFileSync(join(memoryDir, MEMORY_INDEX_NAME), buildMemoryIndexContent(cwd, manifest), "utf8");
}

function createOverviewTemplate(name: string): string {
  return `# ${name} Overview\n\n## Goals\n- \n\n## Architecture\n- \n\n## Important Paths\n- \n\n## Constraints\n- \n\n## Open Questions\n- \n`;
}

function createActiveContextTemplate(name: string): string {
  return `# ${name} Active Context\n\n## Current Focus\n- \n\n## In Progress\n- \n\n## Recent Decisions\n- \n\n## Next Steps\n- \n`;
}

function createMemoryTemplate(title: string): string {
  return `# ${title}\n\n## Summary\n- \n\n## Details\n- \n\n## References\n- \n`;
}

function createSkillTemplate(skillName: string, projectName: string, description: string): string {
  return `---\nname: ${skillName}\ndescription: ${description || `Project-specific workflow for ${projectName}. Use when working on ${projectName}.`}\n---\n\n# ${skillName}\n\n## Purpose\n\nDescribe when this project-specific skill should be used.\n\n## Workflow\n\n1. Inspect the relevant files first.\n2. Follow the project memory in ../memory/ when needed.\n3. Make minimal, consistent changes.\n4. Validate the result.\n\n## References\n\n- Project overview: ../../memory/overview.md\n- Active context: ../../memory/active-context.md\n`;
}

function getProjectSessions(cwd: string): SessionSummary[] {
  return walkSessionFiles(getSessionsDir())
    .map(summarizeSession)
    .filter((session) => resolve(session.cwd || "") === resolve(cwd))
    .sort((a, b) => b.modified.getTime() - a.modified.getTime());
}

async function pickItem(ctx: any, items: SelectItem[], title: string): Promise<string | undefined> {
  if (!ctx.hasUI) return undefined;

  const selected = await ctx.ui.custom<string | null>((tui: any, theme: any, _kb: any, done: (value: string | null) => void) => {
    const container = new Container();
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
    container.addChild(new Text(theme.fg("accent", title), 1, 0));

    const selectList = new SelectList(items, Math.min(items.length, 12), {
      selectedPrefix: (text) => theme.bg("selectedBg", theme.fg("accent", text)),
      selectedText: (text) => theme.bg("selectedBg", theme.fg("accent", text)),
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
      render: (width: number) => container.render(width),
      invalidate: () => container.invalidate(),
      handleInput: (data: string) => {
        selectList.handleInput(data);
        tui.requestRender();
      },
    };
  });

  return selected ?? undefined;
}

function findRegisteredProject(arg: string): RegistryProject | undefined {
  const normalized = arg.trim();
  if (!normalized) return undefined;
  const projects = getRegisteredProjects();
  const resolvedPath = resolve(normalized);

  if (existsSync(resolvedPath) && statSync(resolvedPath).isDirectory()) {
    const byPath = projects.find((project) => resolve(project.path) === resolvedPath);
    if (byPath) return byPath;

    const manifest = loadProjectManifest(resolvedPath);
    if (!manifest) return undefined;
    return {
      name: manifest.name,
      path: resolvedPath,
      description: manifest.description,
      updatedAt: nowIso(),
    };
  }

  return projects.find(
    (project) => project.name === normalized || project.name.toLowerCase() === normalized.toLowerCase() || project.path === normalized,
  );
}

function hasTmux(): boolean {
  return spawnSync("bash", ["-lc", "command -v tmux >/dev/null 2>&1"]).status === 0;
}

function buildPiCommand(name?: string, sessionPath?: string): string {
  const parts = ["pi"];
  if (name) parts.push(`--name ${shellQuote(name)}`);
  if (sessionPath) parts.push(`--session ${shellQuote(sessionPath)}`);
  return parts.join(" ");
}

function buildPiEnvPrefix(): string {
  return 'env NODE_OPTIONS="--no-warnings=ExperimentalWarning" NODE_NO_WARNINGS="1"';
}

function launchPiInstance(cwd: string, options?: { name?: string; sessionPath?: string; windowName?: string }): LaunchResult {
  const nixSource = 'if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi';
  const piCmd = buildPiCommand(options?.name, options?.sessionPath);
  const envPrefix = buildPiEnvPrefix();
  const command = `cd ${shellQuote(cwd)} && ${nixSource} && exec ${envPrefix} ${piCmd}`;

  if (!hasTmux()) {
    return {
      mode: "printed",
      command,
      message: `tmux is not available. Run:\n${command}`,
    };
  }

  const tmuxCommand = `${nixSource} && exec ${envPrefix} ${piCmd}`;

  if (process.env.TMUX) {
    const windowName = options?.windowName || options?.name || basename(cwd);
    const result = spawnSync("tmux", ["new-window", "-c", cwd, "-n", windowName, tmuxCommand], { stdio: "ignore" });
    if (result.status === 0) {
      return {
        mode: "tmux-window",
        command,
        message: `Opened a new tmux window for ${options?.name || basename(cwd)} in ${cwd}`,
      };
    }
  }

  const sessionName = slugify(options?.windowName || options?.name || basename(cwd) || "pi-project") || "pi-project";
  const detached = spawnSync("tmux", ["new-session", "-d", "-s", sessionName, "-c", cwd, tmuxCommand], {
    stdio: "ignore",
  });

  if (detached.status === 0) {
    return {
      mode: "tmux-detached",
      command,
      message: `Started detached tmux session '${sessionName}' for ${cwd}. Attach with: tmux attach -t ${sessionName}`,
    };
  }

  return {
    mode: "printed",
    command,
    message: `Could not launch tmux automatically. Run:\n${command}`,
  };
}

function ensureProjectDirs(cwd: string, manifest: ProjectManifest) {
  mkdirSync(join(cwd, PROJECT_DIR), { recursive: true });
  mkdirSync(getProjectMemoryDir(cwd, manifest), { recursive: true });
  mkdirSync(getProjectSkillsDir(cwd, manifest), { recursive: true });
}

function ensureDefaultProjectFiles(cwd: string, manifest: ProjectManifest) {
  const memoryDir = getProjectMemoryDir(cwd, manifest);
  const overviewPath = join(memoryDir, "overview.md");
  const activeContextPath = join(memoryDir, "active-context.md");

  if (!existsSync(overviewPath)) {
    writeFileSync(overviewPath, createOverviewTemplate(manifest.name), "utf8");
  }
  if (!existsSync(activeContextPath)) {
    writeFileSync(activeContextPath, createActiveContextTemplate(manifest.name), "utf8");
  }

  updateProjectMemoryIndex(cwd, manifest);
}

function formatProjectList(projects: RegistryProject[], currentCwd?: string): string {
  if (projects.length === 0) return "No registered Pi projects found.";
  return projects.map((project, index) => `${index + 1}. ${formatProject(project, currentCwd)}`).join("\n");
}

function ensureProjectContext(ctx: any): { manifest: ProjectManifest; cwd: string } | undefined {
  const cwd = ctx.cwd;
  const manifest = loadProjectManifest(cwd);
  if (!manifest) return undefined;
  return { manifest, cwd };
}

function formatMemoryList(files: MemoryFile[]): string {
  if (files.length === 0) return "No project memory files found.";
  return files
    .map((file, index) => `${index + 1}. ${file.relativePath}\n   ${file.title}${file.description ? ` — ${file.description}` : ""}`)
    .join("\n");
}

function findMemoryFile(files: MemoryFile[], arg: string): MemoryFile | undefined {
  const normalized = arg.trim().toLowerCase();
  return files.find(
    (file) =>
      file.relativePath.toLowerCase() === normalized ||
      file.name.toLowerCase() === normalized ||
      basename(file.relativePath, ".md").toLowerCase() === normalized,
  );
}

function buildProjectSystemPrompt(cwd: string, manifest: ProjectManifest): string {
  const files = listProjectMemoryFiles(cwd, manifest)
    .filter((file) => file.relativePath !== MEMORY_INDEX_NAME)
    .slice(0, 10);
  const components = manifest.components?.slice(0, 10) ?? [];
  const defaultMemory = (manifest.defaultMemory ?? DEFAULT_MEMORY_FILES).slice(0, 6);

  const lines = [
    `Current project: ${manifest.name}`,
    manifest.description ? `Description: ${manifest.description}` : "",
    `Project manifest: ${PROJECT_MANIFEST}`,
    `Project memory directory: ${manifest.memoryDir || DEFAULT_MEMORY_DIR}`,
    `Project skills directory: ${manifest.skillsDir || DEFAULT_SKILLS_DIR}`,
    defaultMemory.length > 0 ? `Default memory files: ${defaultMemory.join(", ")}` : "",
    files.length > 0 ? "Available project memory files:" : "",
    ...files.map((file) => `- ${file.relativePath}: ${file.title}${file.description ? ` — ${file.description}` : ""}`),
    components.length > 0 ? "Known project components:" : "",
    ...components.map((component) => `- ${component.name}${component.description ? ` — ${component.description}` : ""}`),
    "When a task depends on project-specific memory, read the relevant markdown file under the project memory directory before making changes.",
    "When a task matches a project-specific workflow, look for a skill under the project skills directory.",
  ].filter(Boolean);

  return lines.join("\n");
}

async function chooseProject(ctx: any, title: string): Promise<RegistryProject | undefined> {
  const projects = getRegisteredProjects();
  if (projects.length === 0) return undefined;
  const value = await pickItem(
    ctx,
    projects.map((project) => ({
      value: project.path,
      label: project.name,
      description: project.description ? `${project.path} · ${project.description}` : project.path,
    })),
    title,
  );
  return value ? projects.find((project) => project.path === value) : undefined;
}

async function chooseMemoryFile(ctx: any, files: MemoryFile[], title: string): Promise<MemoryFile | undefined> {
  const value = await pickItem(
    ctx,
    files.map((file) => ({
      value: file.absolutePath,
      label: file.relativePath,
      description: file.description ? `${file.title} · ${file.description}` : file.title,
    })),
    title,
  );
  return value ? files.find((file) => file.absolutePath === value) : undefined;
}

async function chooseSession(ctx: any, sessions: SessionSummary[], title: string): Promise<SessionSummary | undefined> {
  const currentSessionPath = ctx.sessionManager.getSessionFile();
  const value = await pickItem(
    ctx,
    sessions.map((session) => ({
      value: session.path,
      label: `${getSessionTitle(session)}${currentSessionPath === session.path ? " [current]" : ""}`,
      description: `${formatTimestamp(session.modified)} · ${session.messageCount} messages`,
    })),
    title,
  );
  return value ? sessions.find((session) => session.path === value) : undefined;
}

async function resolveProjectName(args: string, ctx: any, fallback: string): Promise<string> {
  const explicit = compactWhitespace(args);
  if (explicit) return explicit;
  if (!ctx.hasUI) return fallback;
  return compactWhitespace((await ctx.ui.input("Project name", fallback)) ?? fallback) || fallback;
}

async function resolveDescription(args: string, ctx: any): Promise<string | undefined> {
  if (!ctx.hasUI) return undefined;
  const description = compactWhitespace((await ctx.ui.input("Project description (optional)", args.trim())) ?? "");
  return description || undefined;
}

export default function projectManagerExtension(pi: ExtensionAPI) {
  pi.on("before_agent_start", async (event, ctx) => {
    if (!ctx.isProjectTrusted?.()) return;
    const manifest = loadProjectManifest(ctx.cwd);
    if (!manifest) return;
    return {
      systemPrompt: `${event.systemPrompt}\n\nProject-specific context\n${buildProjectSystemPrompt(ctx.cwd, manifest)}`,
    };
  });

  pi.registerCommand("project-create", {
    description: "Create Pi project scaffolding in the current directory",
    handler: async (args, ctx) => {
      const cwd = ctx.cwd;
      const existing = loadProjectManifest(cwd);
      const defaultName = basename(cwd) || "project";
      const name = await resolveProjectName(args, ctx, existing?.name || defaultName);
      const description = existing?.description ?? (await resolveDescription("", ctx));
      const manifest = existing ?? getDefaultManifest(cwd, name, description);
      manifest.name = name;
      manifest.description = description;
      manifest.updatedAt = nowIso();

      ensureProjectDirs(cwd, manifest);
      saveProjectManifest(cwd, manifest);
      ensureDefaultProjectFiles(cwd, manifest);
      upsertRegistryProject({ name: manifest.name, path: cwd, description: manifest.description, updatedAt: nowIso() });

      const report = [
        `Project scaffolded for ${manifest.name}`,
        `Path: ${cwd}`,
        `Manifest: ${PROJECT_MANIFEST}`,
        `Memory: ${manifest.memoryDir || DEFAULT_MEMORY_DIR}`,
        `Skills: ${manifest.skillsDir || DEFAULT_SKILLS_DIR}`,
      ].join("\n");

      if (ctx.hasUI) {
        pi.sendMessage({ customType: "project-create", content: report, display: true, details: { cwd, manifest } });
      } else {
        console.log(report);
      }
    },
  });

  pi.registerCommand("project-list", {
    description: "List registered Pi projects",
    handler: async (_args, ctx) => {
      const projects = getRegisteredProjects();
      const report = formatProjectList(projects, ctx.cwd);
      if (!ctx.hasUI) {
        console.log(report);
        return;
      }
      pi.sendMessage({ customType: "project-list", content: report, display: true, details: { projects } });
    },
  });

  pi.registerCommand("project-open", {
    description: "Open a registered Pi project in another Pi process",
    getArgumentCompletions: (prefix) => {
      const lower = prefix.toLowerCase();
      const items = getRegisteredProjects()
        .filter((project) => project.name.toLowerCase().startsWith(lower) || project.path.toLowerCase().startsWith(lower))
        .map((project) => ({ value: project.name, label: project.name, description: project.path }));
      return items.length > 0 ? items : null;
    },
    handler: async (args, ctx) => {
      const explicit = compactWhitespace(args);
      const selected = explicit ? findRegisteredProject(explicit) : await chooseProject(ctx, "Open Pi project");
      if (!selected) {
        const message = explicit ? `Project not found: ${explicit}` : "No project selected.";
        if (ctx.hasUI) ctx.ui.notify(message, explicit ? "warning" : "info");
        else console.log(message);
        return;
      }

      if (!loadProjectManifest(selected.path)) {
        if (ctx.hasUI) ctx.ui.notify(`No ${PROJECT_MANIFEST} found in ${selected.path}`, "warning");
        else console.log(`No ${PROJECT_MANIFEST} found in ${selected.path}`);
        return;
      }

      upsertRegistryProject({ ...selected, updatedAt: nowIso() });
      touchRegistryProject(selected.path);
      const launch = launchPiInstance(selected.path, { windowName: selected.name });

      if (ctx.hasUI) {
        pi.sendMessage({
          customType: "project-open",
          content: `${launch.message}\n\nCommand:\n${launch.command}`,
          display: true,
          details: { project: selected, launch },
        });
      } else {
        console.log(`${launch.message}\n\nCommand:\n${launch.command}`);
      }
    },
  });

  pi.registerCommand("project-memory", {
    description: "List project memory files or open one interactively",
    getArgumentCompletions: (_prefix) => {
      const manifest = loadProjectManifest(process.cwd());
      if (!manifest) return null;
      return listProjectMemoryFiles(process.cwd(), manifest).map((file) => ({
        value: basename(file.relativePath, ".md"),
        label: file.relativePath,
        description: file.title,
      }));
    },
    handler: async (args, ctx) => {
      const project = ensureProjectContext(ctx);
      if (!project) {
        const message = `No Pi project found in ${ctx.cwd}. Create ${PROJECT_MANIFEST} first.`;
        if (ctx.hasUI) ctx.ui.notify(message, "warning");
        else console.log(message);
        return;
      }

      const files = listProjectMemoryFiles(project.cwd, project.manifest);
      const explicit = compactWhitespace(args);
      if (!explicit) {
        if (!ctx.hasUI) {
          console.log(formatMemoryList(files));
          return;
        }

        if (files.length === 0) {
          ctx.ui.notify("No project memory files found.", "info");
          return;
        }

        const selected = await chooseMemoryFile(ctx, files, "Open project memory");
        if (!selected) return;
        const current = readFileSync(selected.absolutePath, "utf8");
        const edited = await ctx.ui.editor(`Edit ${selected.relativePath}`, current);
        if (edited === undefined) return;
        writeFileSync(selected.absolutePath, edited, "utf8");
        updateProjectMemoryIndex(project.cwd, project.manifest);
        ctx.ui.notify(`Updated ${selected.relativePath}`, "info");
        return;
      }

      const file = findMemoryFile(files, explicit);
      if (!file) {
        const message = `Memory file not found: ${explicit}`;
        if (ctx.hasUI) ctx.ui.notify(message, "warning");
        else console.log(message);
        return;
      }

      if (!ctx.hasUI) {
        console.log(readFileSync(file.absolutePath, "utf8"));
        return;
      }

      const edited = await ctx.ui.editor(`Edit ${file.relativePath}`, readFileSync(file.absolutePath, "utf8"));
      if (edited === undefined) return;
      writeFileSync(file.absolutePath, edited, "utf8");
      updateProjectMemoryIndex(project.cwd, project.manifest);
      ctx.ui.notify(`Updated ${file.relativePath}`, "info");
    },
  });

  pi.registerCommand("project-memory-new", {
    description: "Create a new project memory markdown file",
    handler: async (args, ctx) => {
      const project = ensureProjectContext(ctx);
      if (!project) {
        const message = `No Pi project found in ${ctx.cwd}. Create ${PROJECT_MANIFEST} first.`;
        if (ctx.hasUI) ctx.ui.notify(message, "warning");
        else console.log(message);
        return;
      }

      const requested = compactWhitespace(args) || (ctx.hasUI ? compactWhitespace((await ctx.ui.input("Memory file name", "")) ?? "") : "");
      if (!requested) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /project-memory-new <name>", "warning");
        else console.log("Usage: /project-memory-new <name>");
        return;
      }

      const fileName = ensureMarkdownFileName(requested);
      const memoryDir = getProjectMemoryDir(project.cwd, project.manifest);
      const targetPath = join(memoryDir, fileName);
      mkdirSync(dirname(targetPath), { recursive: true });

      if (!existsSync(targetPath)) {
        writeFileSync(targetPath, createMemoryTemplate(requested.replace(/\.md$/i, "")), "utf8");
      }

      updateProjectMemoryIndex(project.cwd, project.manifest);

      if (!ctx.hasUI) {
        console.log(`Created ${relative(project.cwd, targetPath)}`);
        return;
      }

      const edited = await ctx.ui.editor(`Edit ${relative(project.cwd, targetPath)}`, readFileSync(targetPath, "utf8"));
      if (edited !== undefined) {
        writeFileSync(targetPath, edited, "utf8");
        updateProjectMemoryIndex(project.cwd, project.manifest);
      }
      ctx.ui.notify(`Ready: ${relative(project.cwd, targetPath)}`, "info");
    },
  });

  pi.registerCommand("project-skill-new", {
    description: "Create a new project-specific Pi skill",
    handler: async (args, ctx) => {
      const project = ensureProjectContext(ctx);
      if (!project) {
        const message = `No Pi project found in ${ctx.cwd}. Create ${PROJECT_MANIFEST} first.`;
        if (ctx.hasUI) ctx.ui.notify(message, "warning");
        else console.log(message);
        return;
      }

      const requested = compactWhitespace(args) || (ctx.hasUI ? compactWhitespace((await ctx.ui.input("Skill name", "")) ?? "") : "");
      if (!requested) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /project-skill-new <name>", "warning");
        else console.log("Usage: /project-skill-new <name>");
        return;
      }

      const skillName = ensureSkillName(requested);
      const description = ctx.hasUI ? compactWhitespace((await ctx.ui.input("Skill description", `Project-specific workflow for ${project.manifest.name}`)) ?? "") : "";
      const skillDir = join(getProjectSkillsDir(project.cwd, project.manifest), skillName);
      const skillPath = join(skillDir, "SKILL.md");
      mkdirSync(skillDir, { recursive: true });

      if (!existsSync(skillPath)) {
        writeFileSync(skillPath, createSkillTemplate(skillName, project.manifest.name, description), "utf8");
      }

      if (!ctx.hasUI) {
        console.log(`Created ${relative(project.cwd, skillPath)}`);
        return;
      }

      const edited = await ctx.ui.editor(`Edit ${relative(project.cwd, skillPath)}`, readFileSync(skillPath, "utf8"));
      if (edited !== undefined) {
        writeFileSync(skillPath, edited, "utf8");
      }
      ctx.ui.notify(`Created ${relative(project.cwd, skillPath)}. Run /reload to load the new skill.`, "info");
    },
  });

  pi.registerCommand("project-session-list", {
    description: "List sessions for the current project",
    handler: async (_args, ctx) => {
      const sessions = getProjectSessions(ctx.cwd);
      const report = sessions.length
        ? sessions
            .map(
              (session, index) =>
                `${index + 1}. ${getSessionTitle(session)}\n   ${session.path}\n   ${formatTimestamp(session.modified)} · ${session.messageCount} messages`,
            )
            .join("\n")
        : "No saved sessions found for this project.";

      if (!ctx.hasUI) {
        console.log(report);
        return;
      }

      pi.sendMessage({ customType: "project-session-list", content: report, display: true, details: { sessions } });
    },
  });

  pi.registerCommand("project-session-new", {
    description: "Create a new named session for the current project",
    handler: async (args, ctx) => {
      const name = compactWhitespace(args) || (ctx.hasUI ? compactWhitespace((await ctx.ui.input("New project session name", "")) ?? "") : "");
      if (!name) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /project-session-new <name>", "warning");
        else console.log("Usage: /project-session-new <name>");
        return;
      }

      if (!ctx.isIdle()) {
        await ctx.waitForIdle();
      }

      const result = await ctx.newSession({
        parentSession: ctx.sessionManager.getSessionFile(),
        setup: async (sessionManager: any) => {
          sessionManager.appendSessionInfo(name);
        },
        withSession: async (nextCtx: any) => {
          nextCtx.ui.notify(`Opened new project session: ${name}`, "info");
        },
      });

      if (result.cancelled && ctx.hasUI) {
        ctx.ui.notify("New session cancelled.", "info");
      }
    },
  });

  pi.registerCommand("project-session-open", {
    description: "Switch to another saved session from this project",
    getArgumentCompletions: (prefix) => {
      const lower = prefix.toLowerCase();
      return getProjectSessions(process.cwd())
        .filter((session) => getSessionTitle(session).toLowerCase().startsWith(lower) || session.path.toLowerCase().includes(lower))
        .map((session) => ({ value: getSessionTitle(session), label: getSessionTitle(session), description: session.path }));
    },
    handler: async (args, ctx) => {
      if (!ctx.isIdle()) {
        await ctx.waitForIdle();
      }

      const sessions = getProjectSessions(ctx.cwd);
      if (sessions.length === 0) {
        if (ctx.hasUI) ctx.ui.notify("No saved sessions found for this project.", "info");
        else console.log("No saved sessions found for this project.");
        return;
      }

      const explicit = compactWhitespace(args);
      const selected = explicit
        ? sessions.find(
            (session) =>
              getSessionTitle(session) === explicit ||
              getSessionTitle(session).toLowerCase() === explicit.toLowerCase() ||
              session.path === explicit,
          )
        : await chooseSession(ctx, sessions, "Open project session");

      if (!selected) {
        const message = explicit ? `Session not found: ${explicit}` : "No session selected.";
        if (ctx.hasUI) ctx.ui.notify(message, explicit ? "warning" : "info");
        else console.log(message);
        return;
      }

      const currentSessionPath = ctx.sessionManager.getSessionFile();
      if (currentSessionPath === selected.path) {
        if (ctx.hasUI) ctx.ui.notify(`Already in ${getSessionTitle(selected)}`, "info");
        else console.log(`Already in ${getSessionTitle(selected)}`);
        return;
      }

      const result = await ctx.switchSession(selected.path, {
        withSession: async (nextCtx: any) => {
          nextCtx.ui.notify(`Switched to ${getSessionTitle(selected)}`, "info");
        },
      });

      if (result.cancelled && ctx.hasUI) {
        ctx.ui.notify("Session switch cancelled.", "info");
      }
    },
  });

  pi.registerCommand("project-session-spawn", {
    description: "Start another Pi session for this project, preferably in tmux",
    handler: async (args, ctx) => {
      const sessions = getProjectSessions(ctx.cwd);
      const explicit = compactWhitespace(args);

      let launch: LaunchResult;
      if (explicit) {
        const existing = sessions.find(
          (session) =>
            getSessionTitle(session) === explicit ||
            getSessionTitle(session).toLowerCase() === explicit.toLowerCase() ||
            session.path === explicit,
        );
        launch = existing
          ? launchPiInstance(ctx.cwd, { sessionPath: existing.path, name: getSessionTitle(existing), windowName: getSessionTitle(existing) })
          : launchPiInstance(ctx.cwd, { name: explicit, windowName: explicit });
      } else {
        const defaultName = `component-${sessions.length + 1}`;
        const name = ctx.hasUI ? compactWhitespace((await ctx.ui.input("Spawn session name", defaultName)) ?? defaultName) : defaultName;
        launch = launchPiInstance(ctx.cwd, { name, windowName: name });
      }

      if (ctx.hasUI) {
        pi.sendMessage({
          customType: "project-session-spawn",
          content: `${launch.message}\n\nCommand:\n${launch.command}`,
          display: true,
          details: { cwd: ctx.cwd, launch },
        });
      } else {
        console.log(`${launch.message}\n\nCommand:\n${launch.command}`);
      }
    },
  });
}
