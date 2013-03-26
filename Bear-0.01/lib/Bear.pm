package Bear;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

sub new{ bless({}, __PACKAGE__); }

sub ride{ warn "You are riding a bear!"; }
1;