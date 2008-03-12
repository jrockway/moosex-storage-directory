use inc::Module::Install;

name 'MooseX-Storage-Directory';
all_from 'lib/MooseX/Storage/Directory.pm';

build_requires 'Test::More';
build_requires 'ok';

WriteAll();
