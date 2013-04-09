use strict;
use warnings;
use Test::More tests => 2;

use_ok('Params::Check');

cmp_ok( $Params::Check::VERSION, 'eq', '0.36', 'Params::Check is version 0.36' );
