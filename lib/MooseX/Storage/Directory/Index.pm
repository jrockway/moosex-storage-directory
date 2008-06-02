package MooseX::Storage::Directory::Index;
use Moose;
use MooseX::AttributeHelpers;
use Scalar::Util qw(reftype);
use feature ':5.10';
use Moose::Util::TypeConstraints;
use BerkeleyDB;
use MooseX::Types::Path::Class qw(Dir);

has 'directory' => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

has 'forward_index' => (
    is      => 'ro',
    isa     => 'BerkeleyDB::Btree',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $db = $self->directory->file('.index');
        return BerkeleyDB::Btree->new(
            -Filename => $db->stringify,
            -Subname  => 'forward_index',
            -Property => DB_DUP,
            -Flags    => DB_CREATE,
        );
    },
);

has 'reverse_index' => (
    is      => 'ro',
    isa     => 'BerkeleyDB::Btree',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $db = $self->directory->file('.index');
        return BerkeleyDB::Btree->new(
            -Filename => $db->stringify,
            -Subname  => 'reverse_index',
            -Property => DB_DUP,
            -Flags    => DB_CREATE,
        );
    },
);

sub add_object {
    my ($self, $object) = @_;
    $self->delete_object($object);
    my @flat = $self->_flatten($object);
    $self->_add_forward($_ => $object->get_id) foreach @flat;
    $self->_add_reverse($object->get_id, @flat);
    $self->forward_index->db_sync;
    $self->reverse_index->db_sync;
}

sub query_with_prototype {
    my ($self, $prototype) = @_;
    my @flat = $self->_flatten1('!', $prototype);

    # this can be made more efficient
    my %results;
    foreach my $query (@flat){
        $results{$_}++ for $self->_query($query);
    }

    return grep { $results{$_} == @flat } keys %results;
}

sub delete_object {
    my ($self, $object) = @_;
    my $id = $object->get_id;
    my @keys = _get_all_dups($self->reverse_index, $id);
    foreach my $key (@keys){
        my $cursor = $self->forward_index->db_cursor or die $BerkeleyDB::Error;
        my $current_id;
        $cursor->c_get($key, $current_id, DB_SET) and die $BerkeleyDB::Error;
        $cursor->c_del if $current_id eq $id;
        while($cursor->c_get($key, $current_id, DB_NEXT_DUP) == 0){
            $cursor->c_del if $current_id eq $id;
        }
    }
    $self->reverse_index->db_del($id);
}

# helpers

sub _add_forward {
    my ($self, $key, $id) = @_;
    $self->forward_index->db_put($key => $id)
      and die "Failed to insert '$key => $id' into forward_index";
    return;
}

sub _add_reverse {
    my ($self, $id, @keys) = @_;
    $self->reverse_index->db_put($id, $_) for @keys;
}

sub _get_all_dups {
    my ($db, $key) = @_;

    my $cursor = $db->db_cursor
      or die "Failed to get cursor: $BerkeleyDB::Error";
    
    my (@result, $result);
    $cursor->c_get($key, $result, DB_SET) and return; # true means failure
    push @result, $result;

    # then collect the rest
    while($cursor->c_get($key, $result, DB_NEXT_DUP) == 0){
        push @result, $result;
    }
    return @result;    
}

sub _query {
    my ($self, $key) = @_;
    return _get_all_dups($self->forward_index, $key);
}

sub _flatten {
    my ($self, $object) = @_;
    return $self->_flatten1('!', $object->pack);
}

sub _flatten1 {
    my ($self, $namespace, $ref) = @_;

    return unless $ref;
    given($ref){
        when(!ref){
            return join '=', $namespace, $self->_canonicalize($ref);
        }
        when(reftype $_ eq 'ARRAY'){
            return map { $self->_flatten1("$namespace.[]", $_) } @$ref;
        }
        when(reftype $_ eq 'HASH'){
            return map {
                $self->_flatten1(
                    "$namespace.{". $self->_canonicalize($_). "}",
                    $ref->{$_}
                )
            } keys %$ref;
        }
        default {
            confess 'Cannot flatten objects of type '. reftype $_;
        }
    }
}

sub _canonicalize {
    my ($self, $value) = @_;
    return quotemeta $value;
}

1;
