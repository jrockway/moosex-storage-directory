package MooseX::Storage::Directory::Index::Column;
use Moose;

has 'data' => (
    isa      => 'Algorithm::SkipList',
    is       => 'ro',
    required => 1,
    default  => sub {
        Algorithm::SkipList->new( duplicates => 1 ),
    },
    handles => [qw/insert exists/],
);

sub find {
    my ($self, $key) = @_;
    $self->find_duplicates($key);
}

# sub less_than {
#     my ($self, $key, $equal) = @_;
# }

# sub greater_than {
#     my ($self, $key, $equal) = @_;
# }

# sub equal_to {
#     my ($self, $key) = @_;
# }

1;
