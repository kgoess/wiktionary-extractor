use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'kg::WiktionaryExtractor',
    VERSION_FROM      => 'lib/kg/WiktionaryExtractor.pm', # finds $VERSION
    PREREQ_PM         => {
        'HTML::TableExtract' => 2.10,
        'LWP::Simple'        => 6.00,
        'Data::Dump'        => 1.19,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/kg/WiktionaryExtractor.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin Goess <cpan@goess.org>') : ()),
);
