package Test;
use Moose;
with 'MooseX::Storage::Directory::Id';

has 'id'  => ( is => 'ro', isa => 'Int', required => 1 );
has 'foo' => ( is => 'ro', isa => 'Str', required => 0 );
has 'bar' => ( is => 'ro', isa => 'ArrayRef', required => 0 );

sub get_id { return shift->id }

1;

package t::lib::Test;
use strict;
use Directory::Scratch;
use MooseX::Storage::Directory;
use base 'Exporter';
our @EXPORT = qw/tmp storage/;

my $tmp = Directory::Scratch->new;
my $dir = MooseX::Storage::Directory->new(
    directory => qq{$tmp},
    class     => Test->meta,
); 

sub tmp { $tmp }
sub storage { $dir }

1;

