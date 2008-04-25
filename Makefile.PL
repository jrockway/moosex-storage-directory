use inc::Module::Install;

name 'MooseX-Storage-Directory';
all_from 'lib/MooseX/Storage/Directory.pm';

requires 'Data::UUID';
requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::AttributeHelpers';
requires 'MooseX::Storage';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types::UUID';
requires 'Storable';
build_requires 'Directory::Scratch';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
