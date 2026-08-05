#!/usr/bin/env perl
# Patch graphtool.js / graphtool.*.min.js : ajoute une vérification de
# compatibilité MathJax v2/v3 avant l'appel à "MathJax.startup.promise",
# qui plantait ("Cannot read properties of undefined (reading 'promise')")
# dans notre contexte -- le script vérifie bien que "window.MathJax" existe
# (vrai, puisque le plugin qtype_webwork charge sa propre installation de
# MathJax v2), mais accède ensuite directement à ".startup.promise" sans
# vérifier que "startup" existe, une propriété propre à MathJax v3. Même
# correctif que patch_mathview.pl pour le même problème.
#
# Ce plantage, survenant tôt dans l'exécution des scripts de la page,
# empêchait aussi certains scripts plus loin sur la page (dont le nôtre,
# qui déclenche le rendu MathJax de l'énoncé de la question) de s'exécuter
# -- d'où l'expression manquante dans l'énoncé en plus du plantage
# directement visible.
#
# Usage : perl patch_graphtool.pl /chemin/vers/graphtool.js
use strict;
use warnings;
use utf8;
binmode(STDOUT, ':utf8');

my $path = shift @ARGV or die "Usage: perl patch_graphtool.pl <graphtool.js>\n";

open(my $fh, '<:encoding(UTF-8)', $path) or die "Impossible d'ouvrir $path: $!\n";
local $/;
my $content = <$fh>;
close($fh);

my $pattern = qr/window\.MathJax\s*&&\s*\(MathJax\.startup\.promise\s*=\s*MathJax\.startup\.promise\.then\(\(\s*\(\s*\)\s*=>\s*MathJax\.typesetPromise\(\[(.*?)\]\)\)\)\)/;

my $count = 0;
$content =~ s/$pattern/
    $count++;
    "(window.MathJax&&(MathJax.startup===undefined?MathJax.Hub.Queue([\"Typeset\",MathJax.Hub]):(MathJax.startup.promise=MathJax.startup.promise.then((()=>MathJax.typesetPromise([$1]))))))"
/ge;

if ($count == 0) {
    die "Aucune occurrence de 'window.MathJax && (MathJax.startup.promise...' trouvée -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

# Traduction des textes de l'interface (boutons, info-bulles, messages
# d'aide contextuelle) -- chaînes codées en dur, aucun fichier de locale
# séparé pour GraphTool (contrairement à MathView).
my @strings = (
    ['WeBWorK Graph Tool', 'Outil de traçage WeBWorK'],
    ['Interactively graph objects', 'Tracer des objets de façon interactive'],
    ['Selection Tool: Select a graphed object to modify.', 'Outil de sélection : sélectionner un objet tracé à modifier.'],
    ['Point Tool: Plot a point.', 'Outil point : placer un point.'],
    ['Line Tool: Graph a line.', 'Outil ligne : tracer une droite.'],
    ['Circle Tool: Graph a circle.', 'Outil cercle : tracer un cercle.'],
    ['3-Point Quadratic Tool: Graph a quadratic function.', 'Outil quadratique (3 points) : tracer une fonction quadratique.'],
    ['4-Point Cubic Tool: Graph a cubic function.', 'Outil cubique (4 points) : tracer une fonction cubique.'],
    ['Vertical Parabola Tool: Graph a vertical parabola.', 'Outil parabole verticale : tracer une parabole verticale.'],
    ['Horizontal Parabola Tool: Graph an horizontal parabola.', 'Outil parabole horizontale : tracer une parabole horizontale.'],
    ['Region Shading Tool: Shade a region in the graph.', 'Outil de remplissage : ombrer une région du graphique.'],
    ['Make the selected object solid (s).', 'Rendre l\'objet sélectionné plein (s).'],
    ['Make the selected object dashed (d).', 'Rendre l\'objet sélectionné pointillé (d).'],
    ['Delete the selected object (Delete).', 'Supprimer l\'objet sélectionné (Suppr).'],
    ['Clear all objects from the graph (Ctrl-Delete).', 'Effacer tous les objets du graphique (Ctrl+Suppr).'],
    ['Switch to fullscreen.', 'Basculer en plein écran.'],
    ['Exit fullscreen.', 'Quitter le plein écran.'],
    ['Disable this help for all graphs.', 'Désactiver cette aide pour tous les graphiques.'],
    ['Make changes to the selected object, or select a new tool (Shift-N) to graph another object.', 'Modifiez l\'objet sélectionné, ou choisissez un nouvel outil (Maj+N) pour tracer un autre objet.'],
    ['Select a new tool (Shift-N) to graph an object.', 'Choisissez un nouvel outil (Maj+N) pour tracer un objet.'],
    ['Plot the vertex of the parabola.', 'Placez le sommet de la parabole.'],
    ['Plot another point on the parabola.', 'Placez un autre point sur la parabole.'],
    ['Plot two points on the line.', 'Placez deux points sur la droite.'],
    ['Plot one more point on the line.', 'Placez un point de plus sur la droite.'],
    ['Plot the center of the circle.', 'Placez le centre du cercle.'],
    ['Plot a point on the circle.', 'Placez un point sur le cercle.'],
    ['Choose a point in the region to be filled.', 'Choisissez un point dans la région à remplir.'],
    ['Do you want to delete the selected object?', 'Voulez-vous supprimer l\'objet sélectionné?'],
    ['Do you want to remove all graphed objects?', 'Voulez-vous retirer tous les objets tracés?'],
    ['Unknown tool: ', 'Outil inconnu : '],
);
my $strcount = 0;
for my $pair (@strings) {
    my ($en, $fr) = @$pair;
    $strcount += ($content =~ s/\Q$en\E/$fr/g);
}
# Textes courts (boutons/dropdown) -- traités séparément et en dernier pour
# éviter qu'ils ne matchent accidentellement une portion d'une chaîne plus
# longue déjà traduite ci-dessus.
my @shortstrings = (
    ['"Delete"', '"Supprimer"'],
    ['"Clear"', '"Effacer"'],
    ['"Fullscreen"', '"Plein écran"'],
    ['"Exit Fullscreen"', '"Quitter le plein écran"'],
    ['"Disable Help"', '"Désactiver l\'aide"'],
    ['"Enable Help"', '"Activer l\'aide"'],
    ['"Yes"', '"Oui"'],
    ['"No"', '"Non"'],
);
for my $pair (@shortstrings) {
    my ($en, $fr) = @$pair;
    $strcount += ($content =~ s/\Q$en\E/$fr/g);
}

open(my $out, '>:encoding(UTF-8)', $path) or die "Impossible d'écrire $path: $!\n";
print $out $content;
close($out);

print "Correctif appliqué avec succès à $path ($count occurrence(s) MathJax + $strcount chaîne(s) d'interface traduites)\n";
