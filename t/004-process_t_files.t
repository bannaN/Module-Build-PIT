use warnings;
use strict;

use Test::More tests => 5;
use Test::MockObject::Extends;
use Test::Exception;
use File::Spec;
use Cwd qw(abs_path);

use_ok('Module::Build::PIT');

my $mbp = Module::Build::PIT->new( dist_name => 'Human', dist_version => '0.01', module_name => 'Human', tests => 't/Modules/Human-0.01/t' );

{    #Without the env set. The method should return undef.
  local $ENV{'PERL_INSTALL_TESTS'} = undef;
  ok( !$mbp->process_t_files(), 'Returns undef when $ENV{PERL_INSTALL_TESTS} is not set' );
}

{
  local $ENV{'PERL_INSTALL_TESTS'} = 1;

  my ( $base_dir, $file ) = ( undef, __FILE__ );
  my $relfile = File::Spec->catfile(qw/t 004-process_t_files.t/);
  $file = Cwd::abs_path($file);
  ( $base_dir = $file ) =~ s/\Q$relfile\E$//;

  my $mbp_mocked = Test::MockObject::Extends->new($mbp);

  #Hack for setting the base_dir correct
  $mbp_mocked->mock(
    'base_dir',
    sub {
      #Since the .t files is in the /t directory, the base_dir() method will falsly say that
      # /a/b/c/t is the base dir, while it actually is /a/b/c
      return $base_dir;
    }
  );

  my @expected = (
    { from => 't/Modules/Human-0.01/t/00-human.t',                  to => 'blib/lib/auto/tests/Human-0.01/t/Modules/Human-0.01/t/00-human.t' },
    { from => 't/Modules/Human-0.01/t/moretests/01-human-retest.t', to => 'blib/lib/auto/tests/Human-0.01/t/Modules/Human-0.01/t/moretests/01-human-retest.t' }
  );

  $mbp_mocked->mock(
    'copy_if_modified',
    sub {
      my ( $self, %params ) = @_;
      is_deeply( \%params, shift @expected, "Correct params passed to copy_if_modified" );
    }
  );

  ok( $mbp->process_t_files(), 'process_t_files returns true' );

}

