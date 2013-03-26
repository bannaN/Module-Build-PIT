use Test::More tests => 5;
use Test::Warn;

use_ok('Human');

my $obj = Human->new();

isa_ok($obj, 'Human');
