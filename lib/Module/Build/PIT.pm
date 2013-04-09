package Module::Build::PIT;

use strict;
use warnings;

use base qw(Module::Build);
use ExtUtils::Installed;

our $VERSION = "0.002";

sub test_dirs {
  my $self = shift;
  return ( ref( $self->{properties}->{tests} ) eq 'ARRAY' )
    ? $self->{properties}->{tests}
    : [ $self->{properties}->{tests} ];
}

sub process_t_files {
  my $self = shift;

  return unless $ENV{'PERL_INSTALL_TESTS'};

  my $test_dirs = $self->test_dirs;
  return unless $test_dirs;

  my $prefix = File::Spec->catdir( $self->blib, qw/lib auto tests/, $self->dist_name() . "-" . $self->dist_version() );

  #Search the directories
  my %files;
  for my $dir (@$test_dirs) {
    for my $f ( @{ $self->rscan_dir( File::Spec->catdir( $self->base_dir, $dir ), sub { -f } ) } ) {
      $f =~ s{\A.*\Q$dir\E/}{};
      $files{ File::Spec->catdir( $dir, $f ) } =
        File::Spec->catdir( $prefix, $dir, $f );
    }
  }
  my @keys   = keys %files;
  my @values = values %files;
  while ( my ( $file, $dest ) = each %files ) {
    $self->copy_if_modified( from => $file, to => $dest );
  }
  return 1;
}

sub ACTION_fakeinstall {
  my $self = shift;

  use Data::Dumper;

  if ( $ENV{'PERL_INSTALL_TESTS'} ) {

    my @path = qw/auto tests/;
    my $dir  = File::Spec->catdir( $self->install_destination('lib') );
    for (@path) {
      $dir = File::Spec->catdir( $dir, $_ );
      next if -e $dir;
      die("Cannot create $dir ") if !mkdir($dir);
    }

    my $dist_name = $self->dist_name();

    #Looking for old tests
    opendir( my $dh, $dir ) || die "can't opendir " . $dir . ": $!";
    my @dirs =
      grep { /^$dist_name/ && -d File::Spec->catdir( $dir, $_ ) } readdir($dh);
    closedir $dh;

    my $r;

    if ( scalar( @dirs > 3 ) ) {
      $r = $self->y_n(
        'You have a large number of test for old versions of '
          . $self->dist_name()
          . '. Do you want to delete all the old tests? (This is a fakeinstall. Action will _NOT_ be executed)',
        'y'
      );
    }

    if ($r) {
      print "Deleting " . File::Spec->catdir( $dir, $_ ) for @dirs;
    } else {
      foreach my $ldir (@dirs) {
        if ( $self->y_n( 'Delete ' . File::Spec->catdir( $dir, $ldir ) . '? (This is a fakeinstall. Action will not be executed)', 'y' ) ) {
          print "Deleting " . File::Spec->catdir( $dir, $ldir ) . "\n";
        }
      }
    }

  }

  #Retval is the return structure from ExtUtils::Install::install
  return $self->SUPER::ACTION_fakeinstall(@_);
}

sub ACTION_install {
  my $self = shift;

  $self->depends_on('build');

  use File::Path qw( remove_tree );

  if ( $ENV{PERL_INSTALL_TESTS} ) {

    my @path = qw/auto tests/;
    my $dir  = File::Spec->catdir( $self->install_destination('lib') );
    for (@path) {
      $dir = File::Spec->catdir( $dir, $_ );
      next if -e $dir;
      die("Cannot create $dir ") if !mkdir($dir);
    }

    my $dist_name = $self->dist_name;
    opendir( my $dh, $dir ) || die "can't opendir " . $dir . ": $!";
    my @dirs =
      grep { /^$dist_name/ && -d File::Spec->catdir( $dir, $_ ) } readdir($dh);
    closedir $dh;

    my $r;

    if ( scalar( @dirs > 1 ) ) {
      $r = $self->y_n(
        'You have tests for a large number('
          . scalar(@dirs)
          . ') of versions of '
          . $self->dist_name()
          . ' installed. Do you want to delete all the old tests?',
        'y'
      );
    }
    if ($r) {
      my @del_dirs = map { File::Spec->catdir( $dir, $_ ) } @dirs;
      remove_tree( @del_dirs, { verbose => 1 } );
    } else {
      foreach my $ldir (@dirs) {
        if ( $self->y_n( 'Delete ' . File::Spec->catdir( $dir, $ldir ) . '?', 'y' ) ) {
          remove_tree( File::Spec->catdir( $dir, $ldir ), { verbose => 1 } );
        }
      }
    }
  }

  return $self->SUPER::ACTION_install(@_);
}

sub ACTION_installtests{
  my ($self) = @_;
  
  local $ENV{PERL_INSTALL_TESTS} = 1;
  return $self->depends_on('install');
}

sub _get_ext_installed_obj {
  return ExtUtils::Installed->new();
}

sub _find_installed_test_files {
  my ($self, @wanted_modules) = @_;

  my @test_files = (

    #    [file1, alias1],
    #    [file2, alias2]
  );

  my $inst = $self->_get_ext_installed_obj();
  my (@installed_modules) = $inst->modules();
  my @modules = ();

  if(scalar(@wanted_modules) > 0){
    #keep the duplicates in @installed_modules
    my %wanted = map { $_ => 1 } @wanted_modules;
    foreach my $inst_module (@installed_modules){
      push(@modules, $inst_module) if grep { m/^\Q$inst_module\E$/ } @wanted_modules;
    }
  }else{
    @modules = @installed_modules;
  }

  foreach my $module (@modules) {
    my $path = File::Spec->catdir(qw/auto tests/);

    #Best effort
    my @files = grep { defined && m/$path/ } $inst->files($module);
    next unless scalar(@files) > 0;
    my $dist_name;
    ( $dist_name = $module ) =~ s/::/\-/g;
    push @test_files, map {
      my $alias = $_;
      my $file  = $_;
      $alias =~ s/.*($dist_name\-[\d\.]+)/$1/;
      [ $_, File::Spec->catdir($alias) ]
    } @files;
  }

  return @test_files;
}

