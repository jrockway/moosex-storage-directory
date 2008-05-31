package MooseX::Storage::Directory;
use Moose;
use MooseX::Types::Path::Class qw(Dir);
use Moose::Util::TypeConstraints;
use Moose::Meta::Class;
use MooseX::Storage;
use MooseX::Storage::IO::File;
use MooseX::Storage::Format::JSON;
use MooseX::Storage::Directory::Index;

our $VERSION   = '0.00_2';
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

has 'index' => (
    is      => 'ro',
    isa     => 'MooseX::Storage::Directory::Index',
    lazy    => 1,
    default => sub {
        MooseX::Storage::Directory::Index->new( directory => shift->directory );
    },
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
    my @results = $self->index->query_with_prototype($prototype);
    return map { $self->lookup($_) } @results;
}

sub store {
    my ($self, $object) = @_;
    confess "The class ($object) is not the correct type"
      unless $object->isa($self->class->name);
    
    $object->store($self->directory->file($object->get_id. '.json')->stringify);
    $self->index->add_object($object);

    return $object->get_id;
}

1;

__END__

=head1 NAME

MooseX::Storage::Directory -
