import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_provider_request", (event, ctx) => {
    if (ctx.model?.provider !== "azure-foundry") return;

    const payload = event.payload as { input?: unknown[] };
    if (!Array.isArray(payload.input)) return;

    return {
      ...payload,
      input: payload.input.map((item) =>
        item && typeof item === "object" && "role" in item && !("type" in item)
          ? { type: "message", ...item }
          : item,
      ),
    };
  });
}
