# Traduction (fr-CA)

Ce document décrit les mécanismes de traduction utilisés par la variante `fr`
(voir [`Dockerfile.fr`](../Dockerfile.fr)) et comment contribuer de nouvelles traductions.


Trois mécanismes distincts, avec un comportement différent qu'il est important de comprendre :

| | `fr-CA.po` (PG) | `fr-CA.renderer.po` (renderer) | `patch_context.pl` (Value/Context.pm) |
|---|---|---|---|
| **Mécanisme** | Système `maketext`/`.po` de **PG** (`lib/PG/lib/WeBWorK/PG/Localize/`) | Système `maketext`/`.po` **du renderer** (`lib/WeBWorK/Localize/`), utilisé par ses gabarits `RPCRenderFormats/default.*.ep` | Table `$context->{error}{msg}`, propre au Parser bas niveau |
| **Couvre** | Messages généraux (Correct, Erroné, Indice, Solution, Aperçu, crédit partiel… — env. 160 chaînes) | Texte autour du problème : « Vous avez obtenu un résultat de X % pour cette tentative. », boutons (~60 chaînes) | Messages techniques du moteur d'analyse (~185 messages : "Variable non définie", "Parenthèse en trop", erreurs de types, etc.) |
| **Respecte `language=en`?** | ✅ Oui — bascule en anglais si Moodle le demande | ✅ Oui | ❌ Non — **toujours en français**, peu importe le paramètre envoyé |

Les deux catalogues `.po` ne se remplacent pas : une chaîne du gabarit du renderer ajoutée au
`.po` de PG n'a **aucun** effet (constaté). Pour savoir lequel compléter, cherchez d'où vient le
message : un `maketext` dans `templates/` ou `lib/RenderApp` → `fr-CA.renderer.po` ; dans
`lib/PG/` → `fr-CA.po`.

La langue est **figée dans chaque tentative** : le `problemJWT` (chiffré, dans le `sessionJWT`)
reprend les paramètres du premier rendu, langue comprise. Un changement du réglage `language`
du plugin ne touche que les tentatives commencées ensuite.

Concrètement : si votre institution a besoin d'une expérience **réellement bilingue**, sachez
que les messages techniques du Parser resteront toujours en français avec cette image, même
pour un utilisateur anglophone. Pour une installation strictement anglophone/internationale,
utilisez la variante `intl` (voir le [README principal](../README.md)).

### Éditeurs d'aide à la saisie : MathQuill / MathView / Aucun

