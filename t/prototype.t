use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

use Directory::Scratch;
use MooseX::Storage::Directory;

{
    package Test;
    use Moose;
    use MooseX::Storage;
    with 'MooseX::Storage::Directory::Id';
    
    has 'id'    => ( is => 'ro', isa => 'Int',      required => 1 );
    has 'hash'  => ( is => 'ro', isa => 'HashRef',  required => 1 );
    has 'array' => ( is => 'ro', isa => 'ArrayRef', required => 1 );
    sub get_id { return shift->id }
}

my $tmp = Directory::Scratch->new;

my $dir = MooseX::Storage::Directory->new(
    directory => qq{$tmp},
    class     => Test->meta,
);

ok $dir, 'created directory';

my $complex = Test->new(
    id    => 1,
    hash  => { this => { is => { a => { deeply => { nested => 'hash' } } } } },
    array => [ 'here', 'is', 'a', { list => [ 'of', 'random', 'crap' ] } ],
);

lives_ok {
    $dir->store( $complex );
} 'storing complex works';

is [ 
    $dir->search( { hash => { this => { is => { a => { deeply => { nested => 'hash' } } } } } } )
]->[0]->id, 1, 'got result';
