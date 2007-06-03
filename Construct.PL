# Construct.PL for AutoCons.

# Check for stupid mistakes.
use strict;

# Use a "boxed" AutoCons by default.
use lib './plib';
use AutoCons;

# I need info about your perl.
use Config;

# Check for cons.
my(@path) = split /$Config{'path_sep'}/, $ENV{'PATH'};

foreach(@path) {
  if (-f "$_/cons") {
    use vars qw($cons);
    $cons = 1;
  }
}
unless ($cons) {
  do("plib/AutoCons/AC.pm");
  my $yn = Prompt("I cannot find cons. Should I install it now?\n");
  if ($yn eq "y") {
    mkdir "pscripts" if (! -d "pscripts");
    use File::Copy;
    File::Copy::syscopy("cons-2.2.0/cons", "pscripts/cons") 
      || die "Cannot prepare Cons sources: $!";
    chmod 0755, "pscripts/cons";
    print "To build, use pscripts/cons.\n";
  }
}

# Write Construct.PL.
WriteCS(
  Name => "AutoCons",
  Version => "0.01_03",
  NoRec => 1, # Don't build examples.
  PreReqs => [
    "strict",
    "Config",
    "Test::Harness 2",
    "ExtUtils::Manifest",
    "File::Find"
  ]
);
