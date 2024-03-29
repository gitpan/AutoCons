use strict;
no strict "vars";
use warnings;
use AutoCons::AC;

open(LANG,">Lang.pm");
print LANG <<END;
# Automatically generated by $0.
# If you want to add another language
# module, just append another "use _" to 
# this file.
END

DirSearch("Lang");
foreach (@dirs) {
  DirSearch("$_");
}
foreach (@files) {
  my $mod = $_;
  $mod =~ s/\//::/;
  $mod =~ s/\.pm//;
  print LANG "use AutoCons::$mod;\n"
    if (/\.pm$/);
}

