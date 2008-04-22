package MooseX::Storage::Directory::UUID;
use Moose;
use MooseX::Types::UUID qw(UUID);
use Data::UUID;

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
