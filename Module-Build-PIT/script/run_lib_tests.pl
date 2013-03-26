use strict;
use warnings;
use Path::Class;
use Path::Class::Dir;
use Data::Dumper;
use App::Prove;
use ExtUtils::Installed;

my %modules = (
  # My::Module => {
  #  test_files => [], #List of test files
  #  #Other things might pop up from nowhere
  #}
);

my $inst = ExtUtils::Installed->new();
my (@modules) = $inst->modules();

foreach my $module ( @modules ){
  $modules{$module} = { test_files => [] };
  
  my $path = File::Spec->catdir( qw/auto tests/);
  
  #Best effort
  my @testfiles = grep { m/$path/} $inst->files($module);
  
  $modules{$module}->{test_files} = [ @testfiles ];
}



print Dumper %modules;
die();

foreach my $module ( keys %INC){
  #searchreplace Getopt/Long.pm => Getopt-Long
  foreach my $path ( @INC ){
    my $full_path = Path::Class::Dir->new( $path, qw/auto tests/)->stringify;
    next unless ( -e $full_path && -d $full_path );
    
    #har full-path ^Getopt-Long
    
    push(@ARGV, $full_path);
  }  
}


print Dumper %INC;

my $app = App::Prove->new;
$app->recurse(1);
$app->process_args(@ARGV);

exit( $app->run ? 0 : 1 );