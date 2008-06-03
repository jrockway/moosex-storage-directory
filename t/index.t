use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;
use t::lib::Test;

my $tmp = tmp;
my $dir = storage;
ok $dir, 'created directory';

{ my $foo = Test->new( id => 1, foo => 'Hello' );
  $dir->store($foo);
  ok $tmp->exists('1.json'), 'created 1.json ok';
  ok $tmp->exists('.index'), 'created index ok';
  
  my $foo2 = [$dir->search( { foo => 'Hello' } )]->[0];
  is $foo2->{id}, 1;
}

$tmp->mkdir('foo');
my $dir2 = MooseX::Storage::Directory->new(
    directory => $tmp->exists('foo'),
    class     => Test->meta,
);

ok $dir2, 'created dir2';

my $nothing;
lives_ok {
    $nothing = $dir->search( { nothing => 'to search on' } );
} 'searching when there are no entries lives ok';

ok !$nothing, 'no results, and no death';
