use strict;
use warnings;
use Test::More tests => 6;
use t::lib::Test;

my $tmp = tmp;
my $dir = storage;
ok $dir, 'created directory';

{
    my $foo = Test->new( id => 1, foo => 'Hello' );
    $dir->store($foo);
}

{
    my $foo = $dir->lookup(1);
    ok $foo, 'got something from lookup';
    isa_ok $foo, 'Test', 'loaded class';

    is $foo->id, 1, 'correct id';
    is $foo->foo, 'Hello', 'correct foo';
}

$dir->store( Test->new( id => 2, foo => 'Another file' ) );

my @files = $tmp->ls;

is_deeply [sort grep { !/.index/ } @files], 
          [sort ('1.json', '2.json')], 
  'all files stored ok';
