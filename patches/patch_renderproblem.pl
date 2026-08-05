#!/usr/bin/env perl
# Patch RenderProblem.pm : ajoute le calcul manquant de "useMathView" (déjà
# pleinement supporté par PG.pm -- voir sa documentation, section "useMathQuill,
# useMathView" -- mais jamais transmis par le renderer standalone). Permet un
# vrai choix par requête entre MathQuill, MathView, et aucun éditeur assisté,
# via le paramètre "entryAssist" du render-api :
#   entryAssist=MathQuill (ou absent) -> MathQuill (comportement actuel, inchangé)
#   entryAssist=MathView              -> MathView
#   entryAssist=<toute autre valeur>  -> aucun éditeur assisté
#
# Usage : perl patch_renderproblem.pl /chemin/vers/RenderProblem.pm
use strict;
use warnings;

my $path = shift @ARGV or die "Usage: perl patch_renderproblem.pl <RenderProblem.pm>\n";

open(my $fh, '<', $path) or die "Impossible d'ouvrir $path: $!\n";
local $/;
my $content = <$fh>;
close($fh);

my $old = q{useMathQuill            => !defined $inputs_ref->{entryAssist} || $inputs_ref->{entryAssist} eq 'MathQuill',};

my $new = q{useMathQuill            => !defined $inputs_ref->{entryAssist} || $inputs_ref->{entryAssist} eq 'MathQuill',
                useMathView             => defined $inputs_ref->{entryAssist} && $inputs_ref->{entryAssist} eq 'MathView',};

if (index($content, $old) == -1) {
    die "Ligne 'useMathQuill' attendue introuvable -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

$content =~ s/\Q$old\E/$new/;

open(my $out, '>', $path) or die "Impossible d'écrire $path: $!\n";
print $out $content;
close($out);

print "Correctif appliqué avec succès à $path\n";
