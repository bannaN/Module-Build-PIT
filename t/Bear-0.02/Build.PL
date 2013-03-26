use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $class = Module::Build->subclass(
    code => q{
    sub process_t_files {
      my $self = shift;
      use File::Copy::Recursive qw(dircopy);
      $File::Copy::Recursive::CPRFComp = 1;
      if( ! -e $self->base_dir() . '/blib/t' && !mkdir($self->base_dir() . '/blib/t')){
        die("Cannot create blib/t directory");
      }
      unless(dircopy($self->base_dir() . '/t', $self->base_dir() . '/blib')){
        die("Cannot move t files to blib");
      }
    }
    sub ACTION_fakeinstall {
      my $self = shift;

      use Data::Dumper;

      my $dir = $self->install_base . '/t';
      my $dist_name = $self->dist_name;
      opendir(my $dh, $dir) || die "can't opendir " . $dir . ": $!";
        my @dirs = grep { /^$dist_name/ && -d "$dir/$_" } readdir($dh);
      closedir $dh;

      my $r;

      if(scalar( @dirs > 3)){
        $r = $self->y_n('You have a large number of test for old versions of ' . $self->dist_name() . '. Do you want to delete all the old tests? (This is a fakeinstall. Action will _NOT_ be executed)', 'y');
      }

        if($r){
            print "Deleting " . $dir . "/" . $_ for @dirs;
        }else{
            foreach my $ldir ( @dirs){
                if($self->y_n('Delete ' . $dir . "/" . $ldir . '? (This is a fakeinstall. Action will not be executed)', 'y')){
                    print "Deleting " . $dir . "/" . $ldir . "\n";
                }
            }
        }

      #Retval is the return structure from ExtUtils::Install::install
      $self->SUPER::ACTION_fakeinstall(@_);
    }

    sub ACTION_install{
        my $self = shift;

      $self->depends_on('build');

      use File::Path qw( remove_tree );
      use Data::Dumper;

      my $dir = $self->install_base . '/t';

      if( ! -e $dir ){
        die( "Cannot create $dir " )if !mkdir( $dir );
      }

      my $dist_name = $self->dist_name;
      opendir(my $dh, $dir) || die "can't opendir " . $dir . ": $!";
        my @dirs = grep { /^$dist_name/ && -d "$dir/$_" } readdir($dh);
      closedir $dh;

      my $r;

      if(scalar( @dirs > 1)){
        $r = $self->y_n('You have tests for a large number(' . scalar(@dirs) . ') of versions of ' . $self->dist_name() . ' installed. Do you want to delete all the old tests?', 'y');
      }
        if($r){
            my @del_dirs = map { $dir . "/" . $_ } @dirs;
            remove_tree( @del_dirs, { verbose => 1 } );
        }else{
            foreach my $ldir ( @dirs){
                if($self->y_n('Delete ' . $dir . "/" . $ldir . '?', 'y')){
                    remove_tree( $dir . "/" . $ldir , { verbose => 1 } );
                }
            }
        }
        $self->SUPER::ACTION_install(@_);
    }
}
);

my $builder = $class->new(
    module_name        => 'Bear',
    license            => 'restrictive',
    dist_author        => q{Joakim Tørmoen <joakim.tormoen@evry.com>},
    dist_version_from  => 'lib/Bear.pm',
    dist_abstract      => 'A module representive a powerful bear',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'            => 0,
        'File::Copy::Recursive' => 0,
        'File::Path'            => 0
    },
    requires => {
        version => 0
    },
    add_to_cleanup     => ['Bear-*'],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('t');
$builder->install_base_relpaths( t => 't/Bear-' . $builder->dist_version() );
$builder->create_build_script();
