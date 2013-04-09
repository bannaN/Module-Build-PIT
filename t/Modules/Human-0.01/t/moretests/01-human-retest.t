use strict;
use warnings;
use Test::More tests => 2;
use Test::Warn;

use_ok('Human');

my $obj = Human->new();

isa_ok( $obj, 'Human' );
