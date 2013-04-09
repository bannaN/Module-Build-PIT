use Test::More tests => 2;

use_ok('Bear');

my $obj = Bear->new();

isa_ok( $obj, 'Bear' );
