package t::lib::Test;
1;

package Test;
use Moose;
with 'MooseX::Storage::Directory::Id';

has 'id'  => ( is => 'ro', isa => 'Int', required => 1 );
has 'foo' => ( is => 'ro', isa => 'Str', required => 0 );
has 'bar' => ( is => 'ro', isa => 'ArrayRef', required => 0 );

sub get_id { return shift->id }

1;
