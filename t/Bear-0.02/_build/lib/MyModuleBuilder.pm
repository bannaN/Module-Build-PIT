package MyModuleBuilder;
use Module::Build;
@ISA = qw(Module::Build);

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
        $r = $self->y_n('You have a large number of test for old versions of ' . $self->dist_name() . '. Do you want to delete all the old tests?', 'y');
      }
        if($r){
            my @del_dirs = map { $dir . "/" . $_ } @dirs;
            remove_tree( @del_dirs, { verbose => 1 } );
            #print "Deleting " . $dir . "/" . $_ for @dirs;
        }else{
            foreach my $ldir ( @dirs){
                if($self->y_n('Delete ' . $dir . "/" . $ldir . '?', 'y')){
                    remove_tree( $dir . "/" . $ldir , { verbose => 1 } );
                }
            }
        }
        $self->SUPER::ACTION_install(@_);        
    }

1;
