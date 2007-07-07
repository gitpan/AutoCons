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

AutoCons::ConfigH - Write a Config.h for C programs.

=head1 SYNOPSIS

use AutoCons::ConfigH;
Configh();

=head1 DESCRIPTION

AutoCons is a cons Construct generator similar to ExtUtils::MakeMaker or Gnu Autoconf,
except that cons is far more portable than make. For the developer, this
means that your program will build on any system that cons will.
For a user, this means that you don't need a "make" program to build your program.

AutoCons::ConfigH automatically generates a Config.h file, including ALL 
of the information included in the Config.pm file that comes with perl. It 
will also add any extra info that you give it.

=head2 FUNCTIONS

=cut

# Set up package.
package AutoCons::ConfigH;
require Exporter;
@ISA = (Exporter);
@EXPORT = qw(ConfigH);
use vars qw($VERSION);

# Make sure there isn't anything stupid in here, but don't worry about 
# global variables.
use strict;
no strict "vars";
# Load in what I need.
use Config;
# In case we are under a 'boxed' install.
use AutoCons::AC;

=pod

* ConfigH()

Create a Config.h. This file will contain all variables defined by
Config.pm (over 900 values), as well as anything else you add.

 ConfigH(
   <ADDITIONAL CODE>
 );

=cut

sub ConfigH {
  print "Writing Config.h...\n";
  open(CH,">Config.h");
  print CH "/* Generated by $0 */\n";
  my @Configks = keys %Config;
  foreach (@Configks) {
    print CH "#define $_ \"$Config{ $_ }\"\n";
  }
  foreach (@_) {
    print CH "$_\n";
  }
}

1;

=pod   

=head1 COPYRIGHT

Copyright (c) 2007 Michael Howell. All rights reserved.              
This program is free software; you can redistribute it and/or        
modify it under the same terms as Perl itself.                

=head1 SEE ALSO

L<AutoCons::HOWTO::C(1)> L<AutoCons(3)>

L<cons(1)> L<perl(1)>

=cut
