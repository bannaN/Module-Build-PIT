use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build::PIT;

my $builder = Module::Build::PIT->new(
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
    verbose => 1,
    tests => 't',
    add_to_cleanup     => ['Bear-*'],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('t');
$builder->create_build_script();

