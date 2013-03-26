use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Module::Build::PIT',
    license             => 'restrictive',
    dist_author         => q{Joakim Tørmoen <joakim.tormoen@evry.com>},
    dist_version_from   => 'lib/Module/Build/PIT.pm',
    dist_abstract       => 'An extension to Module::Build for handling Post-Install tests',
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
    },
    verbose => 1,
    tests => 't',
    add_to_cleanup     => [ 'Module-Build-PIT-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
