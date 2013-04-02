use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Furl;
use JSON::PP;
use Pod::Usage;
use Data::Dumper;
use ExtUtils::Installed;

my $module = pop @ARGV || pod2usage();

my $res = Furl->new()->post(
    'http://api.metacpan.org/v0/release/_search',
    ['Content-Type' => 'application/json'],
    sprintf(<<'...', $module));
  {
  "query": {
    "match_all": {}
  },
  "size": 5000,
  "fields": [ "distribution" ],
  "filter": {
    "and": [
      { "term": { "release.dependency.module": "%s" } },
      { "term": {"release.maturity": "released"} },
      { "term": {"release.status": "latest"} }
    ]
  }
}
...
die $res->status_code unless $res->is_success;

print Dumper( decode_json($res->content) );
die();

my $path = File::Spec->catdir( qw/auto tests/);

my $inst = ExtUtils::Installed->new();
my (@modules) = $inst->modules();

my %modules = (
  # My::Module => {
  #  test_files => [
  #    [file1, alias1],
  #    [file2, alias2]
  #  ], #List of test files
  #  #Other things might pop up from nowhere
  #}
);

my @reverse_deps = map{ $_->{fields}->{distribution} } @{decode_json($res->content)->{hits}->{hits}};

foreach my $dep (@reverse_deps){
  die($dep . " does is not installed") unless grep { m/^$dep$/ } @modules;
  
  #Finding test files for the reverse dependency
  
  #Best effort
  my @files = grep { m/$path/} $inst->files($dep);
  next unless scalar(@files) > 0 ;
  my $alias_prefix = $dep;
  my @testfiles = map{
    my $alias = $_;
    my $file = $_;
    $alias =~s/.*$dep//g;
    [$_, File::Spec->catdir($alias_prefix, $alias) ]
  } @files;
  
  $modules{$dep} = { test_files => [ @testfiles ] };
  
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

#print Dumper \@reverse_deps;
#print Dumper \@modules;

#print Dumper %tests;

__END__

=head1 SYNOPSIS

    % cpan-reverse-deps Text::Xslate