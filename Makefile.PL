# $Id$
use ExtUtils::MakeMaker;
use strict;
use warnings FATAL => 'all';

WriteMakefile(
    NAME                => 'Data::Currency',
    AUTHOR              => 'Christopher H. Laco <claco@chrislaco.com>',
    VERSION_FROM        => 'lib/Data/Currency.pm',
    ABSTRACT_FROM       => 'lib/Data/Currency.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'Class::Accessor::Grouped' => '0.03',
        'Class::Inspector'         => '0',
        'Finance::Currency::Convert::WebserviceX' => '0.03',
        'Locale::Currency'         => '2.07',
        'Locale::Currency::Format' => '1.22',
        'Scalar::Util'             => '0',
    },
    NO_META             => 1,
    dist                => {
        PREOP           => 'pod2text lib/Data/Currency.pm > $(DISTVNAME)/README',
    },    
    clean               => { FILES => 'Data-Currency-* t/var' },
);
