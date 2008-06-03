use strict;
use warnings;
use Test::More tests => 3;
use t::lib::Test;

my $dir = storage;

my $foo = Test->new( id => 1, bar => [qw/foo yay/] );
my $bar = Test->new( id => 2, bar => [qw/bar yay/] );
my $baz = Test->new( id => 3, bar => [qw/foo bar baz !yay/] );

$dir->store($_) for ($foo, $bar, $baz);

my @foos = sort map { $_->get_id } $dir->search( { bar => ['foo'] } );
is_deeply \@foos, [1, 3];

my @yays = sort map { $_->get_id } $dir->search( { bar => ['yay'] } );
is_deeply \@yays, [1, 2];

my @twos = sort map { $_->get_id } $dir->search( { id => 2 } );
is_deeply \@twos, [2];

