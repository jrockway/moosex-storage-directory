use strict;
use warnings;
use Test::More tests => 4;

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

{ my $foo = Test->new( id => 1, foo => 'Hello' );
  $dir->store($foo);
  ok $tmp->exists('1.json'), 'created 1.json ok';
  ok $tmp->exists('.index'), 'created index ok';
  
  my $foo2 = [$dir->search( { foo => 'Hello' } )]->[0];
  is $foo2->{id}, 1;
}
