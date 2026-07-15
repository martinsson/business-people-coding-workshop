# Appeler un vrai LLM depuis une appli d'atelier

Les applis sont 100 % statiques (GitHub Pages) : pas de backend, donc **une clé API
mise dans le code serait publique**. Deux approches, de la plus simple à la plus
robuste.

## 1. Sans clé (recommandé pour l'atelier)

[`assets/llm.js`](../assets/llm.js) appelle [Pollinations](https://pollinations.ai),
un endpoint **gratuit, sans clé, et compatible CORS** (`Access-Control-Allow-Origin: *`).
Il fonctionne directement depuis une page statique.

```html
<script src="llm.js"></script>
<script>
  const reponse = await askLLM("Donne-moi une recette rapide avec des œufs.");
  // avec une consigne système :
  const r = await askLLM("Résume ce texte.", { system: "Réponds en une phrase, en français." });
</script>
```

Pas de fichier à inclure ? Le minimum vital tient en une fonction à coller :

```js
async function askLLM(prompt) {
  const res = await fetch("https://text.pollinations.ai/" + encodeURIComponent(prompt));
  return (await res.text()).trim();
}
```

Démo prête à ouvrir : [`assets/llm-demo.html`](../assets/llm-demo.html).

> ⚠️ **C'est un service public gratuit.** Débit limité, qualité variable, et il peut
> ralentir ou disparaître sans préavis. Parfait pour une démo d'atelier ; à ne pas
> utiliser pour quelque chose dont vous dépendez.

## 2. Avec une vraie clé, gardée secrète (pour aller plus loin)

Pour un fournisseur « sérieux » (OpenAI, Anthropic, …) sans exposer la clé, placez un
**petit proxy** entre l'appli et le fournisseur. Le plus simple ici : un **Cloudflare
Worker** (vous utilisez déjà Wrangler).

```js
// worker.js — déployé sur changit.fr/llm, la clé reste dans le secret du Worker
export default {
  async fetch(req, env) {
    const { prompt } = await req.json();
    const r = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${env.OPENAI_KEY}` },
      body: JSON.stringify({ model: "gpt-4o-mini", messages: [{ role: "user", content: prompt }] }),
    });
    const d = await r.json();
    return new Response(d.choices[0].message.content, {
      headers: { "Access-Control-Allow-Origin": "*" },
    });
  },
};
```

```bash
wrangler secret put OPENAI_KEY   # la clé n'est jamais dans le code de l'appli
wrangler deploy
```

L'appli appelle alors `fetch("https://changit.fr/llm", { method: "POST", body: JSON.stringify({ prompt }) })`.
La clé reste côté serveur, vous maîtrisez la dépense, et le débit est fiable.
