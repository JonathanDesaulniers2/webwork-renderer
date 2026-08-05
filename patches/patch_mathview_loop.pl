#!/usr/bin/env perl
# Patch mathview.js / mathview.*.min.js : corrige une boucle infinie dans
# le MutationObserver de fin de fichier.
#
# Le garde-fou "mvInitialized" (censé empêcher de réinitialiser un champ
# déjà traité par MathView) ne vérifie QUE l'élément directement ajouté au
# DOM -- PAS les éléments retrouvés via querySelectorAll(".codeshard")/
# querySelectorAll(".latexentryfield") dans la branche "sinon". Or, le
# constructeur de MathView DÉPLACE le champ décoré original à l'intérieur
# d'un nouveau conteneur (n.append(t)) -- ce déplacement déclenche
# l'observateur à nouveau, qui retrouve le MÊME champ (déjà initialisé)
# via querySelectorAll, et le réinitialise, créant un nouveau conteneur,
# qui redéclenche l'observateur, etc. -- une boucle infinie qui bloque
# complètement le navigateur ("la page ne répond pas"), particulièrement
# visible sur une page affichant plusieurs questions MathView à la fois
# (ex. la page de relecture d'une tentative de quiz).
#
# On ajoute le même garde-fou "mvInitialized" à ces deux branches
# querySelectorAll, absent du code d'origine.
#
# Usage : perl patch_mathview_loop.pl /chemin/vers/mathview.js
use strict;
use warnings;

my $path = shift @ARGV or die "Usage: perl patch_mathview_loop.pl <mathview.js>\n";

open(my $fh, '<', $path) or die "Impossible d'ouvrir $path: $!\n";
local $/;
my $content = <$fh>;
close($fh);

my $count = 0;

# Boucles de scan INITIAL (au chargement du script, avant même que le
# MutationObserver n'entre en jeu) -- aucune vérification de
# "mvInitialized" ici du tout à l'origine. Sur une page Moodle affichant
# PLUSIEURS questions WeBWorK avec des réglages "entryAssist" différents
# (ex. MathView sur une question, MathQuill sur une autre), CE scan
# s'exécute sur TOUTE la page sans distinction, et s'accroche à des champs
# ".codeshard" qui appartiennent à une AUTRE question, configurée pour un
# AUTRE éditeur -- d'où des icônes MathView apparaissant sur des questions
# qui ne les demandaient pas. Le plugin Moodle marque désormais
# préventivement (data-mv-initialized="true") les champs des questions
# n'utilisant pas MathView ; ce correctif fait en sorte que ce marqueur
# soit respecté dès ce scan initial, pas seulement dans le
# MutationObserver (qui, lui, était déjà protégé par une vérification
# identique, mais uniquement pour les nœuds ajoutés APRÈS coup).
my $pat0a = qr/for\s*\(\s*const\s+e\s+of\s+document\.querySelectorAll\(\s*["\']\.codeshard["\']\s*\)\s*\)\s*new\s+t\(e\)\s*;/;
$count += ($content =~ s/$pat0a/for (const e of document.querySelectorAll(".codeshard")) if ("true" !== e.dataset.mvInitialized) new t(e);/g);

my $pat0b = qr/for\s*\(\s*const\s+e\s+of\s+document\.querySelectorAll\(\s*["\']\.latexentryfield["\']\s*\)\s*\)\s*new\s+t\(e,\s*(\{[^}]*\})\s*\)\s*;/;
$count += ($content =~ s/$pat0b/for (const e of document.querySelectorAll(".latexentryfield")) if ("true" !== e.dataset.mvInitialized) new t(e,$1);/g);

# Branche "codeshard"
my $pat1 = qr/\.querySelectorAll\(\s*["\']\.codeshard["\']\s*\)\.forEach\(\(\s*e\s*=>\s*new\s+t\(e\)\s*\)\)/;
$count += ($content =~ s/$pat1/.querySelectorAll(".codeshard").forEach((e=>{if("true"!==e.dataset.mvInitialized)new t(e)}))/g);

# Branche "latexentryfield" (l'objet d'options est capturé et réinjecté tel quel)
my $pat2 = qr/\.querySelectorAll\(\s*["\']\.latexentryfield["\']\s*\)\.forEach\(\(\s*e\s*=>\s*new\s+t\(e,\s*(\{[^}]*\})\s*\)\)\)/;
$count += ($content =~ s/$pat2/.querySelectorAll(".latexentryfield").forEach((e=>{if("true"!==e.dataset.mvInitialized)new t(e,$1)}))/g);

if ($count == 0) {
    die "Aucune occurrence trouvée -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

open(my $out, '>', $path) or die "Impossible d'écrire $path: $!\n";
print $out $content;
close($out);

print "Correctif appliqué avec succès à $path ($count occurrence(s) corrigée(s))\n";
