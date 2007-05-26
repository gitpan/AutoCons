# AutoCons common code.

=head1 NAME

AutoCons::AC - Common information used in AutoCons.

=head1 SYNOPSIS

use AutoCons::AC;
print "Using AutoCons $VERSION...\n";

=head1 DESCRIPTION

AutoCons is a cons Construct generator similar to ExtUtils::MakeMaker or 
Gnu Autoconf except that cons is far more portable than make. For the 
developer, this means that your program will build on any system that cons 
will. For a user, this means that you don't need a "make" program to build 
your program.

AutoCons::Settings contains common information in AutoCons.

=head2 FUNCTIONS

=cut

# Make sure there isn't anything stupid in here, but don't worry about
# global variables.
use strict;
no strict "vars";

$VERSION = 0.01_01;
$XS_VERSION = $VERSION;

# List files if a directory.

=pod

* DirSearch()

Get list of files in a directory (run by WriteCS, mainly for internal 
use.)
 DirSearch("<DIRECTORY>");
 foreach (@dirs)  {< DO SOMETHING >}
 foreach (@files) {< DO SOMETHING >}

=cut

sub DirSearch {
  $dir = $_[0];
  opendir(DIR,$dir);
  while ($filename = readdir(DIR)) {
    next if ($filename eq ".");
    next if ($filename eq "..");
    push @files,"$dir/$filename" if (-f "$dir/$filename");
    push @dirs,"$dir/$filename" if (-d "$dir/$filename");
  }
  close(DIR);
}

=pod

* DirCleanUp()

Clean up variables set by DirSearch (run by WriteCS, mainly for internal
use.)
 DirCleanUp( );

=cut

sub DirCleanUp {
  close(DIR);
  undef @files;
  undef @dirs;
}

=pod

* Prompt()

Ask the user for input (run by WriteCS, mainly for internal use.)
 $answ = Prompt("<MESSAGE>");

=cut

sub Prompt {
  my $msg = $_[0];
  print "$msg\n:";
  my $ans = <>;
  chomp $ans;
  return $ans;
}

=pod

* MkDist()

Ask the user for input (run by WriteCS, mainly for internal use.)
 MkDist("<NAME>", "<VER>");

=cut

sub MkDist {
  # Get args.
  my($name, $ver) = @_;
  # Check for "officially supported" distribution makers.
  if (-f 'Build.PL') {
    if (! -f 'Build') {
      print "$^X Build.PL\n" if ($0 eq "cons");
      system("$^X Build.PL");
    }
    &MkMS;
    print "$^X Build manifest\n" if ($0 eq "cons");
    system("$^X Build manifest");
    print "$^X Build dist\n" if ($0 eq "cons");
    system("$^X Build dist");
    return 1;
  } elsif (-f "Makefile.PL") {
    if (! -f 'Makefile') {
      print "$^X Makefile.PL\n" if ($0 eq "cons");
      system("$^X Makefile.PL");
    }
    &MkMS;
    print "make dist\n" if ($0 eq "cons");
    system("make dist");
    return 1;
    # Try to drive Module::Build.
  } elsif (eval "use Module::Build; 1") {
    # Search for PMs and PODs.
    DirSearch("plib");
    DirSearch("pod");
    foreach (@dirs) {
      DirSearch($_);
    }
    foreach (@files) {
      if (/\.pm/) {
        s/plib/lib/;
        $pm{"p$_"} = $_;
      } elsif (/\.pod/) {
        s/plib/lib/;
        $pods{"p$_"} = $_;
      }
    }
    # Get info from user.
    my $name = Prompt("Name?")        unless ($name);
    my $ver  = Prompt("Version?")     unless ($ver);
    my $auth = Prompt("Author?")      unless ($auth);
    my $desc = Prompt("Description?") unless ($disc);
    my $build = Module::Build->new (
      module_name => "$name",
      dist_version => "$ver",
      dist_author => "$auth",
      dist_abstract => "$desc",
      pm_files => {%pm},
      pod_files => {%pods}
    );
    &MkMS;
    $build->dispatch('manifest');
    $build->dispatch('dist');
    return 1;
  } else {
    # All right... I'll do it myself.
    my $name = Prompt("Name?")        unless ($name);
    my $ver  = Prompt("Version?")     unless ($ver);
    my $auth = Prompt("Author?")      unless ($auth);
    my $desc = Prompt("Description?") unless ($disc);
    if (! -f "MANIFEST") {
      if (! -f "MANIFEST.SKIP") {
        &MkMS;
      }
      print "Writing MANIFEST...\n";
      use ExtUtils::Manifest qw(mkmanifest);
      mkmanifest();
    }
    print "Creating $name-$ver.tar.gz...\n";
    open(MANIFEST, "MANIFEST");
    while (<MANIFEST>) {
      if (/^([^\s]+)\s(.+)/) {
        push @files, $1;
      } else {
        chomp $_;
        push @files, $_;
      }
    }
    use Archive::Tar;
    Archive::Tar->create_archive("$name-$ver.tar.gz", 1, @files);
    return 1;
  }
  # Cleanup
  unlink "$name-$ver.tar.gz" if (-f "$name-$ver.tar.gz");
  unlink "Build" if (-f "Build");
  unlink "Makefile" if (-f "Makefile");
}

