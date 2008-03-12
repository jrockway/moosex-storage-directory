use inc::Module::Install;

name 'MooseX-Storage-Directory';
all_from 'lib/MooseX/Storage/Directory.pm';

requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Storage';
build_requires 'Directory::Scratch';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
