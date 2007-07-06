##AUTOCONS.PM##
#######################################################################
#    This Perl library module is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Library General Public
#    License (as published by the Free Software Foundation) or the
#    Artistic License.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Library General Public License for more details.
#
#    You should have received a copy of the GNU Library General Public 
#    License along with this library; if not, write to the Free
#    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#######################################################################

=head1 NAME

AutoCons - Write a Construct file.

=head1 SYNOPSIS

use AutoCons;
WriteCS(
  Name    => "Foo::Bar",
  Version => "1.0"
);

=head1 DESCRIPTION

AutoCons is a cons Construct generator similar to ExtUtils::MakeMaker or 
Gnu Autoconf, except that cons is far more portable than make. For the 
developer, this means that your program will build on any system that cons 
will. For a user, this means that you don't need a "make" program to build 
your program.

=head2 FUNCTIONS

=cut

# Set up package.

package AutoCons;

require Exporter;

@ISA = (Exporter);
@EXPORT = qw(WriteCS Dep Targ);

use vars qw($VERSION $installbin $installlib $installarch $installman1 $installman3);

# Load everything.
use Config;

# Don't worry about global variables, but still make sure nothing stupod 
# is in here.
use strict;
no strict "vars";

# In case we are under a 'boxed' install.
if (-f "plib/AutoCons/AC.pm") {
  use lib 'plib';
}
use AutoCons::AC;

# Main subroutine used to create a Construct.

=pod

* WriteCS()

Create a Construct with the information you give it. WriteCS involks all 
of the other subs needed to create a working Construct of Conscript.
 WriteCS(
   File => "<FILENAME>", # Optional; defaults to 'Construct'
   Name => "<NAME>", # Required
   Version => "<VERSION>", # Required
   Type =< "<'site' or 'vendor' or 'perl'>", # Optional; defaults to 'site'
   NoRec => <NO RECURSIVE BUILD>, # Optional
   PreReqs => [ # Optional.
     <MOD>,
     ...
   ],
   Add => "<CODE TO APPEND>" # Optional 
 );

=cut

sub WriteCS {
  # Get arguments.
  %Args   = @_;
  $cs     = $Args{ File } if ($Args{ File });
  $name   = $Args{ Name } if ($Args{ Name });
  $ver    = $Args{ Version } if ($Args{ Version });
  $add    = $Args{ Add } if ($Args{ Add });
  $type   = $Args{ Type } if ($Args{ Type });
  $norec  = $Args{ NoRec } if ($Args{ NoRec });
  @prereq = @{$Args{ PreReqs }} if ($Args{ PreReqs });
  # Defaults.
  $cs   = "Construct" unless ($cs);
  $type = "site" unless ($type);
  # How to handle type.
  if ($type eq "site") {
    $installbin  = $Config{ installsitebin };
    $installlib  = $Config{ installsitelib };
    $installarch = $Config{ installsitearch };
    $installman1 = $Config{ installsiteman1dir };
    $installman3 = $Config{ installsiteman3dir };
  } elsif ($type eq "vendor") {
    $installbin  = $Config{ installvendorbin };
    $installlib  = $Config{ installvendorlib };
    $installarch = $Config{ installvendorarch };
    $installman1 = $Config{ installvendorman1dir };
    $installman3 = $Config{ installvendorman3dir };
  } else {
    $installbin  = $Config{ installbin };
    $installlib  = $Config{ installlib };              
    $installarch = $Config{ installarchlib };               
    $installman1 = $Config{ installman1dir };                  
    $installman3 = $Config{ installman3dir }; 
  }
  $installprefix = $Config{ installprefix };
  # Get command line.
  foreach (@ARGV) {
    if (/(.+)\=(.*)/) {
      no strict 'refs'; # Need to be allowed the following ref.
      $$1 = $2;
    }
  }
  # Scan directories.
  &RecBuild unless ($norec);
  &DirCleanUp;
  # Ok, now we've started.
  print "Writing $cs for $name $ver...\n";
  # Open file.
  open(CS,">$cs");
  # Run sanity checks.
  &SanityCheck;
  # Head.
  print CS "# $cs for $name $ver\n\n";
  print CS "# Auto-generated by AutoCons.\n";
  print CS "# Don't edit this file. Edit $0 instead.\n";
  # Create variables.
  &Vars;
  &DirCleanUp;
  # Create targets.
  &Targs;
  &DirCleanUp;
  # Add extras.
  if ($add) {
    print CS "# From $0\n";
    print CS "$add\n";
  }
  # End.
}