=pod

* MkMS

Make a MANIFEST.SKIP
 MkMS( )

=cut

sub MkMS {
  print "Writing MANIFEST.SKIP...\n";
  open(MS,">MANIFEST.SKIP");
  print MS '
# Avoid version control files.
\bRCS\b
\bCVS\b
,v$
\B\.svn\b
\B\.cvsignore$
# Avoid Makemaker generated and utility files.
\bMakefile$
\bblib
\bMakeMaker-\d
\bpm_to_blib$
\bblibdirs$
^MANIFEST\.SKIP$
# Avoid Module::Build generated and utility files.   
\bBuild$
\bBuild.bat$
\b_build
# Avoid Devel::Cover generated files
\bcover_db
# Avoid temp and backup files. 
~$
\.tmp$
\.old$
\.bak$
\#$
\.#
\.rej$ 
# Avoid OS-specific files/dirs
#   Mac OSX metadata
\B\.DS_Store  
#   Mac OSX SMB mount metadata files
\B\._
# Avoid archives of this distribution
\b-[\d\.\_]+  
# Don\'t add AutoCons files.
\.consign$ 
Construct$
';
}

=pod

=head3 Cons targets: ONLY WORK IN CONSTRUCTS!!!

=cut

###CONS SUBS###

=pod
  
* Cp()
  
Copy a file.
 Cp $env "<DEST>", <FILE>;

=cut

sub cons::Cp {
  my ($env, $dst, $src) = @_;
  Command $env $dst, $src, qq(
    @ echo "[CP] $dst"
    @ [perl] futil::copy("$src","$dst")
  );
}

=pod

* Pod2Man()

Convert a POD to a manpage.
 Pod2Man $env "<DEST>", <FILE>;

=cut

sub cons::Pod2Man {
  my ($env, $dst, $src, $manname) = @_;
  # Set name.
  if (!$manname) {
    $manname = uc($src);
  }
  Command $env $dst, $src, qq(
    @ echo "[MAN] $manname"
    @ pod2man --name=$manname %< %>
  );
}

=pod   

=head1 COPYRIGHT

Copyright (c) 1995 Michael Howell. All rights reserved.                         
This program is free software; you can redistribute it and/or             
modify it under the same terms as Perl itself.                

=head1 SEE ALSO

L<AutoCons::HOWTO::C(3)> L<AutoCons::HOWTO::Perl(3)> L<AutoCons(3)>

L<cons(1)> L<perl(1)>

=cut
