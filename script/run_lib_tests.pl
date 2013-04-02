use strict;
use warnings;
use Path::Class;
use Path::Class::Dir;
use Data::Dumper;
use App::Prove;
use ExtUtils::Installed;
use TAP::Formatter::Console;
use TAP::Parser;
use TAP::Harness;
use TAP::Parser::Aggregator;

my %modules = (
  # My::Module => {
  #  test_files => [
  #    [file1, alias1],
  #    [file2, alias2]
  #  ], #List of test files
  #  #Other things might pop up from nowhere
  #}
);

my $inst = ExtUtils::Installed->new();
my (@modules) = $inst->modules();

foreach my $module ( @modules ){  
  my $path = File::Spec->catdir( qw/auto tests/);
  
  #Best effort
  my @files = grep { m/$path/} $inst->files($module);
  next unless scalar(@files) > 0 ;
  $modules{$module} = { test_files => [] };
  my $alias_prefix = $module;
  my @testfiles = map{
    my $alias = $_;
    my $file = $_;
    $alias =~s/.*$module//g;
    [$_, File::Spec->catdir($alias_prefix, $alias) ]
  } @files;
  
  $modules{$module}->{test_files} = [ @testfiles ];
}

my $formatter   = TAP::Formatter::Console->new;
my $harness = TAP::Harness->new( { formatter => $formatter } );

my $aggregator = TAP::Parser::Aggregator->new;

$aggregator->start();
foreach my $module ( keys %modules ){
  $harness->aggregate_tests($aggregator,  @{ $modules{$module}->{test_files} });
}
$aggregator->stop();
$formatter->summary($aggregator);