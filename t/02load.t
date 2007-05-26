use strict;
use warnings;
print "1..2\n";
require("blib\/plib\/AutoCons.pm") && 
print "ok 1\n" || print "not ok 1\n";
require("blib\/plib\/AutoCons\/ConfigH.pm") &&
print "ok 2\n" || print "not ok 2\n";
