##############################################################################
#
# Class::SelfMethods - a Module for supporting instance-defined methods
#
# Author: Toby Everett
# Revision: 1.0
# Last Change: Released
##############################################################################
# Copyright 1999 Toby Everett, 1999 Damian Conway.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
#
# Damian Conway, damian@cs.monash.edu.au, was responsible for the _SET
# accessor code.
##############################################################################

package Class::SelfMethods;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

$VERSION = '1.01';


sub AUTOLOAD {
  my $self = shift;
  my(@params) = @_;

  (my $func = $AUTOLOAD) =~ s/^.*:://;

  $func =~ s/_SET$// and return $self->{$func} = $params[0];
  $func =~ s/_CLEAR$// and return delete $self->{$func};

  if (exists $self->{$func}) {
    if (ref ($self->{$func}) eq 'CODE') {
      return $self->{$func}->($self, @params);
    } else {
      return $self->{$func};
    }
  } else {
    my $undercall = "_$func";
    $self->can($undercall) and return $self->$undercall(@params);
    return;
  }
}

sub new {
  my $class = shift;
  my(%params) = @_;

  my %temp_params;
  foreach my $i (keys %params) {
    if ($i =~ /^_/) {
      $temp_params{$i} = $params{$i};
      delete $params{$i};
    }
  }

  my $self = \%params;
  bless $self, $class;

  foreach my $i (keys %temp_params) {
    $self->$i(@{$temp_params{$i}});
  }

  return $self;
}

1;

__END__

=head1 NAME

Class::SelfMethods - a Module for supporting instance-defined methods

=head1 SYNOPSIS

  use Class::SelfMethods;

  package MyClass;
  @ISA = qw(Class::SelfMethods);
  use strict;

  sub _friendly {
    my $self = shift;
    return $self->name;
  }

  package main;
  no strict;

  my $foo = MyClass->new( name => 'foo' );
  my $bar = MyClass->new( name => 'bar', friendly => 'Bar');
  my $bas = MyClass->new( name => 'bas',
                          friendly => sub {
                            my $self = shift;
                            return ucfirst($self->_friendly);
                          }
                        );

  print $foo->friendly, "\n";
  print $bar->friendly, "\n";
  print $bas->friendly, "\n";

  $bas->friendly_SET('a reset friendly');
  print $bas->friendly, "\n";

  $bas->friendly_SET( sub { my $self = shift; return uc($self->_friendly) });
  print $bas->friendly, "\n";

  $bas->friendly_CLEAR;
  print $bas->friendly, "\n";


=head1 DESCRIPTION

C<Class::SelfMethods> merges some features of other Object Oriented languages to build a
system for implementing more flexible objects than is provided by default in Perl.

The core features I was looking for when I wrote C<Class::SelfMethods> were:

=over 4

=item Class-based inheritance hierarchy

I wanted to retain Perl's normal class-based inheritance hierarchy rather than to write (or use) a
completely prototype based system.  If you are looking for a purely prototype based system, see
Sean M. Burke's C<Class::Classless>.  My reasoning on this is that it is easier in file based
languages (as opposed to world based languages like Self) to code class based inheritance
hierarchies (which are largely static) than to code object based inheritance hierarchies (since
objects in such languages have a dynamicism that is not granted to classes).

=item Instance-defined method overriding

I wanted instances to be able to override their class-defined methods.  In the example above,
the C<$bas> object has its own C<friendly> method.  Instance-defined methods are passed the exact
same parameter list as class-defined methods.

=item Subroutine/Attribute equivalence

Borrowing from Self, I wanted to be able to treat methods and attributes similarly.  For instance,
in the above example the C<$bar> object has an attribute C<friendly>, whereas the C<$bas> object
has a method C<friendly>, and the C<$foo> object uses the class-defined method.  The calling
syntax is independent of the implementation.  Parameters can even be passed in the method call and
they will simply be ignored if the method is implemented by a simple attribute

=back

In addition to those core features, I (and Damian) had a wish list of additional features:

=over 4

=item Simple syntax

