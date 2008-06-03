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

sub _record_path {
    my ($self, $id) = @_;
    return $self->directory->file("$id.json")->stringify;
}

sub lookup {
    my ($self, $id) = @_;
    return $self->class->name->load($self->_record_path($id));
}

sub search {
    my ($self, $prototype) = @_;
    my @results = $self->index->query_with_prototype($prototype);
    return map { $self->lookup($_) } @results;
}

sub scan {
    my ($self, $code) = @_;

    opendir my $dh, $self->directory
      or die "Failed to open @{[$self->directory]}: $!";

    my @files = grep { -f } map { $self->directory->file($_) } readdir $dh;

    closedir $dh;

    foreach my $file (@files){
        my $obj = $self->class->name->load($file->stringify);
        $code->($obj);
    }

    return;
}

sub grep {
    my ($self, $code) = @_;

    my @results;
    $self->scan(sub {
        my $obj = shift;
        push @results, $obj if $code->($obj);
    });
    return @results;
}

sub all {
    my ($self) = @_;
    my @results;
    $self->scan(sub { push @results, $_[0] });
    return @results;
}

sub store {
    my ($self, $object) = @_;
    confess "The class ($object) is not the correct type"
      unless $object->isa($self->class->name);

    $object->store($self->directory->file($object->get_id. '.json')->stringify);
    $self->index->add_object($object);

    return $object->get_id;
}

sub delete {
    my ($self, $object) = @_;
    $self->index->delete_object($object);
    unlink $self->_record_path($object->get_id);
}

1;

__END__

=head1 NAME

MooseX::Storage::Directory -
