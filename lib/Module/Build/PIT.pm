package Module::Build::PIT;

use strict;
use warnings;

use base qw(Module::Build);
use Cwd;
use Archive::Tar;

our $VERSION = "0.002";

sub process_t_files {
  my $self = shift;

  return unless $ENV{'PERL_INSTALL_TESTS'};
  
  my $prefix = File::Spec->catdir( $self->blib, qw/lib auto tests/);


  
  #Find all files in this directory
  my @files = @{$self->rscan_dir( File::Spec->catdir( $self->base_dir), sub {
    my $file = $_;
    return unless(-f $file);
    return 1;
  } )};

  
    #Remove the base_dir. +1 because we want to also remove the additional /
  @files = map { substr($_, (length($self->base_dir) + 1)) } @files;

  
  #Take all those files and add them to a tar archive
  my $current_dir = getcwd;
  
  my $tar = Archive::Tar->new;
  
  #Change the working directory
  chdir($self->base_dir);
  #Add files to archive
  $tar->add_files(@files);

  #Write first the tar file to the base_dir and then use Module::Builds functions to move it
  my $tar_filename = $self->dist_name . "-" . $self->dist_version() . ".tar.gz";
  $tar->write(File::Spec->catfile($self->base_dir, $tar_filename), COMPRESS_GZIP, $self->dist_name . "-" . $self->dist_version());
  
  #Move the archive into the install directory
  $self->copy_if_modified( from => $tar_filename, to => File::Spec->catfile($prefix, $tar_filename) );

  #Revert the working directory change
  chdir($current_dir);
  
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
    my @archives = grep { /^$dist_name/ && -f File::Spec->catfile( $dir, $_ ) } readdir($dh);
    closedir $dh;

    my $r;
    
    for(my $i = 0; $i < scalar(@archives); $i++){
      $r = $self->y_n(
        'You have an old archive named ' . $archives[$i]
          . '. Do you want to delete it? (This is a fakeinstall. Action will _NOT_ be executed)',
        'y'
      );
      if ($r) {
        print "Deleting " . File::Spec->catfile( $dir, $archives[$i] );
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
    
    #Looking for old tests
    opendir( my $dh, $dir ) || die "can't opendir " . $dir . ": $!";
    my @archives = grep { /^$dist_name/ && -f File::Spec->catfile( $dir, $_ ) } readdir($dh);
    closedir $dh;
    

    my $r;
    for(my $i = 0; $i < scalar(@archives); $i++){
      $r = $self->y_n(
        'You have an old archive named ' . $archives[$i]
          . '. Do you want to delete it?',
        'y'
      );
      if ($r) {
        print "Deleting " . File::Spec->catfile( $dir, $archives[$i] ) . "\n";
        unlink($archives[$i]);
      }
      
    }
  }

  return $self->SUPER::ACTION_install(@_);
}

sub ACTION_installtests {
  my ($self) = @_;

  local $ENV{PERL_INSTALL_TESTS} = 1;
  return $self->depends_on('install');
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

