package MooseX::Storage::Directory;
use Moose;
use MooseX::Types::Path::Class qw(Dir);
use Moose::Util::TypeConstraints;
use Moose::Meta::Class;
use MooseX::Storage;
use MooseX::Storage::IO::File;
use MooseX::Storage::Format::JSON;

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
    
    MooseX::Storage::Format::JSON->meta->apply($self->class);
    MooseX::Storage::IO::File->meta->apply($self->class);
}

sub lookup {
    my ($self, $query) = @_;
    return $self->class->name->load($self->directory->file("$query.json")->stringify);
}

sub store {
    my ($self, $class) = @_;
    confess "The class ($class) is not the correct type"
      unless $class->isa($self->class->name);
    $class->store($self->directory->file(join '.', $class->get_id, 'json')->stringify);
}

1;

__END__

=head1 NAME

MooseX::Storage::Directory - 
