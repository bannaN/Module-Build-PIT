use warnings;
use strict;

use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 2;

use_ok ('Module::Build::PIT');

my $obj = Module::Build::PIT->new(module_name => 'Module::Build::PIT');
isa_ok($obj, q{Module::Build::PIT}, q{Expect a Module::Build::PIT object});

__END__

