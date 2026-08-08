use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Pinterest::URL::Normalizer',
  VERSION_FROM     => 'lib/Pinterest/URL/Normalizer.pm',
  ABSTRACT_FROM    => 'lib/Pinterest/URL/Normalizer.pm',
  AUTHOR           => 'jiankn',
  LICENSE          => 'mit',
  MIN_PERL_VERSION => '5.014',
  EXE_FILES        => ['bin/pinterest-url-normalizer'],
  PREREQ_PM        => {},
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    resources   => {
      homepage   => 'https://savepinner.com/pinterest-downloader/',
      bugtracker => { web => 'https://github.com/jiankn/pinterest-url-normalizer-perl/issues' },
      repository => {
        type => 'git',
        url  => 'https://github.com/jiankn/pinterest-url-normalizer-perl.git',
        web  => 'https://github.com/jiankn/pinterest-url-normalizer-perl',
      },
    },
  },
);
