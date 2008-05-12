use strict;
use warnings;
use Test::More tests => 3;
use Directory::Scratch;
use MooseX::Storage::Directory;

{
    package Test;
    use Moose;
    use MooseX::Storage;
    with 'MooseX::Storage::Directory::Id';
    
    has 'id'  => ( is => 'ro', isa => 'Int', required => 1 );
    has 'foo' => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
    
    sub get_id { return shift->id }
}

my $tmp = Directory::Scratch->new;

my $dir = MooseX::Storage::Directory->new(
    directory => qq{$tmp},
    class     => Test->meta,
);

my $foo = Test->new( id => 1, foo => [qw/foo yay/] );
my $bar = Test->new( id => 2, foo => [qw/bar yay/] );
my $baz = Test->new( id => 3, foo => [qw/foo bar baz !yay/] );

$dir->store($_) for ($foo, $bar, $baz);

my @foos = sort map { $_->get_id } $dir->search( { foo => 'foo' } );
is_deeply \@foos, [1, 3];

my @yays = sort map { $_->get_id } $dir->search( { foo => 'yay' } );
is_deeply \@yays, [1, 2];

my @twos = sort map { $_->get_id } $dir->search( { id => 2 } );
is_deeply \@twos, [2];

