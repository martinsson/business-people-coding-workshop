// llm.js — call a real LLM from a static workshop app, with NO API key.
//
// Uses Pollinations (https://pollinations.ai), a free, keyless, CORS-enabled
// endpoint (Access-Control-Allow-Origin: *), so it works straight from a static
// page on GitHub Pages — no backend, no token.
//
// ⚠️  It's a free public service: rate limits and uptime are NOT guaranteed, and
//     it can change or disappear. Great for a workshop demo; for anything you rely
//     on, front a real provider with your own proxy — see docs/LLM-FOR-APPS.md.
//
// Usage:
//   <script src="llm.js"></script>
//   const reply = await askLLM("Donne-moi une recette rapide avec des œufs.");
//   // with a system instruction:
//   const reply = await askLLM("Résume ce texte.", { system: "Tu réponds en français, en une phrase." });
//
async function askLLM(prompt, opts = {}) {
  const messages = [];
  if (opts.system) messages.push({ role: "system", content: opts.system });
  messages.push({ role: "user", content: String(prompt) });

  const res = await fetch("https://text.pollinations.ai/openai", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ model: opts.model || "openai", messages }),
  });
  if (!res.ok) throw new Error("LLM request failed (" + res.status + ")");
  const data = await res.json();
  return (data.choices && data.choices[0] && data.choices[0].message.content || "").trim();
}

// Simplest possible call: a plain-text GET. Handy for a one-liner with no options.
async function askLLMSimple(prompt) {
  const res = await fetch("https://text.pollinations.ai/" + encodeURIComponent(String(prompt)));
  if (!res.ok) throw new Error("LLM request failed (" + res.status + ")");
  return (await res.text()).trim();
}

if (typeof window !== "undefined") { window.askLLM = askLLM; window.askLLMSimple = askLLMSimple; }
