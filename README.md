# WeBWorK Standalone Renderer — images prêtes pour Moodle

Images Docker du [Standalone Renderer](https://github.com/openwebwork/renderer) de WeBWorK,
préparées pour fonctionner avec le plugin Moodle
[qtype_webwork](https://github.com/JonathanDesaulniers2/moodle-qtype_webwork).

Deux variantes sont disponibles :

| Variante | Contenu | Pour qui |
|---|---|---|
| **`intl`** | TeX Live, MathJax v2 et MathJax 4 locaux, correctifs d'intégration Moodle | Installations anglophones ou réellement bilingues |
| **`fr`** | Tout ce qui précède **+ francisation complète (fr-CA)** | Institutions francophones (Québec) |

**Compatibilité avec le plugin** : une même image sert les trois versions du plugin
[qtype_webwork](https://github.com/JonathanDesaulniers2/moodle-qtype_webwork#plugins-moodle--webwork).

| Plugin pour… | Image du renderer | Pourquoi |
|---|---|---|
| Moodle 4.1 / 4.5 | v1.0 ou plus | MathJax v2 (`pg_files/mathjax-v2/`) |
| Moodle 5.3 | **v1.1 ou plus** | MathJax 4 (`pg_files/mathjax-v4/`), seule version compatible avec celle de Moodle 5 |

La variante `fr` est construite **par-dessus** `intl` : les correctifs d'intégration (bogues
réels de MathQuill/MathView/GraphTool en contexte multi-questions) sont communs aux deux, seules
les traductions les distinguent.

## Utiliser une image pré-construite (le plus simple)

```bash
# Variante française
docker pull ghcr.io/jonathandesaulniers2/webwork-renderer:fr

# Variante internationale
docker pull ghcr.io/jonathandesaulniers2/webwork-renderer:intl
```

Puis lancez le conteneur (adaptez les chemins) :

```bash
# Bibliothèque de problèmes et dossier privé (à cloner/créer une fois)
git clone https://github.com/openwebwork/webwork-open-problem-library \
  volumes/webwork-open-problem-library
mkdir -p private

sudo docker run -d \
  --name standalone-renderer \
  --restart unless-stopped \
  --publish 3000:3000 \
  --mount type=bind,source="$(pwd)"/volumes/webwork-open-problem-library/,target=/usr/app/webwork-open-problem-library \
  --mount type=bind,source="$(pwd)"/private/,target=/usr/app/private \
  --env MOJO_MODE=development \
  ghcr.io/jonathandesaulniers2/webwork-renderer:fr
```

## Construire soi-même

Utile pour auditer les correctifs, en ajouter, ou adapter les traductions.

```bash
# 1. Image de base officielle (amont), à la version sur laquelle les correctifs ont été mis au
#    point -- ils visent des fichiers précis de PG et échoueraient sur une version plus récente
git clone https://github.com/openwebwork/renderer container/
git -C container checkout 1134ffbbf5e656148e579f424f70bcd9f1d15936
git -C container submodule update --init --recursive
docker build --tag renderer:1.0 ./container

# 2. Variante internationale
docker build --no-cache --tag webwork-renderer:intl --file Dockerfile.intl .

# 3. (optionnel) Variante française, PAR-DESSUS l'internationale
docker build --no-cache --tag webwork-renderer:fr --file Dockerfile.fr .
```

⚠️ **`--no-cache` est important** : le cache Docker peut réutiliser silencieusement une couche
d'une construction précédente portant le même nom d'étape mais un contenu différent, faisant
échouer les correctifs suivants de façon très déroutante à diagnostiquer.

## ⚠️ Ne jamais redémarrer ce conteneur

**N'utilisez jamais `docker restart` ou `docker exec ... kill -USR2` sur ce conteneur.**
`hypnotoad` (le serveur applicatif du renderer) a un mécanisme de rechargement à chaud qui entre
en conflit avec la façon dont Docker gère le PID 1 : le nouveau code se charge correctement, mais
l'ancien processus manager se termine ensuite normalement — et comme le PID 1 du conteneur
attendait justement CE processus, tout le conteneur s'arrête.

**Pour appliquer un changement, recréez toujours le conteneur au complet** (`docker stop` +
`docker rm` + nouveau `docker run`).

## Documentation détaillée

- [`docs/INSTALLATION.md`](docs/INSTALLATION.md) — pare-feu, CORS (MathJax 4), HTTPS/Caddy, certificats
- [`docs/PATCHES.md`](docs/PATCHES.md) — ce que fait chaque correctif, et pourquoi
- [`docs/TRADUCTION.md`](docs/TRADUCTION.md) — les deux mécanismes de traduction, et comment
  contribuer de nouvelles traductions

## Auteur

**Modifié par Jonathan Desaulniers** — correctifs d'intégration à Moodle, francisation (fr-CA)
et images Docker, à partir du [WeBWorK Standalone Renderer](https://github.com/openwebwork/renderer)
et de [PG](https://github.com/openwebwork/pg) du projet WeBWorK.

Claude Code d'Anthropic a été utilisé dans la programmation du renderer.

## Licence

Voir [`LICENSE`](LICENSE). Ces images redistribuent :
- [WeBWorK / PG](https://github.com/openwebwork) — licence GPL
- [MathJax](https://github.com/mathjax/MathJax) — licence Apache 2.0
- [TeX Live](https://tug.org/texlive/) — licences libres diverses (LPPL et autres)

Les correctifs et traductions de ce dépôt sont fournis sous la même licence que le projet.