# Add a target.

=pod

* Targ()

Add a target. Required to compile source code.
 Targ("<TARGET>", "<FILE>", "<DEPS>", "<ARGS>" );

=cut

sub Targ {
  my ($targ,$out,$in,$args) = @_;
  if ($args) {
    print CS "$targ \$env \"$out\", \"$in\", \"$args\";\n";
  } else {
    print CS "$targ \$env \"$out\", \"$in\";\n";
  }
}

# Add a dependency.

=pod

* Dep()

Add a dependency. Required to compile source code.
 Dep("<TARGET>", "<DEPS>");

=cut

sub Dep {
  my ($out,$in) = @_;
  print CS "Depends \$env \"$out\", \"$in\";\n";
}

# Scan other directories for contents.

=pod

* RecBuild()

Scan for and run PL scripts in other directories (run by WriteCS, mainly 
for internal use.)
 RecBuild( );

=cut

sub RecBuild {
  &DirSearch(".");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    # DON'T GET CAUGHT IN A LOOP!!!
    next if ($file =~ /^\.\/Construct\.PL$/);
    next if ($file =~ /^\.\/Conscript\.PL$/);
    # Now run it.
    if ($file =~ /(.+)\/(.+)\.PL$/) {
      system("cd $1;$^X $2.PL");
    }
  }
}

# Sanity checks.

=pod

* SanityCheck()

Check sanity of WriteCS options (run by WriteCS, mainly for internal use.)
 SanityCheck( );

=cut

sub SanityCheck {
  if (! $name) {
    die "Please specify name.\n  Error";
  }
  if (! $ver) {
    die "Please specify version.\n  Error";
  }
  if (@prereq) {
    foreach my $mod (@prereq) {
      if ($mod =~ /(.+) (.+)/) {
	eval("use $1 $2");
      } else {
        eval("use $mod");
      }
      if ($@) {
        warn sprintf "Warning: prerequisite $mod not found.\n";
      }
    }
  }
  if (-f "MANIFEST") {
    use ExtUtils::Manifest qw(manicheck);
    &manicheck;
  }
}

# Set variables.

=pod

* Vars()

Add variables to Conscript (run by WriteCS, mainly for internal use.)
 Vars( );

=cut

sub Vars {
  # Load cons. What worked for Perl itself must work.
  # Might as well be ready in case this is multi-level build.
  print CS "Export qw( env name ver installbin installlib installarch installman1 installman3);\n";
  # Use current plibs, if we have them.
  print CS "use lib \'./plib\';\n" if (-d "plib");
  print CS "use lib \'./.AutoCons\';\n" if (-d ".AutoCons");
  # Variables.
  print CS "\$name = \"$name\";\n";
  print CS "\$ver  = \"$ver\";\n";
  print CS "\$installbin  = \"$installbin\";\n";
  print CS "\$installlib  = \"$installlib\";\n";
  print CS "\$installarch = \"$installarch\";\n";
  print CS "\$installman1 = \"$installman1\";\n";
  print CS "\$installman3 = \"$installman3\";\n";
  foreach (@ARGV) {  
    if (/(.+)\=(.*)/) {
      print CS "\$$1 = $2;\n";
    }
  }  
  # Load AC.
  print CS "use AutoCons::AC;\n";
  # Construction environment.
  print CS "\$env = new cons(
  CC            => \'$Config{cc}\',
  CFLAGS        => \'$Config{ccflags}\',
  AR            => \'$Config{ar}\',
  LD            => \'$Config{ld}\',
  LDFLAGS       => \'$Config{ldflags}\',
  ENV           => { \%ENV },\n";
  # Ranlib is a bit weird, since it might be ":" if Ar can do the job.
  print CS
"  RANLIB        => \'$Config{ranlib}\'\n" if (!$Config{ranlib} eq ":");
  print CS ");\n";
  # Default targets.
  print CS "if (\$ARGV[0] eq \"install\") {\n";
  print CS "  Default qw(\n";
  print CS <<END;
    $installbin
    $installlib
    $installarch
    $installman1
    $installman3
    $installprefix);
