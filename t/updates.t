use strict;
use warnings;
use Test::More tests => 7;

use Directory::Scratch;
use MooseX::Storage::Directory;

{
    package Test;
    use Moose;
    use MooseX::Storage;
    with 'MooseX::Storage::Directory::Id';
    
    has 'id'  => ( is => 'ro', isa => 'Int', required => 1 );
    has 'foo' => ( is => 'ro', isa => 'Str', required => 1 );

    sub get_id { return shift->id }
}

my $tmp = Directory::Scratch->new;

my $dir = MooseX::Storage::Directory->new(
    directory => qq{$tmp},
    class     => Test->meta,
);

ok $dir, 'created directory';


my $foo = Test->new( id => 1, foo => 'Hello' );
$dir->store($foo);

is [$dir->search({ foo => 'Hello' })]->[0]->id, 1; 

$foo = Test->new( id => 1, foo => 'Not hello' );
$dir->store($foo);

ok !eval { [$dir->search({ foo => 'Hello' })]->[0]->id }, 'didnt get old object';
is [$dir->search({ foo => 'Not hello' })]->[0]->id, 1, 'did get new object';

ok $tmp->exists('1.json');
$dir->delete($foo);
ok !$tmp->exists('1.json');

my @id = $dir->index->query_with_prototype({ foo => 'Not hello'});
is scalar @id, 0, 'no matching records';