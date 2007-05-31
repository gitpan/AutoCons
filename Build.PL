# Build.PL for AutoCons.
# This is a great example for other's Build.PLs.

use Module::Build;
my $build = Module::Build->new(
  module_name => 'AutoCons',
  dist_version => 0.01_02,
  dist_abstract => "a cons-based build system",
  dist_author => "Michael Howell <m_howell123@yahoo.com>",
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
  }
);
$build->create_build_script;