END
  print CS "} elsif (\$ARGV[0] eq \"test\") {\n";   
  print CS "  Default \'t\'\n if (-d \"t\");";
  print CS "} else {\n";
  print CS "  Default \'blib\';\n";
  print CS "}\n";
  # Help message.
  print CS "Help <<END;\n";
  print CS "$cs generated by AutoCons $VERSION for \$name \$ver\n\n";
  print CS "Usage: cons [consargs] [targ] [-- [aargs]]\n";
  print CS "AutoCons Args:\n";
  print CS "  none: Build the program if no target is specified.\n";
  print CS "  test: Run any self-tests the program comes with.\n";
  print CS "  install: Install to $Config{ prefix }\n";
  print CS "Run cons -x for cons args.\n";
  print CS "Examples:\n";
  print CS "  cons -r -- install: Uninstall \$name\n";
  print CS "  cons -r .: Like make distclean.\n";
  print CS "  cons -r: Like make clean.\n";
  print CS "END\n";
}

# Create targets.

=pod

* Targs()

Add targets to Conscript (run by WriteCS, mainly for internal use.)
 Targs( );

=cut

sub Targs {
  # Construct
  print CS "Command \$env \"$cs\", \"$0\", \"$^X $0";
  foreach (@ARGV) {
    if (/(.+)\=(.*)/) {
      print CS " $1=\'$2\' ";
    }
  }
  print CS "\";\n";
  &DirCleanUp;
  if (-d "plib") {
    print CS "# XS targets.\n";
    &XSTargs;
    print CS "# Library targets.\n";
    &PLibTargs;
  }
  &DirCleanUp;
  if (-d "bin") {
    print CS "# Program targets.\n";
    &BinTargs;
  }
  &DirCleanUp;
  if (-d "pscripts") {  
    print CS "# Script targets.\n";
    &PScriptTargs;
  }
  &DirCleanUp;
  print CS "# Documentation targets.\n";
  &DocTargs;
  &DirCleanUp;
  # Dist targets.
  print CS "# Distribution packaging.\n";
  print CS "Command \$env \"dist/\$name-\$ver.tar.gz\", \"$cs\", \'[perl] MkDist()\'
  unless (-f \"dist/\$name-\$ver.tar.gz\");\n";
  # Test targets.
  if (-d "t") {
    &TestTargs();
  }
  if (-f "Config.h") {
    open (CH, "Config.h");
    my $l1 = <CH>;
    if ($l1 =~ /\/\* Generated by (.+) \*\//) {
      print CS "# Regenerate Config.h.\n";
      Targ("Command", "Config.h", "$1", "$^X $1");
    }
  }
}

=pod

* XSTargs()

Add targets for testing.
 TestTargs( )

=cut

sub XSTargs {
  &DirSearch("plib");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    next if ($file =~ /\.consign$/);
    next if ($file !~ /\.xs/);
    my $cfile = $file;
    $cfile =~ s/\.xs/.c/;
    my $ofile = $file;
    $ofile =~ s/\.xs/$Config{_o}/;
    print CS "Command \$env \"blib/$cfile\", \"$file\", \"xsubpp $file >blib/$cfile\";\n";
    print CS "Objects \$env \"blib/$cfile\";\n";
    my $instfile = $ofile;
    $instfile =~ s/plib\///;
    print CS "InstallAs \$env \"\$installarch/$instfile\", \"blib/$ofile\";\n";
  }
}

=pod

* TestTargs()

Add targets for testing.
 TestTargs( )

=cut

