use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build::PIT;

my $builder = Module::Build::PIT->new(
    module_name         => 'Params::Check',
    license             => 'perl',
    dist_author         => q{Jos Boumans <kane[at]cpan.org>},
    dist_version_from   => 'lib/Params/Check.pm',
    dist_abstract       => 'Templated based param validation',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
      'Locale::Maketext::Simple'  => 0,
    },
    verbose => 1,
    tests => 't',
    add_to_cleanup     => [ 'Params-Check-*' ],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('t');
$builder->create_build_script();
