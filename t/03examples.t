# Find CONS.
if (-x "pscripts/cons") { $main::Cons = "pscripts/cons" }
else { $main::Cons = "cons" }
# Tests. 
print "1..2\n";
print STDERR "# Please wait...\n";
chdir("examples/cprog-1/"); 
system("$^X Construct.PL >log && $main::Cons -q >log");
unless ($?) {
print "ok 1\n" } else { print "not ok 1\n" }
chdir("../Perl-Module");
system("$^X Construct.PL >log && $main::Cons -q >log");
unless ($?) {
print "ok 2\n" } else { print "not ok 1\n" }

