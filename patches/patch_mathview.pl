#!/usr/bin/env perl
# Patch mathview.js / mathview.*.min.js -- trois correctifs distincts :
#
# 1. Ajoute une vérification de compatibilité MathJax v2/v3 avant chaque
#    appel à "MathJax.startup.promise", qui plantait inconditionnellement
#    dans notre contexte (le renderer charge sa propre MathJax v3, mais le
#    plugin qtype_webwork exclut volontairement ce script au profit de sa
#    propre installation de MathJax v2). Même logique de repli que
#    l'ancienne version de ce fichier (plugin qtype_webwork_opaque) avait
#    déjà : "if (MathJax.startup == undefined) { ... } else { ... }".
#
# 2. Assainit l'identifiant de base que mathview.js construit à partir de
#    l'"id" HTML du champ décoré (this.id = `${t.id}_mathviewer`), puis
#    RÉUTILISE comme SÉLECTEUR CSS (via data-bs-target de Bootstrap) pour
#    gérer ses onglets de catégories. Le préfixe de nommage de Moodle
#    contient un DEUX-POINTS littéral (ex. "q440:1_..."), syntaxiquement
#    invalide dans un sélecteur CSS -- ce qui cassait silencieusement le
#    changement d'onglet (toujours bloqué sur "Basic").
#
# 3. Traduit trois chaînes anglaises codées EN DUR directement dans
#    mathview.min.js (pas dans mv_locale_us.js, donc jamais traduisibles
#    via le fichier de locale seul) : l'info-bulle "Equation Editor" et
#    les boutons "Insert"/"Clear" de la fenêtre d'édition (mode non
#    décoré, ex. correction de copies).
#
# Usage : perl patch_mathview.pl /chemin/vers/mathview.js
use strict;
use warnings;
use utf8;
binmode(STDOUT, ':utf8');

my $path = shift @ARGV or die "Usage: perl patch_mathview.pl <mathview.js>\n";

open(my $fh, '<:encoding(UTF-8)', $path) or die "Impossible d'ouvrir $path: $!\n";
local $/;
my $content = <$fh>;
close($fh);

my $pattern = qr/MathJax\.startup\.promise\s*=\s*MathJax\.startup\.promise\.then\(\(\s*\(\s*\)\s*=>\s*MathJax\.typesetPromise\(\[(.*?)\]\)\)\)/;

my $count = 0;
$content =~ s/$pattern/
    $count++;
    "(MathJax.startup===undefined?MathJax.Hub.Queue([\"Typeset\",MathJax.Hub]):(MathJax.startup.promise=MathJax.startup.promise.then((()=>MathJax.typesetPromise([$1])))))"
/ge;

if ($count == 0) {
    die "Aucune occurrence de 'MathJax.startup.promise' trouvée -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

my $idpattern = qr/this\.id\s*=\s*`\$\{t\.id\}_mathviewer`/;
my $idcount = 0;
$content =~ s{$idpattern}{
    $idcount++;
    'this.id=`${t.id.replace(/:/g,"_")}_mathviewer`'
}ge;

if ($idcount == 0) {
    die "Aucune occurrence de 'this.id = ...mathviewer' trouvée -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

# 4. Position du curseur après l'insertion d'un modèle : mathview.js le
#    place juste après la première ouverture trouvée par /\(\)|\[,|\(,/.
#    Les intervalles en notation québécoise de mv_locale_fr.js (],] et
#    ],[) commencent par « ] » : sans « \], » dans l'expression, le curseur
#    restait AVANT le modèle inséré. Sans effet sur la notation anglaise.
my $cursorcount = ($content =~ s{\Q/\(\)|\[,|\(,/\E}{/\\(\\)|\\[,|\\(,|\\],/}g);
if ($cursorcount == 0) {
    die "Expression de position du curseur introuvable -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

# 5. Libellé du bouton de sections : mathview.js y écrit une fois pour
#    toutes mathView_translator[12] (« Operations ») et ne le met jamais à
#    jour. En français, « Opérations » se lit comme le nom d'une section :
#    après un passage à « Intervalles », le bouton affichait toujours
#    « Opérations ». Il affiche maintenant le nom de la section active :
#    celui de la première au départ, puis celui de la section choisie.
my $labelcount = ($content =~ s{\Qc.textContent=mathView_translator[12]\E}{c.textContent=mv_categories[0].text}g);
my $switchcount = ($content =~ s{\Qi.textContent=e.text,o.append(i)\E}{i.textContent=e.text,i.addEventListener("click",()=>{this.dropdown.previousElementSibling.textContent=e.text}),o.append(i)}g);
if ($labelcount == 0 || $switchcount == 0) {
    die "Bouton de sections introuvable ($labelcount/$switchcount) -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

my %hardcoded = (
    '"Equation Editor"' => "\"Éditeur d'équations\"",
    '"Insert"'          => "\"Insérer\"",
    '"Clear"'           => "\"Effacer\"",
);
my $hcount = 0;
for my $en (keys %hardcoded) {
    my $fr = $hardcoded{$en};
    $hcount += ($content =~ s/\Q$en\E/$fr/g);
}

open(my $out, '>:encoding(UTF-8)', $path) or die "Impossible d'écrire $path: $!\n";
print $out $content;
close($out);

print "Correctif appliqué avec succès à $path ($count occurrence(s) MathJax + $idcount occurrence(s) id + $hcount chaîne(s) codée(s) en dur + $cursorcount curseur + $labelcount/$switchcount bouton de sections)\n";
