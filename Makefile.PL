use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Riji',
    VERSION_FROM  => 'lib/Riji.pm',
    PREREQ_PM     => {
        'Kossy' =>  '0.13',
    },
    MIN_PERL_VERSION => '5.008001'
);

