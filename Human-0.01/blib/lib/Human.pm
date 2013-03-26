package Human;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

sub new{
  my ($class, %params) = @_;
  return bless({
    bear => $params{bear}
  }, $class);
}

sub bear{ return shift->{bear}; }

1;