I wanted the system to be reasonable easy to use for both implementers of classes and users of
objects.  Simple syntax for users is more important than simple syntax for implementers.

=item Full support for C<SUPER> type concepts

I wanted instance-defined methods to be able to call the class-defined methods they replace.

=item Support for calling methods at instantiation time

In some circumstances, rather than deal with multiple inheritance it is easier to have a
class-defined object method that sets up the various instance-defined methods for a given object.
To support this, the C<new> method allows deferred method calls to be passed in as parameters.

=item Modifying objects post-instantiation

I originally had no need for modifying objects post-instantiation, but Damian Conway thought it
would be a Good Thing (TM) to support.  Being so very good at these sorts of thing, he instantly
came up with a good general syntax to support such.  Method calls that end in a C<_SET> result in
the first parameter being assigned to the attribute/method.  I noticed one remaining hole and
added support for C<_CLEAR>.

=back

=head1 HOW TO

=head2 Write A Class

Your class should inherit from C<Class::SelfMethods>.  The class-defined instance methods
should be B<defined with> a leading underscore and should be B<called without> a leading
underscore.  Don't do anything silly like writing methods whose proper names have a leading
underscore and whose definitions have two leading underscores - that's just asking for trouble.

Do B<not>, of course, make use of attributes that have leading underscores - that's also just
asking for trouble.  Also, do not access attributes directly (i.e. C<$self-E<gt>{foo}>).  That
will prevent people who use your class from substituting a method for an attribute.  Instead,
always read attributes by making the corresponding method call (C<$self-E<gt>foo>).

If you need to call C<SUPER::methodname>, call C<SUPER::_methodname>.

=head2 Create An Instance

The default C<new> method uses named parameters.  Unless you are certifiable, you will too.  To
specify attributes, simply use the syntax C<name =E<gt> 'value'> and to specify a method use
C<name =E<gt> sub { my $self = shift; . . . }>.  Note that methods and attributes are
interchangeable.

=head2 Modify An Instance

Method calls that end in a C<_SET> will result in their first parameter being assigned to the
appropriate attribute/method.  For instance, in the C<SYNOPSIS> I use C<$foo-E<gt>friendly_SET> to
specify both a value and a method for C<friendly>.  Method calls that end in a C<_CLEAR> will
delete that attribute/method from the object.

=head2 Installation instructions

Standard module installation procedure.

=head1 INTERNALS

=head2 AUTOLOAD

This is the heart of the system.  Every method call passes through C<AUTOLOAD> because the method
is called without the leading underscore, but is defined in the class hierarchy with the leading
underscore.

C<AUTOLOAD> starts by stripping off the module name from C<$AUTOLOAD>.  It checks first for
C<_SET> and C<_CLEAR> method calls and does the right thing in those situations.  If it's a normal
method call, it then searches for an entry in C<$self>'s hash with that name.  If it finds one and
it is not a C<CODE> reference, it returns the value.  If it is a C<CODE> reference, it calls the
subroutine passing it C<$self> and whatever parameters C<AUTOLOAD> was originally passed.  If it
doesn't find an entry in the hash, it prepends an underscore to the method name and uses C<can> to
test whether the object is capable of handling the method call.  If it is, C<AUTOLOAD> calls the
method (with the leading underscore) and passes it whatever parameters C<AUTOLOAD> was originally
passed.  If not, it returns silently (this is designed to mimic a non-existent hash entry).

=head2 new

The C<new> method supplied in C<Class::SelfMethods> provides one interesting twist on an
otherwise standard named parameters constructor.  It strips out any passed parameters that have
leading underscores and stores them away.  It then creates the hash ref from the remaining
parameters and blesses it appropriately.  Finally, it takes the stored parameters that have
leading underscores and makes the matching method calls - the key is used for the method name and
the value is dereferenced to an array and passed as parameters.

=head1 AUTHOR

Toby Everett, teverett@alascom.att.com

=head1 CREDITS

=over 4

=item Damian Conway, damian@cs.monash.edu.au

Responsible for accessor methods, module name, constructive criticism and moral support.  He also
wrote an excellent book, Object Oriented Perl, that is a must read.

=back

=cut

