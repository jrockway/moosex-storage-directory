package MooseX::Storage::Directory::Id;
use Moose::Role;

with 'MooseX::Storage::Basic';

requires 'get_id';

1;
