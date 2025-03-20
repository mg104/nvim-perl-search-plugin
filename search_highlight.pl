#!/usr/bin/perl
use strict;
use warnings;

# Read the regex pattern from command-line arguments
my $query = shift or die "Usage: $0 <regex-pattern>\n";

my $i = 0;
while (<>) {
   while ($_ =~ /$query/g) {
      print "$i $-[0] $+[0]\n";
   }
   $i++;
}

