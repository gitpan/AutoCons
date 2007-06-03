use strict;
use warnings;
print "1..2\n";
if (-f "pscripts/cons") {
  $main::cons = "pscripts/cons";
} else {
  $main::cons = "cons";
}
system("$main::cons -f t/test.cs test");
if (-f "t/test") {
  print "ok 1\n";
} else {
  print "not ok 1\n";
}

system("$main::cons -q -f t/test.cs -r test");
if (! -f "t/test") {
  print "ok 2\n";
} else {
  print "not ok 2\n";
}

