package CustomBuild;

use strict;
use warnings;

use base qw(Module::Build);

sub test_dirs{
  my $self = shift;
  return (ref($self->{properties}->{tests}) eq 'ARRAY') ? $self->{properties}->{tests} : [ $self->{properties}->{tests} ];
}

sub process_t_files {
    my $self = shift;
    
    return unless $ENV{'PERL_INSTALL_TESTS'};
    
    use Data::Dumper;
    
    my $test_dirs = $self->test_dirs;
    return unless $test_dirs;

    my $prefix = File::Spec->catdir($self->blib, qw/lib auto tests/, $self->dist_name() . "-" . $self->dist_version());
    
    #Search the directories
    my %files;
    for my $dir ( @$test_dirs ) {
      for my $f ( @{ $self->rscan_dir( $dir, sub {-f} )} ) {
        $f =~ s{\A.*?\Q$dir\E/}{};
        $files{"$dir/$f"} = File::Spec->catdir( $prefix, $dir, $f);
      }
    }
    
    while (my ($file, $dest) = each %files) {
      $self->copy_if_modified(
        from => $file, to => $dest
      );
    }        
    
}
sub ACTION_fakeinstall {
  my $self = shift;
  
  use Data::Dumper;
  
  if( $ENV{'PERL_INSTALL_TESTS'} ){
    my $dir = File::Spec->catdir($self->install_base, qw/lib perl5 auto tests/);

    if( ! -e $dir ){
      die( "Cannot create $dir " )if !mkdir( $dir );
    }        
    
    my $dist_name = $self->dist_name();
    
    #Looking for old tests
    opendir(my $dh, $dir) || die "can't opendir " . $dir . ": $!";
      my @dirs = grep { /^$dist_name/ && -d File::Spec->catdir($dir, $_) } readdir($dh);
    closedir $dh;
    
    my $r;
    
    if(scalar( @dirs > 3)){
      $r = $self->y_n('You have a large number of test for old versions of ' . $self->dist_name() . '. Do you want to delete all the old tests? (This is a fakeinstall. Action will _NOT_ be executed)', 'y');
    }
    
    if($r){
        print "Deleting " . File::Spec->catdir($dir , $_) for @dirs;
    }else{
        foreach my $ldir ( @dirs){
            if($self->y_n('Delete ' . File::Spec->catdir($dir , $ldir) . '? (This is a fakeinstall. Action will not be executed)', 'y')){
                print "Deleting " . File::Spec->catdir($dir , $ldir) . "\n";
            }
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
  
  if($ENV{PERL_INSTALL_TESTS}){
    my $dir = File::Spec->catdir($self->install_base, qw/lib perl5 auto tests/);
    if( ! -e $dir ){
      die( "Cannot create $dir " )if !mkdir( $dir );
    }
    my $dist_name = $self->dist_name;
    opendir(my $dh, $dir) || die "can't opendir " . $dir . ": $!";
      my @dirs = grep { /^$dist_name/ && -d File::Spec->catdir($dir, $_) } readdir($dh);
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
  }
  
  $self->SUPER::ACTION_install(@_);        
}
1;