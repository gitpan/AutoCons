# Build.PL for AutoCons.

# Check for stupid mistakes.
use strict;

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
    push @main::scripts, "pscripts/cons"
  }
}

use Module::Build;
my $build = Module::Build->new(
  module_name => 'AutoCons',
  dist_version => 0.01_04,
  dist_abstract => "a cons-based build system",
  dist_author => "Michael Howell <m_howell123\@yahoo.com>",
  license  => 'perl',
  requires => {
    'Test::Harness'  => '2',
    'File::Find' => '0',
  },
  create_makefile_pl => 'passthrough',
  pm_files => {
    'plib/AutoCons.pm' => 'lib/AutoCons.pm',
    'plib/AutoCons/AC.pm' => 'lib/AutoCons/AC.pm',
    'plib/AutoCons/ConfigH.pm' => 'lib/AutoCons/ConfigH.pm'
  },
  pod_files => {
    'plib/AutoCons/HOWTO.pod' => 'lib/AutoCons/HOWTO.pod',
    'plib/AutoCons/HOWTO/C.pod' => 'lib/AutoCons/HOWTO/C.pod',
    'plib/AutoCons/HOWTO/Perl.pod' => 'lib/AutoCons/HOWTO/Perl.pod'
  },
  script_files => @main::scripts
);
$build->create_build_script;

