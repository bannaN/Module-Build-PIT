use strict;
use warnings;
use Test::More tests => 5;
use Test::Warn;

use_ok('Human');
use_ok('Bear');

my $obj = Human->new( bear => Bear->new() );

isa_ok( $obj, 'Human' );

isa_ok( $obj->bear(), 'Bear' );

warning_is {
  $obj->bear()->ride();
}
"You are riding a bear!", "Riding a bear gives a warning";
