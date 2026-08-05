# Traduction (fr-CA)

Ce document décrit les mécanismes de traduction utilisés par la variante `fr`
(voir [`Dockerfile.fr`](../Dockerfile.fr)) et comment contribuer de nouvelles traductions.


Deux mécanismes distincts, avec un comportement différent qu'il est important de comprendre :

| | `fr-CA.po` | `patch_context.pl` (Value/Context.pm) |
|---|---|---|
| **Mécanisme** | Système standard `maketext`/`.po` de WeBWorK | Table `$context->{error}{msg}`, propre au Parser bas niveau |
| **Couvre** | Messages généraux (Correct, Erroné, Indice, Solution, Aperçu, etc. — env. 160 chaînes) | Messages techniques du moteur d'analyse (~185 messages : "Variable non définie", "Parenthèse en trop", erreurs de types, etc.) |
| **Respecte `language=en`?** | ✅ Oui — bascule en anglais si Moodle le demande | ❌ Non — **toujours en français**, peu importe le paramètre envoyé |

Concrètement : si votre institution a besoin d'une expérience **réellement bilingue**, sachez
que les messages techniques du Parser resteront toujours en français avec cette image, même
pour un utilisateur anglophone. Pour une installation strictement anglophone/internationale,
utilisez la variante `intl` (voir le [README principal](../README.md)).

### Éditeurs d'aide à la saisie : MathQuill / MathView / Aucun

Depuis `patch_renderproblem.pl`, le choix entre MathQuill, MathView, et aucun éditeur assisté
est surchargeable **par requête** (donc par question, configuré dans le plugin Moodle — voir
[son README](https://github.com/JonathanDesaulniers/moodle-qtype_webwork)), via le paramètre `entryAssist` du render-api :
- `entryAssist=MathQuill` (ou absent) → MathQuill
- `entryAssist=MathView` → MathView (traduit en français, notation d'intervalle québécoise ]a,b[)
- toute autre valeur (ex. `None`) → aucun éditeur assisté (champ texte brut)

`patch_mathview.pl` corrige aussi trois bogues distincts propres à MathView dans ce contexte
d'intégration (incompatibilité MathJax v3, sélecteur CSS invalide à cause du deux-points de
Moodle, chaînes anglaises codées en dur) — voir les commentaires du script pour le détail.

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
- `mv_locale_fr.js` : traduction complète du fichier de catégories/info-bulles de MathView
  (`mv_locale_us.js`), avec notation d'intervalle adaptée au Québec.

### Mettre à jour les traductions

Si vous voulez ajouter/corriger des traductions, éditez `fr-CA.po` (format `.po` standard),
`patch_context.pl` (dictionnaire Perl dans la section `HASHBODY_END`), ou tout autre
`patch_*.pl` pertinent, puis reconstruisez l'image. Contributions bienvenues via pull request !
