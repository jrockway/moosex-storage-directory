use strict;
use warnings;
use Test::More tests => 3;
use t::lib::Test;

my $dir = storage;

$dir->store(Test->new( id => 1, foo => 'one' ));
$dir->store(Test->new( id => 2, foo => 'two' ));
$dir->store(Test->new( id => 3, foo => 'three' ));

tmp()->touch('.gitignore'); # make sure this is ignored

my @results = map { $_->id } $dir->grep(sub { my $obj = shift; length $obj->foo == 3 });
is_deeply [sort @results], [1, 2], 'got results';

my @foos;
$dir->scan(sub { push @foos, $_[0]->foo });
is_deeply [sort @foos], [sort qw/one two three/];

my @all = $dir->all;
is_deeply [map { $_->foo } sort { $a->id <=> $b->id } @all],
          [qw/one two three/];

