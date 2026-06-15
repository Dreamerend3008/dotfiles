import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const SEARCH_ENDPOINTS = [
  {
    name: "DuckDuckGo",
    url: "https://html.duckduckgo.com/html/",
    buildBody: (query: string) => new URLSearchParams({ q: query, kl: "us-en", kp: "-1" }),
    parse: extractHtmlResults,
  },
  {
    name: "DuckDuckGo Lite",
    url: "https://lite.duckduckgo.com/lite/",
    buildBody: (query: string) => new URLSearchParams({ q: query, kl: "us-en", kp: "-1" }),
    parse: extractLiteResults,
  },
] as const;
const MAX_RESULTS = 8;
const MAX_QUERY_LENGTH = 500;
const MAX_SNIPPET_LENGTH = 280;
const MAX_TITLE_LENGTH = 120;
const DEFAULT_PAGE_CHARS = 8000;
const MAX_PAGE_CHARS = 20000;
const SEARCH_TIMEOUT_MS = 15000;

const SearchParams = Type.Object({
  query: Type.String({ minLength: 1, maxLength: MAX_QUERY_LENGTH, description: "Search query" }),
  maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 10, default: MAX_RESULTS })),
});

const ReadPageParams = Type.Object({
  url: Type.String({ minLength: 1, maxLength: 2048, description: "Public HTTP or HTTPS URL to read" }),
  maxChars: Type.Optional(Type.Integer({ minimum: 500, maximum: MAX_PAGE_CHARS, default: DEFAULT_PAGE_CHARS })),
});

type SearchResult = {
  title: string;
  url: string;
  snippet: string;
  source: string;
};

type PageResult = {
  url: string;
  finalUrl: string;
  title: string;
  description: string;
  contentType: string;
  text: string;
};

function clean(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function trunc(text: string, max: number): string {
  const cleaned = clean(text);
  return cleaned.length > max ? `${cleaned.slice(0, max - 1)}…` : cleaned;
}

function decodeDuckDuckGoUrl(url: string): string {
  try {
    const parsed = new URL(url);
    const uddg = parsed.searchParams.get("uddg");
    return decodeHtmlEntities(uddg ? decodeURIComponent(uddg) : url);
  } catch {
    return decodeHtmlEntities(url);
  }
}

function decodeHtmlEntities(text: string): string {
  const named: Record<string, string> = {
    amp: "&",
    lt: "<",
    gt: ">",
    quot: '"',
    apos: "'",
    nbsp: " ",
    mdash: "—",
    ndash: "–",
    hellip: "…",
    rsquo: "’",
    lsquo: "‘",
    rdquo: "”",
    ldquo: "“",
    copy: "©",
    reg: "®",
    trade: "™",
  };

  return text.replace(/&(#x?[0-9a-fA-F]+|[a-zA-Z]+);/g, (match, entity: string) => {
    if (entity[0] === "#") {
      const isHex = entity[1]?.toLowerCase() === "x";
      const raw = isHex ? entity.slice(2) : entity.slice(1);
      const value = Number.parseInt(raw, isHex ? 16 : 10);
      return Number.isFinite(value) ? String.fromCodePoint(value) : match;
    }
    return named[entity] ?? match;
  });
}

function normalizeResult(url: string, title: string, snippet: string, source: string): SearchResult | null {
  const normalizedUrl = decodeDuckDuckGoUrl(url);
  const normalizedTitle = trunc(decodeHtmlEntities(title.replace(/<[^>]+>/g, " ")), MAX_TITLE_LENGTH);
  const normalizedSnippet = trunc(decodeHtmlEntities(snippet.replace(/<[^>]+>/g, " ")), MAX_SNIPPET_LENGTH);
  if (!normalizedUrl || !normalizedTitle) return null;
  return { title: normalizedTitle, url: normalizedUrl, snippet: normalizedSnippet, source };
}

function extractHtmlResults(html: string): SearchResult[] {
  const results: SearchResult[] = [];
  const resultStartRegex = /<div class="result[^"]*web-result[^"]*">/g;
  const matches = [...html.matchAll(resultStartRegex)];

  for (let i = 0; i < matches.length; i++) {
    const start = matches[i].index;
    if (start == null) continue;

    const end = matches[i + 1]?.index ?? html.length;
    const block = html.slice(start, end);
    const linkMatch = block.match(/<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/);
    if (!linkMatch) continue;

    const snippetMatch = block.match(/<a[^>]+class="result__snippet"[^>]*>([\s\S]*?)<\/a>/);
    const result = normalizeResult(linkMatch[1], linkMatch[2], snippetMatch?.[1] ?? "", "DuckDuckGo");
    if (!result) continue;
    results.push(result);
    if (results.length >= 10) break;
  }

  return results;
}

function extractLiteResults(html: string): SearchResult[] {
  const results: SearchResult[] = [];
  const rowRegex = /<a rel="nofollow" href="([^"]+)" class='result-link'>([\s\S]*?)<\/a>[\s\S]*?<td class='result-snippet'>\s*([\s\S]*?)\s*<\/td>/g;

  for (const match of html.matchAll(rowRegex)) {
    const result = normalizeResult(match[1], match[2], match[3], "DuckDuckGo Lite");
    if (!result) continue;
    results.push(result);
    if (results.length >= 10) break;
  }

  return results;
}