sub TestTargs {
  print CS "# Test targets.\n";
  my @ts = <t/*.t>;
  print CS "Command \$env \"t/.tested\", qw(@ts), \"@ [perl] require Test::Harness;Test::Harness::runtests(<t/*.t>)\n  @ touch t/.tested\"\n";
}

=pod

* PLibTargs()

Add perl module targets to Conscript (run by WriteCS, mainly for internal use.)
 PLibTargs( );

=cut

sub PLibTargs {
  &DirSearch("plib");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    next if ($file =~ /\.consign$/);
    next if ($file !~ /\.pm/);
    print CS "Cp \$env \"blib/$file\", \"$file\";\n";
    my $instfile = $file;
    $instfile =~ s/plib\///;
    print CS "InstallAs \$env \"\$installlib/$instfile\", \"blib/$file\";\n";
    push @ppods,"$file";
  }
}
  
=pod

* BinTargs()

Add binary targets to Conscript (run by WriteCS, mainly for internal use.)
 BinTargs( );

=cut

sub BinTargs {
  &DirSearch("bin");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    next if ($file =~ /\.consign$/);
    print CS "Cp \$env \"blib/$file\", \"$file\";\n";
    my $instfile = $file;
    $instfile =~ s/bin\///;
    print CS "InstallAs \$env \"\$installbin/$instfile\", \"blib/$file\";\n";
    push @ppods,"$file";
  }
}
=pod

* PScriptTargs()

Add perl script targets to Conscript (run by WriteCS, mainly for internal use.)
 ScriptTargs( );

=cut

sub PScriptTargs {
  &DirSearch("pscripts");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    next if ($file =~ /\.consign$/);
    print CS "Cp \$env \"blib/$file\", \"$file\";\n";
    my $instfile = $file;
    $instfile =~ s/pscripts\///;
    print CS "InstallAs \$env \"\$installbin/$instfile\", \"blib/$file\";\n";
    push @ppods,"$file";
  }
}


=pod

* DocTargs()

Add documentation targets to Conscript (run by WriteCS, mainly for 
internal use.)
 DocTargs( );

=cut

sub DocTargs {
  # Preformatted manpage targets.
  if ((-d "man1") || (-d "man2") || (-d "man3")) {
    &DirSearch("man1") if (-d "man1");
    &DirSearch("man2") if (-d "man2");
    &DirSearch("man3") if (-d "man3");
    foreach (@dirs) {
      &DirSearch("$_");
    }
    foreach my $file (@files) {
      print CS "Cp \$env \"blib/$file\", \"$file\";\n";
      if ($file =~ /(.+)\/(.+)/) {
        print CS "InstallAs \$env \"\$install$1/$2\", \"$file\";\n";
      }
    }
  }
  &DirCleanUp;
  # Add "pod" directory.
  &DirSearch("pod") if (-d "pod");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    push @ppods,"$file";
  }
  # Format Pod docs into manpages.
  if (@ppods) {
    foreach my $file (@ppods) {
      # Open file.
      open(PP,$file);
      # Check if any actual POD docs are in there.
      while (<PP>) {
        # I'm sure you have at least this.
        next unless 
        (($_ =~ /\=cut$/) || ($_ =~ /\=pod$/) || ($_ =~ /\=head1/));
        $pod = 1;
      }
      close(PP);
      next unless ($pod); # If not, move along.
      # Get a doc name from the name and path, for example: 
      # blib/plib/Foo/Bar.pm -> blib/man3/Foo::Bar.3
      $doc = "$file";
      # Directories.
      $doc =~ s/plib\///;
      $doc =~ s/pod\///;
      $doc =~ s/lib\///;
      $doc =~ s/pscripts\///;
      # Extensions.
      $doc =~ s/\.pod//;
      $doc =~ s/\.pm//;
      # Subdirs.
      $doc =~ s/\//::/g;
      # Name.
      $manname = uc($doc);
      # Section 1 or 3.
      if ($file =~ /\.pm$/) {
        $sect = "3pm";
      } else {
         $sect = "1";
      }
      # Now add the target.
      print CS "Pod2Man \$env \"blib/man$sect/$doc.$sect\", \"blib/$file\", \"$manname\";\n";
      if ($sect eq "3pm") {
        print CS "InstallAs \$env \"\$installman3/$doc.$sect\", \"blib/man$sect/$doc.$sect\";\n";
      } else {
        print CS "InstallAs \$env \"\$installman1/$doc.$sect\", \"blib/man$sect/$doc.$sect\";\n";
      }
      undef $doc;
      undef $pod; # Just so we don't take all from here on as POD.
    }
  }
}

1;

=pod

=head1 COPYRIGHT

Copyright (c) 2007 Michael Howell. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<AutoCons::HOWTO::C(1)> L<AutoCons::HOWTO::Perl(1)> L<AutoCons::HOWTO(1)> L<AutoCons::ConfigH(3)>

L<cons(1)> L<perl(1)>

=cut
