# Installation — réseau, HTTPS et certificats

Ce document couvre tout ce qui entoure le déploiement du renderer : restriction d'accès
réseau, mise en place de HTTPS via Caddy, et gestion des certificats. Pour la construction
des images elles-mêmes, voir le [README principal](../README.md).

## Pare-feu / sécurité réseau

Le renderer n'a **aucune notion d'identité ou de rôle** : `/render-api` répond à quiconque peut
l'atteindre, sans vérifier qui pose la question. **Restreignez l'accès réseau pour que seul le
serveur Moodle puisse le joindre** :

```bash
sudo ufw allow OpenSSH               # ne jamais oublier avant d'activer ufw !
sudo ufw allow from <IP_MOODLE> to any port 3443
sudo ufw deny 3443
sudo ufw enable
```

**Piège fréquent (ufw + Docker)** : activer `ufw` peut couper la communication interne entre
Caddy et le renderer (erreur 502, "i/o timeout" vers l'IP du pont Docker `172.17.0.0/16`). Deux
réglages sont généralement nécessaires en plus des règles ci-dessus :
```bash
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
sudo ufw allow from 172.17.0.0/16 to any port 3000
sudo ufw reload
```

## HTTPS via Caddy

Le renderer lui-même ne fait pas de HTTPS — utilisez [Caddy](https://caddyserver.com/) comme
reverse proxy. Voir le `Caddyfile` d'exemple et les instructions complètes dans le
[README du plugin Moodle](https://github.com/JonathanDesaulniers2/moodle-qtype_webwork#caddy), puisque Caddy sert aussi de point
de navigation en lecture seule pour les banques de problèmes utilisées par le plugin.

### Certificat HTTPS : deux approches selon le contexte

Un certificat auto-signé « nu » (par défaut, non signé par une autorité) doit être accepté
manuellement dans **chaque navigateur**, et redevient méfiant à chaque régénération —
inutilisable pour de vrais étudiants sur leurs propres appareils. Deux solutions robustes,
selon votre situation :

#### A. Développement / test local (pas de nom de domaine) — mini autorité de certification (CA)

Créez votre propre autorité de certification une seule fois, puis un certificat signé par
elle pour le renderer. Une fois cette CA installée comme « de confiance » sur un poste, **tous**
les certificats qu'elle signe sont acceptés automatiquement, même après une reconstruction
Docker complète (tant que la clé ne change pas).

```bash
mkdir -p ~/webwork-ca && cd ~/webwork-ca

# 1. La CA elle-même (valide 10 ans) -- à ne créer qu'UNE SEULE FOIS
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt -subj "/C=CA/ST=Quebec/O=Votre Institution/CN=WebWorK Renderer CA"

# 2. Le certificat du renderer, signé par cette CA (adapter l'IP/le nom de domaine)
cat > webwork.ext << 'EOF'
subjectAltName = IP:192.168.50.158
EOF
openssl genrsa -out webwork.key 2048
openssl req -new -key webwork.key -out webwork.csr \
  -subj "/C=CA/ST=Quebec/O=Votre Institution/CN=192.168.50.158"
openssl x509 -req -in webwork.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out webwork.crt -days 3650 -sha256 -extfile webwork.ext

# 3. Remplacer le certificat utilisé par Caddy, puis redémarrer
cp webwork.crt webwork.key /chemin/vers/vos/fichiers/montés/par/caddy/
sudo docker restart webwork-caddy
```

Installez ensuite **`ca.crt`** (pas `webwork.crt`) comme autorité de confiance sur chaque poste
qui doit accéder au renderer :
- **Windows** : `certlm.msc` (magasin machine, recommandé pour Chrome/Edge) → *Autorités de
  certification racines de confiance* → clic droit → *Toutes les tâches → Importer* →
  sélectionner `ca.crt` → confirmer que l'importation réussit → **redémarrer complètement le
  navigateur** (fermer tous les processus, pas juste l'onglet)
- **macOS** : double-clic sur `ca.crt` (ouvre *Trousseau d'accès*) → trouver le certificat →
  *Obtenir des informations* → *Approbation* → *Toujours faire confiance*
- **Firefox** (magasin séparé du système) : *Paramètres → Vie privée et sécurité → Certificats
  → Afficher les certificats → Autorités → Importer*

Le fichier `ca.crt` doit être transféré sur le poste local d'abord (le certificat est généré
sur le serveur) — via `scp`, ou un client graphique comme WinSCP (Windows) ou Cyberduck (Mac).

⚠️ Cette approche exige d'installer `ca.crt` sur **chaque appareil** qui accède au renderer —
adaptée pour du développement/test personnel, mais **pas adaptée à de vrais étudiants** sur
leurs propres appareils (impossible de leur demander d'installer un certificat).

#### B. Production avec de vrais étudiants — Let's Encrypt via validation DNS-01

Solution **sans aucune installation, sur aucun appareil** — le certificat est reconnu
nativement par tous les navigateurs, et se renouvelle automatiquement pour toujours. Nécessite :

1. **Un nom de domaine** (ou sous-domaine) dont vous contrôlez les entrées DNS (ex.
   `webwork.votre-institution.ca`)
2. **Un accès à l'API de votre fournisseur DNS** — Caddy supporte de nombreux fournisseurs
   (Cloudflare, OVH, Route53, etc.) via des modules de validation DNS-01
3. **Une résolution DNS interne** faisant pointer ce nom de domaine vers l'IP interne du
   serveur, pour que les appareils sur le réseau institutionnel/VPN trouvent le bon serveur

Le point clé : la validation **DNS-01** prouve que vous contrôlez le domaine (en y ajoutant une
entrée TXT temporaire), **sans jamais exiger que le serveur soit accessible depuis internet** —
contrairement à la validation HTTP-01 par défaut. Le serveur peut donc rester complètement
fermé au reste d'internet (voir la section [pare-feu](#pare-feu--sécurité-réseau)), tout en
obtenant un certificat public légitime.

La configuration exacte du `Caddyfile` dépend du fournisseur DNS utilisé (chaque fournisseur a
son propre module Caddy) — consultez la [documentation Caddy sur les modules DNS](https://caddyserver.com/docs/caddyfile/directives/tls#dns)
pour le vôtre.
