#!/usr/bin/env perl
# Patch CofIdaho_macros.pl : traduit TOUS les messages d'erreur destinés à
# l'étudiant ("ans_message") de ce fichier macro en français (Québec), pas
# seulement celui qui a motivé ce correctif -- politique du projet :
# quand on corrige un fichier macro, on en profite pour tout traduire d'un
# coup plutôt que d'y revenir message par message.
#
# Ce fichier n'utilise PAS le mécanisme $context->{error}{msg} de
# Value/Context.pm (voir patch_context.pl) -- les messages sont fixés
# directement sur l'objet ans_hash via setKeys()/accès direct, une
# convention propre à ce fichier macro spécifique (et probablement à
# beaucoup d'autres fichiers macro non encore examinés).
#
# Usage : perl patch_cofidaho.pl /chemin/vers/CofIdaho_macros.pl
use strict;
use warnings;
use utf8;
binmode(STDOUT, ':utf8');

my $path = shift @ARGV or die "Usage: perl patch_cofidaho.pl <CofIdaho_macros.pl>\n";

open(my $fh, '<:encoding(UTF-8)', $path) or die "Impossible d'ouvrir $path: $!\n";
local $/;
my $content = <$fh>;
close($fh);

my $count = 0;

# Remplacements simples (chaîne exacte -> traduction), avec variables Perl
# interpolées préservées telles quelles.
my @simple = (
    ['"Simplify your answer"',                                          '"Simplifiez votre réponse"'],
    ['"Simplify your answer."',                                         '"Simplifiez votre réponse."'],
    ['"Enter your answer with the correct units: $correct_units"',      '"Entrez votre réponse avec les bonnes unités : $correct_units"'],
    ['"Round your answer to the nearest $error."',                      '"Arrondissez votre réponse au $error près."'],
    ['"At least one side is incorrect."',                               '"Au moins un côté est incorrect."'],
    ['"Enter your answer in the form: $side[0] = expression."',         '"Entrez votre réponse sous la forme : $side[0] = expression."'],
    ['"You must enter an equation."',                                   '"Vous devez entrer une équation."'],
    ['"Enter your answer in the form: $BR y = mx+b, y = b or x = c"',   '"Entrez votre réponse sous la forme : $BR y = mx+b, y = b ou x = c"'],
    ['"Your answer must be in function notation."',                     '"Votre réponse doit être en notation fonctionnelle."'],
    ['"Your answer must be in correct function notation."',             '"Votre réponse doit être en notation fonctionnelle correcte."'],
    ['"You may only use parentheses in your answer."',                  '"Vous ne pouvez utiliser que des parenthèses dans votre réponse."'],
    ['"Your answer has extraneous grouping symbols."',                  '"Votre réponse contient des symboles de groupement superflus."'],
    ['"Factor the expression completely."',                             '"Factorisez complètement l\'expression."'],
    ['"You have listed an asymptote more than once."',                  '"Vous avez indiqué une asymptote plus d\'une fois."'],
);

for my $pair (@simple) {
    my ($en, $fr) = @$pair;
    $count += ($content =~ s/\Q$en\E/$fr/g);
}

# Message étalé sur plusieurs lignes (deux variantes de mise en forme dans
# le fichier) : on tolère les espaces/retours à la ligne via une regex.
my $foldedpattern = qr/"Check\s+that\s+your\s+answer\s+is\s+factored\s+completely\s+and\s+is\s+entered\s+in\s+the\s+required\s+format\."/;
$count += ($content =~ s/$foldedpattern/"Vérifiez que votre réponse est complètement factorisée et entrée dans le format requis."/g);

if ($count == 0) {
    die "Aucune des chaînes attendues n'a été trouvée -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

open(my $out, '>:encoding(UTF-8)', $path) or die "Impossible d'écrire $path: $!\n";
print $out $content;
close($out);

print "Correctif appliqué avec succès à $path ($count chaîne(s) traduite(s))\n";
