#!/usr/bin/env perl
# Patch mv_locale_us.js / mv_locale_us.*.min.js : convertit les déclarations
# globales "const mathView_translator" et "const mv_categories" en "var",
# pour éviter l'erreur "Identifier '...' has already been declared" si ce
# script s'exécute plus d'une fois sur la même page (contrairement à "var",
# "const"/"let" ne tolèrent aucune redéclaration dans la même portée).
#
# Usage : perl patch_mv_locale.pl /chemin/vers/mv_locale_us.js
use strict;
use warnings;

my $path = shift @ARGV or die "Usage: perl patch_mv_locale.pl <mv_locale_us.js>\n";

open(my $fh, '<', $path) or die "Impossible d'ouvrir $path: $!\n";
local $/;
my $content = <$fh>;
close($fh);

my $count = 0;
for my $name ('mathView_translator', 'mv_categories') {
    my $n = ($content =~ s/\bconst\s+$name\b/var $name/g);
    $n += ($content =~ s/\blet\s+$name\b/var $name/g);
    $count += $n;
}

if ($count == 0) {
    die "Aucune déclaration 'const'/'let' trouvée pour mathView_translator ou mv_categories -- le fichier a peut-être une version différente. Aucune modification effectuée.\n";
}

open(my $out, '>', $path) or die "Impossible d'écrire $path: $!\n";
print $out $content;
close($out);

print "Correctif appliqué avec succès à $path ($count déclaration(s) corrigée(s))\n";