async function fetchSearchPage(
  endpoint: (typeof SEARCH_ENDPOINTS)[number],
  query: string,
  signal: AbortSignal,
): Promise<string> {
  const timeoutSignal = AbortSignal.timeout(SEARCH_TIMEOUT_MS);
  const combinedSignal = AbortSignal.any([signal, timeoutSignal]);
  const response = await fetch(endpoint.url, {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded",
      "user-agent": "Mozilla/5.0 (compatible; pi-search/1.0)",
      accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "accept-language": "en-US,en;q=0.9",
      referer: endpoint.url,
    },
    body: endpoint.buildBody(query),
    redirect: "follow",
    signal: combinedSignal,
  });

  if (!response.ok) {
    throw new Error(`${endpoint.name} request failed: ${response.status} ${response.statusText}`);
  }

  return response.text();
}

async function searchWeb(query: string, maxResults: number, signal: AbortSignal): Promise<{ results: SearchResult[]; source: string }> {
  const errors: string[] = [];

  for (const endpoint of SEARCH_ENDPOINTS) {
    try {
      const html = await fetchSearchPage(endpoint, query, signal);
      const results = endpoint.parse(html).slice(0, maxResults);
      if (results.length > 0) {
        return { results, source: endpoint.name };
      }
      errors.push(`${endpoint.name}: no results parsed`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      errors.push(`${endpoint.name}: ${message}`);
    }
  }

  throw new Error(`All search providers failed. ${errors.join(" | ")}`);
}

function pickMainHtml(html: string): string {
  const sections = [
    /<main\b[^>]*>([\s\S]*?)<\/main>/i,
    /<article\b[^>]*>([\s\S]*?)<\/article>/i,
    /<body\b[^>]*>([\s\S]*?)<\/body>/i,
  ];

  for (const regex of sections) {
    const match = html.match(regex)?.[1];
    if (match && clean(match.replace(/<[^>]+>/g, " ")).length >= 200) {
      return match;
    }
  }

  return html;
}

function htmlToText(html: string): string {
  const stripped = pickMainHtml(html)
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
    .replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript>/gi, " ")
    .replace(/<svg\b[^>]*>[\s\S]*?<\/svg>/gi, " ")
    .replace(/<canvas\b[^>]*>[\s\S]*?<\/canvas>/gi, " ")
    .replace(/<template\b[^>]*>[\s\S]*?<\/template>/gi, " ")
    .replace(/<header\b[^>]*>[\s\S]*?<\/header>/gi, " ")
    .replace(/<footer\b[^>]*>[\s\S]*?<\/footer>/gi, " ")
    .replace(/<nav\b[^>]*>[\s\S]*?<\/nav>/gi, " ")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<li\b[^>]*>/gi, "\n- ")
    .replace(/<\/(p|div|section|article|main|aside|blockquote|h[1-6]|tr|ul|ol)>/gi, "\n")
    .replace(/<[^>]+>/g, " ");

  return decodeHtmlEntities(stripped)
    .replace(/\r/g, "")
    .split(/\n+/)
    .map((line) => clean(line))
    .filter(Boolean)
    .join("\n");
}

