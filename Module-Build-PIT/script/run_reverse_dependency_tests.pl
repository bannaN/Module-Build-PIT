use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Furl;
use JSON::PP;
use Pod::Usage;
use Data::Dumper;
use Path::Class::Dir;

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

my %tests = (
  # dist_name => path
);

foreach my $hit (@{decode_json($res->content)->{hits}->{hits}}) {
  my $dist_name = $hit->{fields}->{distribution};
  
  #Seach for the directory withing @INC and add them to the test hash
  foreach my $path ( @INC ){
    my $o_path = Path::Class::Dir->new( $path, '..', '..', 't')->cleanup();
    next if( !-e $o_path->stringify() || !-d $o_path->stringify());
    
    
    #Read the dir and find the tests which corresponds to $hit->{fields}->{distribution}
    opendir(my $dh, $o_path->stringify() ) || die "can't opendir " . $o_path->stringify() . ": $!";
    my @test_folders = grep { /^$dist_name/ && -d  "$o_path->stringify()/$_" } readdir($dh);
    closedir $dh;
    
    $tests{$dist_name} = \@test_folders;
  }  
}

print Dumper %tests;

__END__

=head1 SYNOPSIS

    % cpan-reverse-deps Text::Xslate