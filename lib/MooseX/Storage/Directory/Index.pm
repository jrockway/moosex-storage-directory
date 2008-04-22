package MooseX::Storage::Directory::Index;
use Moose;
use feature ':5.10';
use MooseX::Storage::Directory::Index::Column;
use MooseX::AttributeHelpers;
use Algorithm::SkipList;

has 'column_indexes' => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[MooseX::Storage::Directory::Index::Column]',
    default   => sub { {} },
    provides  => {
        get => 'get_column_index',
        set => 'set_column_index',
    },
);

around get_column_index => sub {
    my ($next, $self, $key) = @_;
    my $result = $self->$next($key);
    return $result if $result;
    my $new_index = MooseX::Storage::Directory::Index::Column->new;
    $self->set_column_index($key => $new_index);
    return $new_index;
};

sub add_to_index {
    my ($self, $object) = @_;

    my $id = $object->get_id;
    my %data = %{ $object->pack };

    foreach my $key (keys %data) {
        my $column_index = $self->get_column_index($key);
        given($data{$key}){
            when(ref eq 'ARRAY'){
                $column_index->insert($_ => $id) for @$_;
            }
            # this is for "nested searches"
            # i.e. "give me all rows where foo.bar = baz"
            when(ref eq 'HASH' || blessed $_){
                die 'I am not sure how to do this yet';
            }
            default {
                $column_index->insert($_ => $id);
            }
        }
    }
}

1;
