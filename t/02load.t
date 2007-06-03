use strict;
use warnings;
if (-d "blib/plib") {
  $main::lib = "blib\/plib";
} elsif (-d "blib\/lib") {
  $main::lib = "blib\/lib";
} else {
  $main::lib = "plib";
}
print "1..2\n";
require("$main::lib\/AutoCons.pm") && 
print "ok 1\n" || print "not ok 1\n";
require("$main::lib\/AutoCons\/ConfigH.pm") &&
print "ok 2\n" || print "not ok 2\n";