Depuis `patch_renderproblem.pl`, le choix entre MathQuill, MathView, et aucun éditeur assisté
est surchargeable **par requête** (donc par question, configuré dans le plugin Moodle — voir
[son README](https://github.com/JonathanDesaulniers2/moodle-qtype_webwork)), via le paramètre `entryAssist` du render-api :
- `entryAssist=MathQuill` (ou absent) → MathQuill
- `entryAssist=MathView` → MathView (traduit en français, notation d'intervalle québécoise ]a,b[)
- toute autre valeur (ex. `None`) → aucun éditeur assisté (champ texte brut)

**Intervalles en notation québécoise.** Les boutons d'intervalles de MathView affichent **et
insèrent** `]a,b]`, `[a,b[`, `]a,b[`. PG ne lit cette notation que dans les problèmes qui
chargent `contextAlternateIntervals.pl` (`Context("AlternateIntervals")`, fourni par PG) ; dans
un problème en `Context("Interval")` standard, `]2,4]` est refusé et l'étudiant doit taper
`(2,4]`. `contextAlternateDecimal.pl` (virgule décimale) est aussi fourni par PG. Ces contextes
ne sont **pas** activés globalement (`parserCustomization.pl`) : avec la virgule décimale partout,
un problème écrivant `Compute("(2,4]")` ne se rend plus du tout (`2,4` lu comme 2,4). Dans un
problème qui charge les deux contextes, un intervalle s'écrit `]2;4]` (point-virgule).

`patch_mathview.pl` corrige aussi cinq bogues distincts propres à MathView dans ce contexte
d'intégration (incompatibilité MathJax v3, sélecteur CSS invalide à cause du deux-points de
Moodle, chaînes anglaises codées en dur, curseur après un « ] » ouvrant, libellé figé du bouton
de sections) — voir [`PATCHES.md`](PATCHES.md) et les commentaires du script.

`patch_mathview_loop.pl` corrige un bogue distinct, plus sérieux : le garde-fou anti-réinitialisation
de MathView (`mvInitialized`) ne protège que l'élément directement ajouté au DOM, pas les éléments
retrouvés via `querySelectorAll` dans son `MutationObserver` — ce qui cause une réinitialisation en
boucle infinie sur une page affichant **plusieurs questions à la fois** (ex. la page de relecture
d'une tentative de quiz), bloquant complètement le navigateur. Un deuxième correctif, côté plugin
Moodle, marque préventivement les champs des questions n'utilisant pas MathView pour que son scan
initial les ignore (nécessaire quand une page mélange plusieurs réglages `entryAssist`).

⚠️ **Après toute reconstruction touchant un fichier JS déjà servi une fois** (`mathview.*.min.js`,
`graphtool.*.min.js`, etc.), videz le cache du navigateur avant de tester (clic droit sur le bouton
de rechargement → « Vider le cache et effectuer une actualisation forcée ») — sinon Chrome peut
continuer à servir l'ancienne version en cache indéfiniment, puisque le nom de fichier ne change
pas d'une reconstruction à l'autre.

### Couverture incrémentale des messages macro-spécifiques

Au-delà du noyau Parser/Value (`patch_context.pl`) et du système `.po` (`fr-CA.po`), WeBWorK a
des **centaines** de fichiers macro, chacun pouvant définir ses propres messages d'erreur via
des conventions variées (`$ans_hash->setKeys('ans_message' => "...")`, chaînes assemblées
dynamiquement à partir de `cmp_class()`/`showClass()`, etc.) — voir `patch_cofidaho.pl` et
`patch_answerchecker.pl` pour deux exemples concrets déjà traités.

**Traduire l'intégralité de ces messages à l'avance serait disproportionné.** La politique de ce
projet est plutôt une **couverture incrémentale** : chaque fois qu'un message non traduit
apparaît dans un problème réellement utilisé, on ajoute un correctif ciblé pour ce fichier
précis (en traduisant TOUT son contenu pertinent d'un coup, pas seulement le message
rencontré), plutôt que de deviner ce qui pourrait manquer. Cette liste de correctifs grandit
donc naturellement avec l'usage réel de l'institution.

### D'où viennent ces fichiers ?

- `fr-CA.po` : basé sur les fichiers `en.po`/`fr-CA.po` du dépôt
  [openwebwork/pg](https://github.com/openwebwork/pg/tree/main/lib/WeBWorK/PG/Localize),
  complété pour couvrir 100% des chaînes traduisibles connues (comparaison systématique avec
  `en.po`).
- `patch_context.pl` : les messages traduits ont été localisés en cherchant tous les
  appels `Value::Error(...)` / `->Error(...)` dans `lib/Parser/`, `lib/Value/`, et `lib/*.pm`
  du renderer. Ces messages n'ont **jamais** été rendus traduisibles nativement dans PG — ce
  correctif comble cette lacune sans modifier le comportement du moteur d'analyse lui-même
  (seul le texte du message change).
- `fr-CA.renderer.po` : traduction de
  [`lib/WeBWorK/Localize/standalone.pot`](https://github.com/openwebwork/renderer/tree/main/lib/WeBWorK/Localize)
  du renderer amont (qui n'a pas de français), plus « You received a score of %1 for this
  attempt. », utilisé par les gabarits mais absent du `.pot`.
- `mv_locale_fr.js` : traduction complète du fichier de catégories/info-bulles de MathView
  (`mv_locale_us.js`), avec notation d'intervalle adaptée au Québec.

### Mettre à jour les traductions

Si vous voulez ajouter/corriger des traductions, éditez `fr-CA.po` ou `fr-CA.renderer.po`
(format `.po` standard),
`patch_context.pl` (dictionnaire Perl dans la section `HASHBODY_END`), ou tout autre
`patch_*.pl` pertinent, puis reconstruisez l'image. Contributions bienvenues via pull request !
