use strict;
use warnings;

use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

BEGIN {
  plan( skip_all => 'AUTHOR_TEST must be set for boilerplate test; skipping' )
    if ( !$ENV{'AUTHOR_TEST'} );

  eval "use Test::Strict";
  plan( skip_all => 'Test::Strict not installed; skipping' ) if $@;
}

all_perl_files_ok(qw/lib script/);

__END__

