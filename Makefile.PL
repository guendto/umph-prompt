
use warnings;
use strict;

use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Umph::Prompt',
  VERSION_FROM       => 'lib/Umph/Prompt.pm',           # finds $VERSION
  BUILD_REQUIRES     => {'ExtUtils::MakeMaker' => 0,},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 0,},
  MIN_PERL_VERSION   => 5.010001,
  PREREQ_PM => {},    # e.g., Module::Name => 1.1
  (
   $] >= 5.005
   ?                  ## Add these new keywords supported since 5.005
     (
     ABSTRACT_FROM =>
       'lib/Umph/Prompt.pm',    # retrieve abstract from module
     AUTHOR => 'Toni Gundogdu <legatvs at sign cpan org>'
     )
   : ()
  ),
  LICENSE => 'lgpl',
  dist    => {
    PREOP => '@if test -f .git/HEAD; then \
	git log --stat --name-only --date=short --abbrev-commit >ChangeLog; \
fi',
    POSTOP => '@if test -f .git/HEAD; then \
	git checkout ChangeLog; \
fi',
  },
);
