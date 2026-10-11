# Journal des modifications

## v1.1

Pour le plugin Moodle 5.3. Ajout seulement : rien ne change pour les plugins Moodle 4.1 / 4.5,
qui continuent d'utiliser MathJax v2 — une même image sert les trois versions du plugin.

- **MathJax 4.1.3 hébergé localement** (`pg_files/mathjax-v4/`), même version que le filtre
  MathJax de Moodle 5.3, avec son paquet de polices (`pg_files/mathjax-v4/fonts/`, sinon cherché
  sur cdn.jsdelivr.net). Moodle 5 charge MathJax 4 et remplace `window.MathJax` : le plugin ne
  peut plus y charger MathJax v2 et réutilise l'instance de Moodle, chargée depuis cette copie.
  La construction vérifie la présence des trois chemins dont le plugin dépend.
- **Renderer amont épinglé** (`openwebwork/renderer` au commit `1134ffb`, 18 juin 2025, PG au
  commit `4b3e564`) dans le workflow de publication et dans les instructions de construction :
  les correctifs visent des fichiers précis de PG (noms à empreinte, ex.
  `mathview.91ad44d1.min.js`) et échoueraient sur une version amont plus récente.
- **Documentation** : section CORS (MathJax 4) dans `docs/INSTALLATION.md`, tableau de
  compatibilité image ↔ plugin dans le README.

## v1.0

Première version publiée, en deux variantes (`intl` et `fr`).

### Correctifs d'intégration (les deux variantes)

- **`patch_renderproblem.pl`** — ajoute le support de `useMathView`, absent du render-api du
  renderer standalone bien que pleinement supporté par `PG.pm`. Rend le paramètre `entryAssist`
  réellement fonctionnel (choix MathQuill / MathView / aucun éditeur, par question).
- **`patch_mathview.pl`** — compatibilité MathJax v2, sélecteur CSS invalide à cause du
  deux-points du préfixage de Moodle (bloquait le changement d'onglet de catégories), et
  traduction des chaînes codées en dur.
- **`patch_mathview_loop.pl`** — corrige une boucle infinie du `MutationObserver` bloquant
  complètement le navigateur sur les pages à questions multiples (relecture de tentative).
- **`patch_mv_locale.pl`** — `const` → `var` pour les globales de `mv_locale_us.js`, dont la
  redéclaration interrompait l'exécution JS de la page (menu Moodle invisible en cascade).
- **`patch_graphtool.pl`** — même incompatibilité MathJax v2 que MathView, plus traduction
  complète de l'interface de GraphTool.
- **TeX Live** — graphiques TikZ/LaTeX (`PGtikz.pl`, `PGlateximage.pl`), absents de l'image
  officielle amont.
- **MathJax v2 hébergé localement** — élimine la dépendance à un CDN externe, dont la lenteur ou
  l'indisponibilité laissait le LaTeX brut affiché sans aucune erreur visible.

### Francisation (variante `fr` seulement)

- **`patch_context.pl`** — ~185 messages du Parser/Value, jamais rendus traduisibles nativement
  dans PG (⚠️ non bilingue : toujours en français, même avec `language=en`).
- **`fr-CA.po`** — ~160 chaînes du système standard maketext/.po (bilingue).
- **`mv_locale_fr.js`** — MathView traduit, avec notation d'intervalle québécoise (`]a,b[`).
- **`patch_cofidaho.pl`**, **`patch_answerchecker.pl`** — messages macro-spécifiques, selon la
  politique de couverture incrémentale décrite dans [`docs/TRADUCTION.md`](docs/TRADUCTION.md).
