package MooseX::Storage::Directory::UUID;
use Moose::Role;
use MooseX::Types::UUID qw(UUID);
use Data::UUID;

with 'MooseX::Storage::Directory::Id';

has uuid => (
    is       => 'ro',
    isa      => UUID,
    required => 1,
    default  => sub { Data::UUID->new->create_str },
);

sub get_id {
    return shift->uuid;
}

1;
