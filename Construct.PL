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
  my $yn = Prompt("I can't find cons. Should I install it now?\n");
  if ($yn eq "y") {
    use CPAN;
    CPAN::Shell->install('Cons');
  }
}

# Write Construct.PL.
WriteCS(
  Name => "AutoCons",
  Version => "0.01_01",
  NoRec => 1, # Don't build examples.
  PreReqs => [
    "strict",
    "Config",
    "Test::Harness 2"
  ]
);
