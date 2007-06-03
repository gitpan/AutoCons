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

AutoCons::AC contains common information in AutoCons.

=head2 FUNCTIONS

=cut

# Make sure there isn't anything stupid in here, but don't worry about
# global variables.
use strict;
use File::Find;
if (eval "require YAML") { require YAML; }
no strict "vars";

$VERSION = 0.01_03;
$XS_VERSION = $VERSION;

# List files if a directory.

=pod

* DirSearch()

Get list of files in a directory.
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

Clean up variables set by DirSearch.
 DirCleanUp( );

=cut

sub DirCleanUp {
  close(DIR);
  undef @files;
  undef @dirs;
}

=pod

* Prompt()

Ask the user for input.
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

Ask the user for input.
 MkDist( );

=cut

sub MkDist {
  # Check for "officially supported" distribution makers.
  #   Module::Build 'Build.PL'
  if ((-f 'Build.PL') && (! $nodrive)) {
    if (! -f 'Build') {
      print "$^X Build.PL\n" if ($0 eq "cons");
      system("$^X Build.PL");
    }
    &MkMS;
    print "$^X Build manifest\n" if ($0 eq "cons");
    system("$^X Build manifest");
    print "$^X Build dist\n" if ($0 eq "cons");
    system("$^X Build dist");
  #   Standard ExtUtils::MakeMaker (I don't list this 1st because of Module::Build::Compat.)
  } elsif ((-f "Makefile.PL") && (! $nodrive)) {
    if (! -f 'Makefile') {
      print "$^X Makefile.PL\n" if ($0 eq "cons");
      system("$^X Makefile.PL");
    }
    &MkMS;
    print "make dist\n" if ($0 eq "cons");
    system("make dist");
  # ...or if there isn't any.
  } else {
    # We need these to build a dist package.
    # We don't set them as needed since they aren't needed otherwise.
    $name = Prompt("Name?")        unless ($name);
    $ver  = Prompt("Version?")     unless ($ver);
    $auth = Prompt("Author?")      unless ($auth);
    $desc = Prompt("Description?") unless ($disc);
    if (eval "require YAML") {
      print "Creating META.yml...\n";
      open(MYML,">META.yml");
      print MYML
      YAML::Dump({"meta-spec" => {"version" => "1.3", "url" => 
"http://module-build.sourceforge.net/META-spec-v1.3.html"}, "name" => $name,"version" => $ver, "abstract" => $desc, "author" => $auth, "license" => "unknown", "generated_by" => "AutoCons version $VERSION"});
    }
    if (! -f "MANIFEST") {
      if (! -f "MANIFEST.SKIP") {
        &MkMS;
      }
      print "Writing MANIFEST...\n";
      use ExtUtils::Manifest qw(mkmanifest);
      mkmanifest();
    }
    print "Creating $name-$ver.tar.gz...\n";
    use ExtUtils::Manifest qw(maniread manicopy);
    manicopy( maniread(), "$name-$ver" );
    make_tarball("$name-$ver");
  }
  1;
}

sub make_tarball {
  my ($dir, $file) = @_;
  $file ||= $dir;
  if (-x "/bin/tar") {
    print "tar -cvf $file.tar $dir\n" if ($0 eq "cons");
    system("tar -cvf $file.tar $dir");
    print "gzip $file.tar\n" if ($0 eq "cons");
    system("gzip $file.tar");
  } else {
    unless (eval "require Archive::Tar") { 
        die "We need Archive::Tar to build a dist.";
    }
    # Archive::Tar versions >= 1.09 use the following to enable a compatibility
    # hack so that the resulting archive is compatible with older clients.
    $Archive::Tar::DO_NOT_USE_PREFIX = 0;
    my $files = rscan_dir($dir);
    print "[TAR] $file.tar.gz\n" if ($0 eq "cons");
    Archive::Tar->create_archive("$file.tar.gz", 1, @$files);
  }
}

sub rscan_dir {
  my ($dir, $pattern) = @_;
  my @result;
  use File::Find;
  local $_; # find() can overwrite $_, so protect ourselves
  my $subr = !$pattern ? sub {push @result, $File::Find::name} :
             !ref($pattern) || (ref $pattern eq 'Regexp') ? sub {push @result, $File::Find::name if /$pattern/} :
             ref($pattern) eq 'CODE' ? sub {push @result, $File::Find::name if $pattern->()} :
             die "Unknown pattern type";

  File::Find::find({wanted => $subr, no_chdir => 1}, $dir);
  return \@result;
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
# Avoid cons/AutoCons files.
\.consign$ 
\bConstruct$

'; close(MS);
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

Copyright (c) 2007 Michael Howell. All rights reserved.                         
This program is free software; you can redistribute it and/or             
modify it under the same terms as Perl itself.                

=head1 SEE ALSO

L<AutoCons::HOWTO::C(1)> L<AutoCons::HOWTO::Perl(1)> 
L<AutoCons::HOWTO(1)> L<AutoCons(3)>

L<cons(1)> L<perl(1)>

=cut
