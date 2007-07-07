use AutoCons;
use ExtUtils::PkgConfig;
%pkg_info = ExtUtils::PkgConfig->find ("gtk+");
WriteCS(
  Name => "cprog",
  Version => "1",
  Libs => "$pkg_info{ libs }"
);
Targ("Program", "blib/bin/cprog", "src/bin/cprog.c");
Targ("Install", "$installbin", "blib/bin/cprog");
