import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const SEARCH_ENDPOINT = "https://html.duckduckgo.com/html/";
const MAX_RESULTS = 8;
const MAX_QUERY_LENGTH = 500;
const MAX_SNIPPET_LENGTH = 280;
const MAX_TITLE_LENGTH = 120;

const SearchParams = Type.Object({
  query: Type.String({ minLength: 1, maxLength: MAX_QUERY_LENGTH, description: "Search query" }),
  maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 10, default: MAX_RESULTS })),
});

type SearchResult = {
  title: string;
  url: string;
  snippet: string;
  source: string;
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
    return uddg ? decodeURIComponent(uddg) : url;
  } catch {
    return url;
  }
}

function extractResults(html: string): SearchResult[] {
  const results: SearchResult[] = [];
  const blockRegex = /<div class="result results_links results_links_deep web-result"[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/g;
  const blocks = html.match(blockRegex) ?? [];

  for (const block of blocks) {
    const linkMatch = block.match(/<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/);
    if (!linkMatch) continue;

    const url = decodeDuckDuckGoUrl(linkMatch[1]);
    const title = trunc(linkMatch[2].replace(/<[^>]+>/g, " "), MAX_TITLE_LENGTH);
    const snippetMatch = block.match(/<a[^>]+class="result__snippet"[^>]*>([\s\S]*?)<\/a>/);
    const snippet = trunc((snippetMatch?.[1] ?? "").replace(/<[^>]+>/g, " "), MAX_SNIPPET_LENGTH);

    if (!title || !url) continue;
    results.push({ title, url, snippet, source: "DuckDuckGo" });
    if (results.length >= 10) break;
  }

  return results;
}

async function searchWeb(query: string, maxResults: number, signal: AbortSignal): Promise<SearchResult[]> {
  const body = new URLSearchParams({ q: query, kl: "us-en", kp: "-1" });
  const response = await fetch(SEARCH_ENDPOINT, {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded",
      "user-agent": "Mozilla/5.0 (compatible; pi-search/1.0)",
      accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
    body,
    signal,
  });

  if (!response.ok) {
    throw new Error(`Search request failed: ${response.status} ${response.statusText}`);
  }

  const html = await response.text();
  return extractResults(html).slice(0, maxResults);
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

      const results = await searchWeb(query, maxResults, signal);
      return {
        content: [{ type: "text", text: formatResults(query, results) }],
        details: { query, results },
      };
    },
  });
}
