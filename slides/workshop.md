---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: #fafafa;
    color: #1a1a1a;
    padding: 70px;
  }
  h1 { color: #0b6bcb; font-size: 1.8em; }
  h2 { color: #0b6bcb; }
  strong { color: #0b6bcb; }
  section.lead {
    text-align: center;
    justify-content: center;
  }
  section.lead h1 { font-size: 2.4em; }
  section.quote {
    text-align: center;
    justify-content: center;
  }
  section.quote h2 {
    font-size: 2em;
    color: #1a1a1a;
    font-weight: 500;
    font-style: italic;
  }
  section.quote p {
    color: #666;
    font-size: 0.9em;
  }
  footer { color: #999; }
  ul { line-height: 1.7; }
  section.procedure { padding: 22px 32px; }
  section.procedure h1 { font-size: 1.15em; margin: 0 0 10px; }
  .proc { display: flex; flex-direction: column; gap: 8px; }
  .proc .steptext {
    margin: 0;
    font-size: 0.66em;
    line-height: 1.3;
  }
  .proc code {
    background: #eef3f8;
    color: #0b6bcb;
    padding: 1px 5px;
    border-radius: 4px;
    font-size: 0.95em;
  }
  .proc .cards {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px 18px;
  }
  .proc .cards figure {
    margin: 0;
    display: flex;
    flex-direction: column;
  }
  .proc .cards figcaption {
    font-size: 0.62em;
    line-height: 1.25;
    margin-bottom: 4px;
    min-height: 2.4em;
  }
  .proc .cards img {
    width: 100%;
    height: 215px;
    object-fit: contain;
    object-position: center center;
    border: 1px solid #ddd;
    border-radius: 8px;
    background: #1a1a1a;
    box-shadow: 0 2px 8px rgba(0,0,0,0.12);
  }
---

<!-- _class: lead -->
<!-- _paginate: false -->

# Faire une petite appli avec une IA, sans coder

Johan Martinsson & Jean Dupuis

---

# Au programme

- **Intro** — ce qu'on va faire et pourquoi
- **Méthode** — comment travailler avec l'IA
- **Hands-on** — vous codez (avec l'IA)
- **Démo & échanges**

---

# On va développer une petite appli

- Open data, visualisation
- Chatbot
- Dépôt de demande
- Votre rêve…

---

# Pratique

- Appli sur GitHub
- Claude sur web (compte de prêt)
- Open source

<br>

**Pour faire pareil chez vous :**
créez un compte GitHub + un compte Claude / Copilot / OpenAI

---

# Pourquoi faire faire une appli aux non-devs ?

- Prototyper pour mieux définir
- Se familiariser avec un workflow IA-first
- Découvrir
- Ne plus être bloqué par la difficulté de coder

---

<!-- _class: quote -->

## « Ce sera pas dans les règles de l'art. »

Pas grave — si le fonctionnel est prometteur, on refait le code proprement.

---

# Comment travailler avec l'IA

**1.** Décrire ce qu'on veut construire
**2.** Itérer avec l'IA — tester, ajuster, préciser
**3.** Valider le résultat

<br>

*L'IA génère, vous guidez.*

---

<!-- _class: procedure -->

# The procedure — step by step

<div class="proc">

<p class="steptext"><b>1.</b> Go to <a href="https://www.changit.fr/AI-kata-non-dev-group1/"><strong>www.changit.fr/AI-kata-non-dev-group<u>N</u></strong></a> (<u>N</u> = your group number)</p>

<div class="cards">
<figure><figcaption><b>2.</b> Go to <strong>claude.ai/code</strong> and enter your email</figcaption><img src="images/step2-email.png" alt="Enter email"></figure>
<figure><figcaption><b>3.</b> Get the <strong>verification code</strong> sent to your email</figcaption><img src="images/step3-code.png" alt="Verification code"></figure>
<figure><figcaption><b>4.</b> Select the <strong>right project</strong> (your group)</figcaption><img src="images/step4-repo-zoom.png" alt="Select project"></figure>
<figure><figcaption><b>5.</b> Ask for a change <strong>like this one</strong>:</figcaption><img src="images/step5-instructions.png" alt="Instruction in the chat"></figure>
</div>

</div>
