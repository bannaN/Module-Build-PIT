use warnings;
use strict;

use Test::More tests => 3;
use Test::MockObject::Extends;

use ExtUtils::Installed;

use_ok('Module::Build::PIT');

my $ei = ExtUtils::Installed->new();
my $mbp = Module::Build::PIT->new( dist_name => 'Bear', dist_version => '0.02', module_name => 'Bear' );


my $ei_mocked = Test::MockObject::Extends->new( $ei );
$ei_mocked->mock('modules', sub{
  return qw( Module::A Module::B Module::C Human Bear);  
});

$ei_mocked->mock('files', sub{
  my ($self, $module) = @_;
  
  my %packlists = (
    Human => [
      '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/Human.pm',
      '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/00-human.t',
      '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/moretests/01-human-retest.t'
    ],
    Bear => [
      '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/Bear.pm',
      '/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Bear-0.01/t/00-bear.t'
    ]
  );

  return (exists $packlists{$module}) ? @{$packlists{$module}} : undef;
});

my $mbp_mocked = Test::MockObject::Extends->new( $mbp );
$mbp_mocked->mock('_get_ext_installed_obj', sub{
  return $ei_mocked;
});

my @test_files = $mbp_mocked->_find_installed_test_files();

is_deeply(\@test_files, [
  ['/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/00-human.t', 'Human-0.01/t/00-human.t'],
  ['/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/moretests/01-human-retest.t', 'Human-0.01/t/moretests/01-human-retest.t'],
  ['/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Bear-0.01/t/00-bear.t', 'Bear-0.01/t/00-bear.t']
], "List of testfiles is as expected");

@test_files = $mbp_mocked->_find_installed_test_files('Human');

is_deeply(\@test_files, [
  ['/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/00-human.t', 'Human-0.01/t/00-human.t'],
  ['/home/user1/.perlbrew/libs/perl-5.16.2@qa-hack-ex/lib/perl5/auto/tests/Human-0.01/t/moretests/01-human-retest.t', 'Human-0.01/t/moretests/01-human-retest.t'],
], "List of testfiles is as expected for module Human");


