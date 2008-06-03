use strict;
use warnings;
use Test::More tests => 1;
use t::lib::Test;

my $dir = storage;

$dir->store(Test->new( id => 1, foo => 'one' ));
$dir->store(Test->new( id => 2, foo => 'two' ));
$dir->store(Test->new( id => 3, foo => 'three' ));

my @results = map { $_->id } $dir->scan(sub { my $obj = shift; length $obj->foo == 3 });
is_deeply [sort @results], [1, 2], 'got results';

