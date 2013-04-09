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
use TAP::Formatter::Console;
use TAP::Harness;
use TAP::Parser::Aggregator;

print Dumper @INC;

my $module = pop @ARGV || pod2usage();

my $res = Furl->new()->post( 'http://api.metacpan.org/v0/release/_search', [ 'Content-Type' => 'application/json' ], sprintf( <<'...', $module ) );
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

my $path = File::Spec->catdir(qw/auto tests/);

my $inst = ExtUtils::Installed->new();
my (@installed_modules) = $inst->modules();

my @test_files = ();

my @reverse_deps = map { $_->{fields}->{distribution} } @{ decode_json( $res->content )->{hits}->{hits} };

foreach my $dist_name (@reverse_deps) {
  my $module;
  ( $module = $dist_name ) =~ s/\-/::/g;
  my $path = File::Spec->catdir(qw/auto tests/);

  unless ( grep { m/^$module$/ } @installed_modules ) {
    print STDERR "$module is not installed on the system. Skipping ... \n";
    next;
  }

  #Best effort
  my @files = grep { m/$path/ } $inst->files($module);
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

my $formatter = TAP::Formatter::Console->new;
my $harness = TAP::Harness->new( { formatter => $formatter, lib => [@INC] } );

my $aggregator = TAP::Parser::Aggregator->new;

$aggregator->start();
foreach my $test (@test_files) {
  $harness->aggregate_tests( $aggregator, $test );
}
$aggregator->stop();
$formatter->summary($aggregator);

__END__

=head1 SYNOPSIS

    % cpan-reverse-deps Text::Xslate
