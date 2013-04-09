use warnings;
use strict;

use Test::More tests => 1;
use Config;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

BEGIN {
  use_ok('Module::Build::PIT');
}

diag("Testing Module::Build::PIT $Module::Build::PIT::VERSION, Perl $], $^X, archname=$Config{archname}, byteorder=$Config{byteorder}");

__END__
