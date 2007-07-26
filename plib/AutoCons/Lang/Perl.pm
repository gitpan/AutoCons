##PERL.PM##
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

AutoCons::Lang::Perl - Perl-specific targets.

=head1 SYNOPSIS

use AutoCons::Lang::Perl;

=head1 DESCRIPTION

AutoCons is a cons Construct generator similar to ExtUtils::MakeMaker or
Gnu Autoconf, except that cons is far more portable than make. For the
developer, this means that your program will build on any system that cons
will. For a user, this means that you don't need a "make" program to build
your program.

This module contains Perl-specific code for AutoCons.

=head2 FUNCTIONS

=cut

# Have AutoCons.pm run these.
push @Targs, "XSTargs", "PLibTargs", "PScriptTargs";
push @Args,  "PerlArgs";
push @Vars,  "PerlVars";

=pod

* PerlArgs

Process Perl-specific WriteCS arguments. All arguments can be passed to WriteCS.
 PerlArgs(
   PreReqs => [ # Optional.
     <MOD>,
     ...
   ],
 );

=cut

sub PerlArgs {
  my %Args = @_;
  @prereqpm = @{$Args{ PreReqs }} if ($Args{ PreReqs });
  # Check for prereqs.
  if (@prereqpm) {
    foreach my $mod (@prereqpm) {
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
  # Handle type.
  if ($type eq "site") {
    $installplib  = $Config{ installsitelib };
    $installparch = $Config{ installsitearch };
  } elsif ($type eq "vendor") {
    $installplib  = $Config{ installvendorlib };
    $installparch = $Config{ installvendorarch };
  } else {
    $installplib  = $Config{ installprivlib };
    $installparch = $Config{ installarchlib };
  }
}

=pod

* PerlVars()

Add Perl-specific variables.

 PerlVars( )

=cut

sub PerlVars {
  Var("installplib", "$installplib");
  Var("installparch", "$installparch");
}

=pod

* XSTargs()

Add targets for PerlXS (Perl bindings to C).
 XSTargs( )

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
    Targ("Command", "blib/$cfile", "$file", "xsubpp $file >blib/$cfile");
    Targ("Objects", "blib/$cfile");
    my $instfile = $ofile;
    $instfile =~ s/plib\///;
    Targ("InstallAs", "\$installparch/$instfile", "blib/$ofile");
  }
}

=pod

* PLibTargs()

Add perl module targets to Conscript.
 PLibTargs( );

=cut

sub PLibTargs {
  &DirSearch("plib");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    next if ($file =~ /\.consign$/);
    next if (($file !~ /\.pm$/) && ($file !~ /\.pod$/));
    Targ("Cp", "blib/$file", "$file");
    my $instfile = $file;
    $instfile =~ s/plib\///;
    Targ("InstallAs","\$installplib/$instfile", "blib/$file");
    push @ppods,"$file";
    open(FILE, "$file");
    while (<FILE>) {
      if ($_ =~ /^use Inline/) {
        my $inl = $file;
        $inl =~ s/\.pm/\.inl/;
        $inl =~ s/plib\///;
        my $moname = $file;
        $moname =~ s/\//::/g;
        $moname =~ s/plib:://;
        $moname =~ s/\.pm//;
        Targ("Command", "blib/inl/$inl", "blib/$file", "$^X -Mlib=blib/plib -MInline=_INSTALL_ -M$moname -e1 $ver blib/inl");
      }
    }
  }
  print CS <<"  END"
# Install precompiled Inline.
DirSearch(\"blib/arch\");
foreach (\@dirs)  {DirSearch(\"\$_\");}
foreach (\@files) {
  my \$file = \$_;
  \$file =~ s/blib\\/arch//;
  InstallAs \$env \"\$installparch/\$file\", \"\$_\";
}
  END
}

=pod

* PScriptTargs()

Add perl script targets to Conscript.
 ScriptTargs( );

=cut

sub PScriptTargs {
  &DirSearch("pscripts");
  foreach (@dirs) {
    &DirSearch("$_");
  }
  foreach my $file (@files) {
    next if ($file =~ /\.consign$/);
    Targ("Cp", "blib/$file", "$file");
    my $instfile = $file;
    $instfile =~ s/pscripts\///;
    Targ("InstallAs", "\$installbin/$instfile", "blib/$file");
    push @ppods,"$file";
  }
}

1;