sub _find_reverse_dependencies{
  my ($self, $dist_name) = @_;
  
  #A fake method, just to illustrate the command behaviour
  return ('Bear') if $dist_name eq 'Human';
  
  return;
}

sub ACTION_testinc {
  my $self = shift;


  $self->depends_on('code');

  # Protect others against our @INC changes
  local @INC = @INC;

  # Make sure we test the module in blib/
  unshift @INC, (File::Spec->catdir($self->base_dir, $self->blib, 'lib'),
                 File::Spec->catdir($self->base_dir, $self->blib, 'arch'));

  my @tests = ();

  my @installed_tests = $self->_find_installed_test_files();

  push @tests, @installed_tests;
  push @tests, @{ $self->find_test_files };

  my $agg = $self->run_tap_harness( \@tests );
  if ( $agg->has_errors ) {
    die "Errors in testing. Cannot continue.\n";
  }
  return 1;
}

sub ACTION_testrdeps{
  my ($self) = @_;
  
  $self->depends_on('code');

  # Protect others against our @INC changes
  local @INC = @INC;

  # Make sure we test the module in blib/
  unshift @INC, (File::Spec->catdir($self->base_dir, $self->blib, 'lib'),
                 File::Spec->catdir($self->base_dir, $self->blib, 'arch'));  
  
  my @rdeps = $self->_find_reverse_dependencies($self->module_name());
  
  my @tests = ();
  my @installed_tests = $self->_find_installed_test_files(@rdeps);
  
  push @tests, @installed_tests;
  push @tests, @{ $self->find_test_files };
  
  my $agg = $self->run_tap_harness( \@tests );
  if ( $agg->has_errors ) {
    die "Errors in testing. Cannot continue.\n";
  }
  return 1;
  
}

1;

__END__

=pod

=head1 NAME

Module::Build::PIT

Module::Build::PIT (Post Install Test) is an extension to
Module::Build.  It allows you to test CPAN modules already installed
(regression testing) as opposed to just test at install time.  The
main objective is to detect errors and inconsistencies in a production
environment resulting from changes in dependenciecs or the
environment itself.

=head1 SYNOPSIS

  export PERL_INSTALL_TESTS=1
  perl run_lib_tests.pl 

=head1 OPTIONS

None

=head1 DESCRIPTION

This module comes with a proposed directory structure that suggests
all CPAN modules optionally can install their respective test files in
the C<auto> directory.  This allows the test files to be run post
install.  This will allow one to determine that a module (and all of
its dependencies) continue to function as expected once installed. 

The directory structure is as follows: 

C<tree /usr/lib/perl5/auto/>

=head1 EXAMPLE

Imaging two modules I<Human> and I<Bear> both in version 0.01.  There
is a C<Bear::ride> method that I<Human> depends on.  Imagine that
I<Bear> is upgraded to version 0.02 where there is no C<Bear::ride>
method.  This would cause I<Human> to stop functionning. 

Module::Build::PIT aims to detect these kind of I<post install
errors>.

=head1 METHODS

=over 4

=item ACTION_fakeinstall()

The method tries to mimic the actions of a real installation.

It does this by:
- Check if the PERL_INSTALL_TESTS environment variable is set
- Check wheter or not the auto/tests directory exists under your lib install destination
- !! CREATES the auto/tests folders if they do not exists !! (This action is actually executed)
- Reads the auto/tests directory in order to check if you have any old versions of tests for this module
- Asks you if you want to delete the old tests if they exists
- Prints a delete statement if you answer yes to the question above. The delete action is not executed
- Calls the ACTION_fakeinstall method of L<Module::Build>

If the environment variable PERL_INSTALL_TESTS is not set it will just call the ACTION_fakeinstall method of L<Module::Build> 

=item ACTION_install()

This method does the actual install.

- Check if the PERL_INSTALL_TESTS environment variable is set
- Check wheter or not the auto/tests directory exists under your lib install destination
- CREATES the auto/tests folders if they do not exists !! (This action is actually executed)
- Reads the auto/tests directory in order to check if you have any old versions of tests for this module
- Asks you if you want to delete the old tests if they exists, and delete them if you accept
- Calls the ACTION_install method of L<Module::Build>

If the enironment variable PERL_INSTALL_TESTS is not set it will just call the ACTION_install method of L<Module::Build>

=item ACTION_installtests()

Just sets the PERL_INSTALL_TESTS=1 and runs install

=item process_t_files()

The method copies the configured test files into the blib directory if the environment variable PERL_INSTALL_TESTS is set.
The test files are copied to a path like blib/lib/auto/tests/Some-Module-0.01/

=item test_dirs()

The methods returns an array ref of folders (relative to the base dir) that contains test files and or data.
The array ref can be set with the tests keyword in the Module::Build configuration.

=item ACTION_testinc()

Method for running the tests for modules in your current @INC (If they have installed their test files)

Useful for checking that the current module you are installing isnt going to break the functionality of some other module.

=item ACTION_testrdeps()

Method for running tests for all reverse dependencies of the module currently being installed.
At this point in time this is not functional, its only a dummy method.

=back

=head1 TODO

A huge amount of stuff

=head1 LIMITATIONS

This module currently only supports the linux operating system (C<$^O
eq 'linux'>).

=head1 SEE ALSO

L<Module::Build>

=head1 AUTHOR

Joakim Tørmoen.

=cut

