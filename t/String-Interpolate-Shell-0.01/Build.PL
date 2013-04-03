use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build::PIT;

my $builder = Module::Build::PIT->new(
    module_name         => 'String::Interpolate::Shell',
    license             => 'gpl3',
    dist_author         => q{Diab Jerius <djerius[at]cpan.org>},
    dist_version_from   => 'lib/String/Interpolate/Shell.pm',
    dist_abstract       => 'Nothing here',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
      'Locale::Maketext::Simple'  => 0,
      'Text::Balanced' => 0,
      
    },
    verbose => 1,
    tests => 't',
    add_to_cleanup     => [ 'String-Interpolate-Shell-*' ],
    create_makefile_pl => 'traditional',
);

$builder->add_build_element('t');
$builder->create_build_script();
