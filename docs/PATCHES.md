# Les correctifs, un par un

Chaque script du dossier [`patches/`](../patches/) corrige un problème précis, rencontré en
conditions réelles lors de l'intégration du Standalone Renderer dans Moodle. Ils sont tous
idempotents dans l'esprit (ils échouent bruyamment si le motif attendu est absent, plutôt que de
modifier silencieusement la mauvaise chose) et commentés en détail dans leur en-tête.

## Correctifs d'intégration (variante `intl` et `fr`)

Ces correctifs n'ont **rien à voir avec la langue** — ils corrigent de vrais bogues qui se
manifestent dès qu'un problème WeBWorK est affiché hors de son contexte d'origine (une page
WeBWorK complète, un seul problème à la fois) et dans une page Moodle (plusieurs questions,
préfixes de nommage particuliers).

### `patch_renderproblem.pl`

Ajoute le support de `useMathView` à `RenderProblem.pm`. Le renderer calculait et transmettait
`useMathQuill` à `PG.pm`, mais jamais `useMathView` — alors que `PG.pm` le supporte pleinement.
Simple oubli de branchement côté renderer.

**Effet** : le paramètre `entryAssist` du render-api devient réellement fonctionnel, permettant
de choisir MathQuill / MathView / aucun éditeur assisté **par requête** (donc par question, via
le réglage correspondant du plugin Moodle).

### `patch_mathview.pl`

Trois correctifs distincts dans `mathview.js` :

1. **Compatibilité MathJax v2/v3** — le fichier accède directement à `MathJax.startup.promise`
   (propre à la v3, et toujours présent en v4) sans vérification, alors que le plugin pour
   Moodle 4.x charge volontairement MathJax v2 (plus tolérant dans un contexte de fragment de
   page). L'ancienne version de ce même fichier avait cette vérification ; elle a disparu en
   amont. Le plugin pour Moodle 5.3 utilise MathJax 4 et passe donc par la branche v3 du
   correctif, qui reste nécessaire pour les plugins 4.x.
2. **Sélecteur CSS invalide** — l'identifiant du champ est réutilisé tel quel comme sélecteur
   CSS Bootstrap, mais le préfixe de nommage de Moodle contient un **deux-points** (ex.
   `q440:1_AnSwEr0001`), syntaxiquement invalide dans un sélecteur. Résultat : le changement
   d'onglet de catégories restait silencieusement bloqué sur « Basic ».
3. **Chaînes codées en dur** — traduit `Equation Editor`, `Insert`, `Clear`, absents du fichier
   de locale. Sans effet notable en usage anglophone.
4. **Position du curseur après insertion** — MathView place le curseur après la première
   ouverture trouvée par `/\(\)|\[,|\(,/`. Les intervalles en notation québécoise de
   `mv_locale_fr.js` (`],]`, `],[`) commencent par `]` : le curseur restait devant le modèle
   inséré. `\],` est ajouté à l'expression ; sans effet sur la notation anglaise.
5. **Libellé du bouton de sections** — MathView y écrivait une fois pour toutes le libellé fixe
   `mathView_translator[12]` (« Operations »/« Opérations ») et ne le mettait jamais à jour : en
   français, il se lisait comme le nom d'une section, même dans « Intervalles ». Le bouton affiche
   maintenant la section active (la première au départ, puis celle choisie).

### `patch_mathview_loop.pl`

Corrige une **boucle infinie** qui bloque complètement le navigateur (« la page ne répond pas »).

Le garde-fou anti-réinitialisation (`mvInitialized`) n'est vérifié que pour l'élément
*directement* ajouté au DOM — pas pour les éléments retrouvés via `querySelectorAll`, ni dans les
boucles de scan initial. Sur une page affichant plusieurs questions à la fois (typiquement la
page de relecture d'une tentative de quiz), MathView se réinitialise donc indéfiniment sur les
mêmes champs.

### `patch_mv_locale.pl`

Convertit les déclarations globales `const mathView_translator` / `const mv_categories` en `var`.
`const` ne tolère aucune redéclaration : si le script s'exécute plus d'une fois sur la même page,
l'erreur `Identifier '...' has already been declared` interrompt l'exécution — et en cascade,
empêche du JavaScript de Moodle plus loin sur la page de s'exécuter (symptôme observé : menu de
navigation de Moodle devenu invisible).

### `patch_graphtool.pl`

Même incompatibilité MathJax v2/v3 que MathView : `window.MathJax &&` vérifie bien l'existence de
l'objet, mais accède ensuite directement à `.startup.promise`. Le plantage survenait tôt dans le
chargement, empêchant d'autres scripts de la page de s'exécuter (dont le rendu MathJax de
l'énoncé).

Traduit aussi l'interface complète de GraphTool (boutons, info-bulles, messages d'aide
contextuelle) — sans effet notable en anglais.

## Correctifs de francisation (variante `fr` seulement)

Voir [`TRADUCTION.md`](TRADUCTION.md) pour le détail des deux mécanismes de traduction de WeBWorK
et de leurs comportements respectifs face au paramètre `language`.

- **`patch_context.pl`** — ~185 messages du Parser/Value (`$context->{error}{msg}`)
- **`fr-CA.po`** — ~160 chaînes du système standard maketext/.po de **PG**
  (`lib/PG/lib/WeBWorK/PG/Localize/`)
- **`fr-CA.renderer.po`** — catalogue **propre au renderer** (`lib/WeBWorK/Localize/`), lu par
  ses gabarits `RPCRenderFormats/default.*.ep` (« You received a score of X% for this
  attempt. », boutons) : tout `standalone.pot` traduit, plus les chaînes du gabarit absentes du
  `.pot`
- **`mv_locale_fr.js`** — catégories et info-bulles de MathView ; intervalles en notation
  québécoise à l'affichage **et** à l'insertion (`],]`, `[,[`, `],[`)
- **`patch_cofidaho.pl`** — messages de `CofIdaho_macros.pl`
- **`patch_answerchecker.pl`** — message dynamique construit par `cmp_class()`/`showClass()`

## Attention au cache du navigateur

Les fichiers JavaScript patchés gardent **exactement le même nom** d'une reconstruction à l'autre
(ex. `mathview.91ad44d1.min.js`). Après toute reconstruction, **videz le cache du navigateur**
avant de tester (clic droit sur le bouton de rechargement → « Vider le cache et effectuer une
actualisation forcée »), sinon le navigateur continuera à servir l'ancienne version
indéfiniment — un piège qui peut coûter des heures de débogage.

Le renderer n'envoie aucun en-tête `Cache-Control` : le navigateur peut réutiliser sa copie
pendant des heures sans la redemander. Pour éviter le problème chez les utilisateurs, ajoutez
dans le Caddyfile (voir le README du plugin) :

```
header /pg_files/* Cache-Control no-cache
```

Le navigateur revalide alors ces fichiers à chaque page (réponse 304 s'ils n'ont pas changé).
⚠️ Si le Caddyfile est monté en fichier unique (`-v ~/Caddyfile:/etc/caddy/Caddyfile`), ne le
modifiez pas avec `sed -i` (le conteneur garderait l'ancien fichier) : éditez-le en place, puis
`docker exec webwork-caddy caddy reload --config /etc/caddy/Caddyfile`.
