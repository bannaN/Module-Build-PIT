use strict;
use warnings;

use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

BEGIN {
  plan( skip_all => 'AUTHOR_TEST must be set for coverage test; skipping' )
    if ( !$ENV { 'AUTHOR_TEST' } );

  eval "use Test::Strict";
  plan( skip_all => 'Test::Strict not installed; skipping' ) if $@;

}

#$Test::Strict::DEVEL_COVER_OPTIONS = '+ignore,"/Test/Strict\b","t/Modules"';

TODO: {
  local $TODO = "Figure out how to exclude the files under t/Modules properly";

  fail("cover is failing");
  #all_cover_ok( 80 );  # at least 80% coverage
};

done_testing();
__END__

