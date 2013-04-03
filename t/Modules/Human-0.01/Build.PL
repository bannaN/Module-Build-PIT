use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build::PIT;

my $builder = Module::Build::PIT->new(
    module_name         => 'Human',
    license             => 'restrictive',
    dist_author         => q{Joakim Tørmoen <joakim.tormoen@evry.com>},
    dist_version_from   => 'lib/Human.pm',
    dist_abstract       => 'A module representive a primitive human',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Warn' => 0,
        'File::Copy::Recursive' => 0
    },
    requires => {
      'version' => 0,
      'Bear' => '>= 0.01',
    },
    verbose => 1,
    tests => 't',
    #tests => [ 't', 'foo', 'bar'],
    add_to_cleanup     => [ 'Human-*' ],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('t');
$builder->create_build_script();
