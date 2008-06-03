use strict;
use warnings;
use Test::More tests => 7;
use t::lib::Test;

my $tmp = tmp;
my $dir = storage;
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
