#!/usr/bin/env perl
# Patch AnswerChecker.pm : traduit le message "Your answer isn't X (it looks
# like Y)" (ligne ~259, sub cmp_equal), où X/Y sont des descriptions de type
# CONSTRUITES DYNAMIQUEMENT par cmp_class()/showClass() (ex. "a Formula that
# returns a Number", "a List of Numbers").
#
# IMPORTANT : on ne touche PAS à showClass()/showType()/cmp_class()
# elles-mêmes -- ces fonctions sont utilisées ailleurs dans le code pour de
# la logique interne basée sur la présence du mot anglais "Formula" (ex.
# cmp_class() fait `return $class if $class =~ m/Formula/`). Les traduire
# directement casserait cette logique. On ajoute plutôt une fonction de
# traduction séparée, appliquée UNIQUEMENT au moment de construire le
# message final affiché à l'étudiant, avec repli sécuritaire vers l'anglais
# pour toute tournure non reconnue (couverture incrémentale, comme les
# autres correctifs de ce projet).
#
# Usage : perl patch_answerchecker.pl /chemin/vers/AnswerChecker.pm
use strict;
use warnings;
use utf8;
binmode(STDOUT, ':utf8');

my $path = shift @ARGV or die "Usage: perl patch_answerchecker.pl <AnswerChecker.pm>\n";

open(my $fh, '<:encoding(UTF-8)', $path) or die "Impossible d'ouvrir $path: $!\n";
local $/;
my $content = <$fh>;
close($fh);

my $utf8count = 0;
if ($content !~ /^use utf8;/m) {
    $content =~ s/(^package\s+\S+;\n)/$1use utf8;\n/m
        or die "Marqueur 'package ...;' introuvable pour insérer 'use utf8;'.\n";
    $utf8count = 1;
}

# Fonction de traduction insérée juste avant "sub cmp_equal {".
my $helper = <<'PERLFUNC';
#
#  Traduit une description de type anglaise (produite par cmp_class()/
#  showClass(), ex. "a Formula that returns a Number", "a List of Numbers")
#  en français -- avec repli sécuritaire vers l'anglais pour toute tournure
#  non reconnue. Ajouté par qtype_webwork (voir patch_answerchecker.pl) :
#  ne modifie PAS showClass()/showType()/cmp_class() elles-mêmes, qui
#  restent en anglais pour la logique interne (ex. tests sur /Formula/).
sub __qtypeWW_frType {
        my $s = shift;
        return $s unless defined $s;
        if ($s =~ /^an?\s+Formula\s+that\s+returns\s+(.+)$/i) {
                return "une Formule qui retourne " . __qtypeWW_frType($1);
        }
        if ($s =~ /^an?\s+List\s+of\s+(.+)$/i) {
                my $singular = $1;
                $singular =~ s/ices$/ix/i;       # Matrices -> Matrix (pour la recherche anglaise)
                $singular =~ s/s$//i unless $singular =~ /ix$/i;
                my $rest = __qtypeWW_frType("a $singular");
                $rest =~ s/^une?\s+//i;
                $rest = lc($rest);
                $rest .= 's' unless $rest =~ /s$/;    # pluriel français régulier (nombre -> nombres, etc.)
                return "une Liste de " . $rest;
        }
        my %table = (
                'Real Number'            => 'un Nombre réel',
                'Complex Number'         => 'un Nombre complexe',
                'Number'                 => 'un Nombre',
                'Interval, Set or Union' => 'un Intervalle, Ensemble ou Union',
                'Union of Intervals'     => 'une Union d\'intervalles',
                'Interval'               => 'un Intervalle',
                'Point'                  => 'un Point',
                'Vector'                 => 'un Vecteur',
                'Matrix'                 => 'une Matrice',
                'Union'                  => 'une Union',
                'Set'                    => 'un Ensemble',
                'Word'                   => 'un Mot',
                'Empty Value'            => 'une Valeur vide',
                'Infinity'               => 'un Infini',
                'String'                 => 'une Chaîne',
        );
        for my $key (sort { length($b) <=> length($a) } keys %table) {
                return $table{$key} if $s =~ /^an?\s+\Q$key\E$/i;
        }
        return $s;    # repli sécuritaire : anglais inchangé si non reconnu
}

PERLFUNC

my $anchor = "sub cmp_equal {";
my $inscount = 0;
if (index($content, $helper) == -1) {
    $inscount = ($content =~ s/\Q$anchor\E/$helper$anchor/);
}

my $old = q{"Your answer isn't " . lc($ans->{cmp_class}) . "\n" . "(it looks like " . lc($student->showClass) . ")"};
my $new = q{"Votre réponse n'est pas " . __qtypeWW_frType($ans->{cmp_class}) . "\n" . "(elle ressemble à " . __qtypeWW_frType($student->showClass) . ")"};

my $msgcount = 0;
if (index($content, $old) != -1) {
    $content =~ s/\Q$old\E/$new/;
    $msgcount = 1;
}

if ($inscount == 0 && $msgcount == 0 && $utf8count == 0) {
    die "Aucune modification n'était nécessaire ou possible -- le fichier a peut-être une version différente.\n";
}

open(my $out, '>:encoding(UTF-8)', $path) or die "Impossible d'écrire $path: $!\n";
print $out $content;
close($out);

print "Correctif appliqué avec succès à $path (use utf8; ajouté : $utf8count, fonction ajoutée : $inscount, message traduit : $msgcount)\n";
