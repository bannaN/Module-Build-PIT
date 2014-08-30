use strict;
use warnings;

use Test::More;

BEGIN {
  eval { require Test::Kwalitee; };
  plan( skip_all => 'AUTHOR_TEST must be set for kwalitee test; skipping' )
    if ( !$ENV{'AUTHOR_TEST'} );

  plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
}

Test::Kwalitee->import();

__END__

