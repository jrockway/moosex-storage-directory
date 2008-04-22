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

sub search {
    my ($self, $key, $value) = @_;
    my $index = $self->_read_index;
    my $column_index = $index->get_column_index($key);
    return map { $self->lookup($_) } $column_index->find($value);
}

sub store {
    my ($self, $object) = @_;
    confess "The class ($object) is not the correct type"
      unless $object->isa($self->class->name);
    $object->store($self->directory->file($object->get_id. '.json')->stringify);

    $self->_index($object);

    return $object->get_id;
}

sub _lockfile {
    my ($self) = @_;
    return $self->directory->file('lock');
}

# sub lock {
#     my ($self) = @_;
#     # XXX: this should block or something, but I don't feel like
#     # writing that code right now
#     my $lock = $self->_lockfile;
#     $self->check_lock;
#     open my $fh, '>', $lock or die "Cannot open lockfile $lock for writing: $!";
#     print {$fh} "$$\n";
#     close $fh;
# }

# # add C< before qw/lookup store/ => sub { shift->asset_lock } > if you care
# # i only care about locking for index updates
# sub assert_lock {
#     my ($self) = @_;
#     my $lock = $self->_lockfile;
#     die $self->directory. ' is locked' if -e $lock;
#     return 1;
# }

# sub unlock {
#     my ($self) = @_;
#     my $lock = $self->_lockfile;
#     die $self->directory. ' is not locked' unless -e $lock;
#     open my $fh, '<', $lock or die "Cannot open lockfile $lock for reading: $!";
#     chomp(my $pid = do { local $/; <$fh> });
#     die 'I did not lock '. $self->directory. ', so I cannot unlock it'
#       unless $pid == $$;
#     unlink $lock or die "Could not unlink $lock: $!";
# }

sub _index {
    my ($self, $object) = @_;
    my $index_file = $self->directory->file('.index');
    my $index = eval { lock_retrieve($index_file) } ||
      MooseX::Storage::Directory::Index->new;
    
    $index->add_to_index($object);
    lock_nstore($index, $index_file);
}

sub _read_index {
    my ($self, $object) = @_;

    my $index_file = $self->directory->file('.index');
    my $index = eval { lock_retrieve($index_file) } ||
      MooseX::Storage::Directory::Index->new;
    return $index;
}

1;

__END__

=head1 NAME

MooseX::Storage::Directory - 
