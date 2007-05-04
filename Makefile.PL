# $Id$
use strict;
use warnings;
use inc::Module::Install;

name 'Data-Currency';
license 'perl';
perl_version '5.008001';
all_from 'lib/Data/Currency.pm';

requires 'Class::Accessor::Grouped' => '0.03';
requires 'Class::Inspector'         => '0';
requires 'Finance::Currency::Convert::WebserviceX' => '0.03';
requires 'Locale::Currency'         => '2.07';
requires 'Locale::Currency::Format' => '1.22';
requires 'Scalar::Util'             => '0';

tests('t/*.t');
clean_files "Data-Currency-* t/var";

system 'pod2text lib/Data/Currency.pm > README';

auto_install;
WriteAll;
