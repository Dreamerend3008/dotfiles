import { existsSync, mkdirSync, readFileSync, readdirSync, unlinkSync, writeFileSync } from "fs";
import { extname, isAbsolute, join, resolve } from "path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type InputImage = {
  type: "image";
  data: string;
  mimeType: string;
};

const CLIPBOARD_IMAGE_PATH = /(?<!\S)(@?)(\/tmp\/pi-clipboard-[^\s]+\.(?:png|jpe?g|webp|gif))(?!\S)/gi;
const ATTACHMENTS_DIR = join(process.env.HOME ?? "/home/harry", "attachments");

function mimeTypeForPath(path: string): string | null {
  switch (extname(path).toLowerCase()) {
    case ".png":
      return "image/png";
    case ".jpg":
    case ".jpeg":
      return "image/jpeg";
    case ".webp":
      return "image/webp";
    case ".gif":
      return "image/gif";
    default:
      return null;
  }
}

function extensionForMimeType(mimeType: string): string {
  switch (mimeType.toLowerCase()) {
    case "image/png":
      return ".png";
    case "image/jpeg":
      return ".jpg";
    case "image/webp":
      return ".webp";
    case "image/gif":
      return ".gif";
    default:
      return ".bin";
  }
}

function attachImage(path: string): InputImage | null {
  const mimeType = mimeTypeForPath(path);
  if (!mimeType || !existsSync(path)) return null;
  return {
    type: "image",
    data: readFileSync(path).toString("base64"),
    mimeType,
  };
}

function materializeImages(images: InputImage[]): string[] {
  mkdirSync(ATTACHMENTS_DIR, { recursive: true });

  for (const name of readdirSync(ATTACHMENTS_DIR)) {
    if (/^\d+\.(png|jpe?g|webp|gif|bin)$/i.test(name)) {
      try {
        unlinkSync(join(ATTACHMENTS_DIR, name));
      } catch {
        // ignore cleanup failures; active slots will still be written below
      }
    }
  }

  const written: string[] = [];

  for (let i = 0; i < images.length; i += 1) {
    const image = images[i];
    const ext = extensionForMimeType(image.mimeType);
    const fullPath = join(ATTACHMENTS_DIR, `${i}${ext}`);
    writeFileSync(fullPath, Buffer.from(image.data, "base64"));
    written.push(fullPath);
  }

  return written;
}

export default function clipboardImagePathExtension(pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    if (event.source === "extension") return { action: "continue" };

    const matches = Array.from(event.text.matchAll(CLIPBOARD_IMAGE_PATH));
    const seen = new Set<string>();
    const pastedImages: InputImage[] = [];

    for (const match of matches) {
      const rawPath = match[2];
      if (!rawPath) continue;
      const path = isAbsolute(rawPath) ? rawPath : resolve(ctx.cwd, rawPath);
      if (seen.has(path)) continue;
      seen.add(path);
      const image = attachImage(path);
      if (image) pastedImages.push(image);
    }

    const allImages = [...(event.images ?? []), ...pastedImages];
    if (allImages.length === 0) return { action: "continue" };

    const attachmentPaths = materializeImages(allImages);
    const cleanedText = event.text.replace(CLIPBOARD_IMAGE_PATH, "").replace(/\s{2,}/g, " ").trim();
    const nextText = [
      cleanedText.length > 0 ? cleanedText : "Please analyze the attached image.",
      attachmentPaths.length > 0
        ? `\n\nIf you need to inspect the image via tools, local copies are available at:\n${attachmentPaths.join("\n")}`
        : "",
    ]
      .join("")
      .trim();

    if (ctx.hasUI) {
      ctx.ui.notify(
        `Prepared ${allImages.length} image${allImages.length === 1 ? "" : "s"} for the model and mirrored them to ${ATTACHMENTS_DIR}.`,
        "info",
      );
    }

    return {
      action: "transform",
      text: nextText,
      images: allImages,
    };
  });
}
