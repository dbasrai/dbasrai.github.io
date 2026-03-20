import http from "http";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { chromium } from "playwright";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");
const siteDir = path.join(repoRoot, "_site");

const urlPath = "/cv-full/"; // Hidden full CV page.
const outPdfPath = path.join(siteDir, "research", "cv.pdf");

function contentTypeFor(urlPathname) {
  const lower = urlPathname.toLowerCase();
  if (lower.endsWith(".html") || lower.endsWith(".htm")) return "text/html; charset=utf-8";
  if (lower.endsWith(".css")) return "text/css; charset=utf-8";
  if (lower.endsWith(".js")) return "application/javascript; charset=utf-8";
  if (lower.endsWith(".json")) return "application/json; charset=utf-8";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".svg")) return "image/svg+xml";
  if (lower.endsWith(".woff2")) return "font/woff2";
  if (lower.endsWith(".woff")) return "font/woff";
  if (lower.endsWith(".ttf")) return "font/ttf";
  if (lower.endsWith(".map")) return "application/json; charset=utf-8";
  if (lower.endsWith(".ico")) return "image/x-icon";
  return "application/octet-stream";
}

function serveStatic(rootDir) {
  const server = http.createServer((req, res) => {
    try {
      const reqUrl = new URL(req.url, "http://localhost");
      let pathname = decodeURIComponent(reqUrl.pathname);

      // Prevent path traversal.
      if (pathname.includes("..")) {
        res.statusCode = 400;
        res.end("Bad Request");
        return;
      }

      if (pathname === "/") pathname = "/index.html";

      // If request points to a directory, default to index.html.
      const fullPath = path.join(rootDir, pathname);
      let resolvedPath = fullPath;
      if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
        resolvedPath = path.join(fullPath, "index.html");
      }

      if (!fs.existsSync(resolvedPath)) {
        res.statusCode = 404;
        res.end("Not Found");
        return;
      }

      const stat = fs.statSync(resolvedPath);
      res.statusCode = 200;
      res.setHeader("Content-Length", stat.size);
      res.setHeader("Content-Type", contentTypeFor(resolvedPath));
      fs.createReadStream(resolvedPath).pipe(res);
    } catch (e) {
      res.statusCode = 500;
      res.end("Internal Server Error");
    }
  });

  return server;
}

async function main() {
  if (!fs.existsSync(siteDir)) {
    throw new Error(`_site directory not found at: ${siteDir}`);
  }

  fs.mkdirSync(path.dirname(outPdfPath), { recursive: true });

  const server = serveStatic(siteDir);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));

  const address = server.address();
  const port = address.port;
  const baseUrl = `http://127.0.0.1:${port}`;
  const targetUrl = `${baseUrl}${urlPath}`;

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 900 } });

  // Ensure we get a consistent (light) theme in the PDF.
  await page.addInitScript(() => {
    try {
      localStorage.setItem("theme", "light");
    } catch (_) {
      // ignore
    }
  });

  await page.goto(targetUrl, { waitUntil: "networkidle" });

  // Hide site chrome for cleaner PDF output.
  await page.addStyleTag({
    content: `
      #navbar, footer { display: none !important; }
      body { background: white !important; color: black !important; }
    `,
  });

  // Ensure the page isn't blank due to initial CSS state.
  await page.evaluate(() => {
    try {
      document.body.style.display = "block";
    } catch (_) {
      // ignore
    }
  });

  // Wait for the CV content to exist (best-effort).
  await page.waitForSelector("h1, h2, h3", { timeout: 10_000 }).catch(() => {});

  await page.waitForTimeout(500); // Let layout settle.
  await page.pdf({
    path: outPdfPath,
    format: "Letter",
    printBackground: true,
  });

  const exists = fs.existsSync(outPdfPath);
  const size = exists ? fs.statSync(outPdfPath).size : 0;
  // eslint-disable-next-line no-console
  console.log(`PDF exists=${exists} sizeBytes=${size}`);

  await browser.close();
  await new Promise((resolve) => server.close(resolve));

  // eslint-disable-next-line no-console
  console.log(`Wrote PDF: ${outPdfPath}`);
}

await main();

