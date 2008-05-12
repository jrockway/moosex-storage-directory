package MooseX::Storage::Directory;
use Moose;
use MooseX::Types::Path::Class qw(Dir);
use Moose::Util::TypeConstraints;
use Moose::Meta::Class;
use MooseX::Storage;
use MooseX::Storage::IO::File;
use MooseX::Storage::Format::JSON;
use MooseX::Storage::Directory::Index;
use Storable qw(lock_nstore lock_retrieve);

our $VERSION   = '0.00_1';
our $AUTHORITY = 'CPAN:JROCKWAY';

subtype 'MXStorageClass'
  => as 'Moose::Meta::Class'
  => where { $_->does_role('MooseX::Storage::Directory::Id') };

has 'directory' => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

has 'class' => (
    is       => 'ro',
    isa      => 'MXStorageClass',
    required => 1,
);

sub BUILD {
    my $self = shift;
    my $meta = $self->class;

    confess $self->directory, 'must exist' unless -d $self->directory;
    
    MooseX::Storage::Format::JSON->meta->apply($meta);
    MooseX::Storage::IO::File->meta->apply($meta);
}

sub lookup {
    my ($self, $query) = @_;
    return $self->class->name->load($self->directory->file("$query.json")->stringify);
}

sub search {
    my ($self, $prototype) = @_;
    my $index = $self->_read_index;

    confess "prototype to search must be a reference, not $prototype"
      if !ref $prototype;
    confess "prototype to search must be a HASH reference, not $prototype"
      if ref $prototype ne 'HASH';
    
    # not yet implemented
    if(scalar keys %$prototype != 1){
        confess 'Searching on more than one column is not yet implemented.';
    }
    
    my ($key, $value) = %$prototype;
    
    my $column_index = $index->get_column_index($key);
    return map { $self->lookup($_) } $column_index->find($value);
}

sub store {
    my ($self, $object) = @_;
    confess "The class ($object) is not the correct type"
      unless $object->isa($self->class->name);
    $object->store($self->directory->file($object->get_id. '.json')->stringify);

    $self->_add_to_index($object);

    return $object->get_id;
}

sub _index_file {
    my $self = shift;
    return $self->directory->file('.index');
}

sub _read_index {
    my $self = shift;
    my $index = eval { lock_retrieve($self->_index_file) } ||
      MooseX::Storage::Directory::Index->new;
    return $index;
}

sub _add_to_index {
    my ($self, $object) = @_;
    my $index = $self->_read_index;
    $index->add_to_index($object);
    lock_nstore($index, $self->_index_file);
}

1;

__END__

=head1 NAME

MooseX::Storage::Directory -
