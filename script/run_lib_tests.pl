use strict;
use warnings;

use ExtUtils::Installed;
use TAP::Formatter::Console;
use TAP::Harness;
use TAP::Parser::Aggregator;
use Data::Dumper;

my @test_files = (
#    [file1, alias1],
#    [file2, alias2]
);

my $inst = ExtUtils::Installed->new();
my (@modules) = $inst->modules();

foreach my $module ( @modules ){  
  my $path = File::Spec->catdir( qw/auto tests/);
  
  #Best effort
  my @files = grep { m/$path/} $inst->files($module);
  next unless scalar(@files) > 0 ;
  my $dist_name;
  ($dist_name = $module) =~ s/::/\-/g;
  push @test_files, map{
    my $alias = $_;
    my $file = $_;
    $alias =~ s/.*($dist_name\-[\d\.]+)/$1/;
    [$_, File::Spec->catdir($alias) ]
  } @files;
}

my $formatter   = TAP::Formatter::Console->new;
my $harness = TAP::Harness->new( { formatter => $formatter } );

my $aggregator = TAP::Parser::Aggregator->new;

$aggregator->start();
foreach my $test ( @test_files ){
  $harness->aggregate_tests($aggregator,  $test);
}
$aggregator->stop();
$formatter->summary($aggregator);