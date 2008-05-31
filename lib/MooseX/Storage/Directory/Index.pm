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

has 'database' => (
    is      => 'ro',
    isa     => 'BerkeleyDB::Btree',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $db = $self->directory->file('.index');
        return BerkeleyDB::Btree->new(
            -Filename => $db->stringify,
            -Property => DB_DUP,
            -Flags    => DB_CREATE,
        );
    },
);

sub add_object {
    my ($self, $object) = @_;
    my @flat = $self->_flatten($object);
    $self->_add($_ => $object->get_id) foreach @flat;
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

# helpers

sub _add {
    my ($self, $key, $id) = @_;
    $self->database->db_put($key => $id)
      and die "Failed to insert '$key => $id' into database";
    return;
}

sub _query {
    my ($self, $key) = @_;

    my $cursor = $self->database->db_cursor
      or die "Failed to get cursor: $BerkeleyDB::Error";

    # get the first matching object
    my (@result, $result);
    $cursor->c_get($key, $result, DB_SET) and return; # true means failure
    push @result, $result;

    # then collect the rest
    while($cursor->c_get($key, $result, DB_NEXT_DUP) == 0){
        push @result, $result;
    }
    return @result;
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
