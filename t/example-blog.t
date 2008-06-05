use strict;
use warnings;
use Test::More tests => 3;
use Directory::Scratch;
use MooseX::Storage::Directory;

{ package Blog::Post;
  use Moose;
  with 'MooseX::Storage::Directory::UUID';

  has 'title'   => ( is => 'ro', isa => 'Str', required => 1 );
  # TODO: has 'date' => ( is => 'ro', isa => 'DateTime', required => 1 );
  has 'content' => ( is => 'ro', isa => 'Str', required => 1 );
  has 'author'  => ( is => 'ro', isa => 'Str', required => 1 );
  has 'tags'    => ( is => 'ro', isa => 'ArrayRef', required => 1 );
}

my $tmp = Directory::Scratch->new;

my $dir = MooseX::Storage::Directory->new(
    directory => qq{$tmp},
    class     => Blog::Post->meta,
);

my $perl_is_awesome = Blog::Post->new( 
    title   => 'OMG PERL IS AWESOME',
    author  => 'Andy Lester',
    content => "Today I wanted to compute the sum of two variables, ".
               "so I used Perl's awesome + operator.  Wow!",
    tags    => [qw/perl awesome blogspam/],
);

my $catalyst_sucks = Blog::Post->new(
    title   => 'jrockway is an idiot',
    author  => 'Anonymous Coward',
    content => "Today I was reading Jonathan Rockway's Catalyst book.  ".
               "It sucks because I typed in the example code wrong, and also ".
               "didn't bother to read the text.  I hate that guy, what a loser!",
    tags    => [qw/jrockway sucks perl catalyst blogspam/],
);

my $catalyst_is_awesome = Blog::Post->new(
    title   => 'Some random tutorial of dubious value',
    author  => 'Jonathan Rockway',
    content => "Today I did something really simple and felt like ". 
               "blogging about it!  Listen to me, I'm soooo awesome!!11!!",
    tags    => [qw/jrockway catalyst perl/],
);

my $lisp_is_awesome = Blog::Post->new(
    title   => "LISP is God's Gift To The World",
    author  => 'Jonathan Rockway',
    content => "'(is :clearly (solution-to (every problem)) lisp)",
    tags    => [qw/jrockway lisp/],
);

$dir->store($_) for ($catalyst_sucks, $perl_is_awesome, $catalyst_is_awesome,
                     $lisp_is_awesome);
# with that out of the way, we can do some searching

sub my_sort {
    return sort { $a->get_id cmp $b->get_id } @_;
}

# one in an array
my @perl = $dir->search( { tags => ['perl'] } );

is_deeply [my_sort @perl],
          [my_sort($perl_is_awesome, $catalyst_is_awesome, $catalyst_sucks)],
  'got the perl articles';

# two in an array
my @jrockway_perl = $dir->search( { tags => [qw/jrockway perl/] });
is_deeply [my_sort @jrockway_perl],
          [my_sort($catalyst_sucks, $catalyst_is_awesome)],
  'got articles about me and perl';
  
# one scalar
my @jrockway = $dir->search( { author => 'Jonathan Rockway' } );

is_deeply [my_sort @jrockway], 
          [my_sort($lisp_is_awesome, $catalyst_is_awesome)],
  'got articles by jrockway';
