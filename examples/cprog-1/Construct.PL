use AutoCons;
WriteCS(
  Name => "cprog",
  Version => "1"
);
Targ("Program", "blib/bin/cprog", "src/bin/cprog.c");
Targ("Install", "$installbin", "blib/bin/cprog");
