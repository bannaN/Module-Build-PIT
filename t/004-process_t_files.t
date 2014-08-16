use warnings;
use strict;

use Test::More tests => 5;
use Test::MockObject::Extends;
use Test::Exception;
use File::Spec;
use Cwd qw(abs_path);

use_ok('Module::Build::PIT');

my $mbp = Module::Build::PIT->new( dist_name => 'Human', dist_version => '0.01', module_name => 'Human');

{    #Without the env set. The method should return undef.
  local $ENV{'PERL_INSTALL_TESTS'} = undef;
  ok( !$mbp->process_t_files(), 'Returns undef when $ENV{PERL_INSTALL_TESTS} is not set' );
}

{
  local $ENV{'PERL_INSTALL_TESTS'} = 1;

  my ( $base_dir, $file ) = ( undef, __FILE__ );
  $file = Cwd::abs_path($file);
  my $relfile = File::Spec->catfile(qw/004-process_t_files.t/);
  
  ( $base_dir = $file ) =~ s/\Q$relfile\E$//;
  $base_dir = File::Spec->catdir($base_dir, qw( Modules Human-0.01 ) );

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
    { from => 'Human-0.01.tar.gz', to => 'blib/lib/auto/tests/Human-0.01.tar.gz' },
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

