use warnings;
use strict;

use Test::More tests => 5;
use Test::MockObject::Extends;
use Test::Exception;

{

  package Fake::Aggregator;
  sub new { bless( { retval => $_[1] }, 'Fake::Aggregator' ); }
  sub has_errors { return shift->{retval} }
}

use_ok('Module::Build::PIT');

my $mbp = Module::Build::PIT->new( dist_name => 'Bear', dist_version => '0.02', module_name => 'Bear' );
my $mbp_mocked = Test::MockObject::Extends->new($mbp);

$mbp_mocked->mock(
  '_find_installed_test_files',
  sub {
    return (
      [ '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/00-human.t', 'Human-0.01/t/00-human.t' ],
      [
        '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/moretests/01-human-retest.t',
        'Human-0.01/t/moretests/01-human-retest.t'
      ],
      [ '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Bear-0.01/t/00-bear.t', 'Bear-0.01/t/00-bear.t' ]
    );
  }
);

$mbp_mocked->mock(
  'find_test_files',
  sub {
    return [ 't/00-test1.t', 't/01-test2.t', 't/02-test3.t', 't/03-test4.t', 't/04-test5.t' ];
  }
);

$mbp_mocked->mock(
  'run_tap_harness',
  sub {
    my ( $self, $tests ) = @_;

    is_deeply(
      $tests,
      [
        [ '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/00-human.t', 'Human-0.01/t/00-human.t' ],
        [
          '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/moretests/01-human-retest.t',
          'Human-0.01/t/moretests/01-human-retest.t'
        ],
        [ '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Bear-0.01/t/00-bear.t', 'Bear-0.01/t/00-bear.t' ],
        't/00-test1.t',
        't/01-test2.t',
        't/02-test3.t',
        't/03-test4.t',
        't/04-test5.t'
      ],
      "List of test files passed to run_tap_harness"
    );

    return Fake::Aggregator->new(undef);

  }
);

lives_ok { $mbp_mocked->ACTION_testinc() } "ACTION_testinc lives";

$mbp_mocked->mock(
  'run_tap_harness',
  sub {
    my ( $self, $tests ) = @_;

    is_deeply(
      $tests,
      [
        [ '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/00-human.t', 'Human-0.01/t/00-human.t' ],
        [
          '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/moretests/01-human-retest.t',
          'Human-0.01/t/moretests/01-human-retest.t'
        ],
        [ '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Bear-0.01/t/00-bear.t', 'Bear-0.01/t/00-bear.t' ],
        't/00-test1.t',
        't/01-test2.t',
        't/02-test3.t',
        't/03-test4.t',
        't/04-test5.t'
      ],
      "List of test files passed to run_tap_harness"
    );

    return Fake::Aggregator->new(1);

  }
);

throws_ok { $mbp_mocked->ACTION_testinc() } qr/Errors in testing. Cannot continue/, 'Throws exception when there is an error in the tests';