function extractMetaContent(html: string, name: string): string {
  const patterns = [
    new RegExp(`<meta[^>]+name=["']${name}["'][^>]+content=["']([^"']+)["'][^>]*>`, "i"),
    new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+name=["']${name}["'][^>]*>`, "i"),
    new RegExp(`<meta[^>]+property=["']${name}["'][^>]+content=["']([^"']+)["'][^>]*>`, "i"),
    new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${name}["'][^>]*>`, "i"),
  ];

  for (const pattern of patterns) {
    const match = html.match(pattern)?.[1];
    if (match) return clean(decodeHtmlEntities(match));
  }

  return "";
}

function extractTitle(html: string): string {
  const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? "";
  const ogTitle = extractMetaContent(html, "og:title");
  return clean(decodeHtmlEntities(ogTitle || titleMatch));
}

function ensureHttpUrl(input: string): URL {
  let parsed: URL;
  try {
    parsed = new URL(input);
  } catch {
    throw new Error(`Invalid URL: ${input}`);
  }

  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new Error("Only http:// and https:// URLs are supported.");
  }

  return parsed;
}

async function readPage(url: string, maxChars: number, signal: AbortSignal): Promise<PageResult> {
  const parsed = ensureHttpUrl(url);
  const response = await fetch(parsed.toString(), {
    method: "GET",
    headers: {
      "user-agent": "Mozilla/5.0 (compatible; pi-read-url/1.0)",
      accept: "text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.5",
    },
    redirect: "follow",
    signal,
  });

  if (!response.ok) {
    throw new Error(`Page request failed: ${response.status} ${response.statusText}`);
  }

  const contentType = response.headers.get("content-type") ?? "";
  const raw = await response.text();
  let text = "";
  let title = "";
  let description = "";

  if (contentType.includes("text/html") || contentType.includes("application/xhtml+xml") || contentType === "") {
    title = extractTitle(raw);
    description = extractMetaContent(raw, "description") || extractMetaContent(raw, "og:description");
    text = htmlToText(raw);
  } else if (contentType.startsWith("text/")) {
    text = raw
      .replace(/\r/g, "")
      .split(/\n+/)
      .map((line) => clean(decodeHtmlEntities(line)))
      .filter(Boolean)
      .join("\n");
  } else {
    throw new Error(`Unsupported content type: ${contentType}`);
  }

  const trimmedText = text.length > maxChars ? `${text.slice(0, maxChars - 1).trimEnd()}…` : text;
  return {
    url: parsed.toString(),
    finalUrl: response.url || parsed.toString(),
    title,
    description,
    contentType,
    text: trimmedText,
  };
}

function formatResults(query: string, results: SearchResult[]): string {
  if (results.length === 0) {
    return `No results found for "${query}".`;
  }

  const lines = [`Web search results for "${query}":`];
  results.forEach((result, index) => {
    lines.push(
      `${index + 1}. ${result.title}\n   ${result.url}${result.snippet ? `\n   ${result.snippet}` : ""}`,
    );
  });
  return lines.join("\n");
}

function formatPage(result: PageResult): string {
  const lines = [
    result.title ? `Title: ${result.title}` : "Title: (untitled)",
    `URL: ${result.finalUrl}`,
  ];

  if (result.description) {
    lines.push(`Description: ${result.description}`);
  }

  lines.push("", "Extracted page text:", result.text || "(No readable page text extracted.)");
  return lines.join("\n");
}

export default function webSearchExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description: "Search the public web and return ranked results with titles, URLs, and snippets.",
    promptSnippet: "Search the public web for current information, sources, and relevant pages.",
    promptGuidelines: [
      "Use web_search when the user asks for current, external, or source-backed information that is not reliably answerable from the local repository alone.",
      "Use web_search before making claims about news, product changes, pricing, docs, or facts that may have changed recently.",
      "Prefer web_search for identifying authoritative sources, then read the returned pages or cite the best matching result.",
      "If a query is ambiguous, use web_search with a focused query and mention the assumptions made.",
    ],
    parameters: SearchParams,
    async execute(_toolCallId, params, signal, onUpdate) {
      const query = clean(params.query);
      const maxResults = params.maxResults ?? MAX_RESULTS;

      onUpdate?.({ content: [{ type: "text", text: `Searching the web for: ${query}` }] });

      const { results, source } = await searchWeb(query, maxResults, signal);
      return {
        content: [{ type: "text", text: formatResults(query, results) }],
        details: { query, source, results },
      };
    },
  });

  pi.registerTool({
    name: "read_url",
    label: "Read URL",
    description: "Fetch a public web page and extract readable text content.",
    promptSnippet: "Fetch a public URL and extract the readable page text.",
    promptGuidelines: [
      "Use read_url after web_search when the user needs the content of a specific result, a source-backed quote, or details from an authoritative page.",
      "Use read_url only for public http:// or https:// pages; do not use it for local files or private network resources.",
    ],
    parameters: ReadPageParams,
    async execute(_toolCallId, params, signal, onUpdate) {
      const url = clean(params.url);
      const maxChars = params.maxChars ?? DEFAULT_PAGE_CHARS;

      onUpdate?.({ content: [{ type: "text", text: `Reading URL: ${url}` }] });

      const result = await readPage(url, maxChars, signal);
      return {
        content: [{ type: "text", text: formatPage(result) }],
        details: result,
      };
    },
  });
}
