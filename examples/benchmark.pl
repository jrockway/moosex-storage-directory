#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';
use Time::HiRes qw(time);
use Directory::Scratch;
use lib '../lib';
use MooseX::Storage::Directory;

local $| = 1;

use Smart::Comments;

{
    package Test;
    use Moose;
    use MooseX::Storage;
    with 'MooseX::Storage::Directory::Id';
    
    has 'id'      => ( is => 'ro', isa => 'Int', required => 1 );
    has 'numbers' => ( is => 'ro', isa => 'ArrayRef[Int]', required => 1 );

    sub get_id { return shift->id }
}

my $tmp = Directory::Scratch->new;

my $dir = MooseX::Storage::Directory->new(
    directory => qq{$tmp},
    class     => Test->meta,
);

say "# db size, insert time, search for 10000 records time";

my $last = 0;
for my $next (5, 10, 100, 500, 1000, 5000, 10000, 20000, 35000, 50000, 60000, 80000, 100000) {
    my ($a,$b)  = add_data_and_search($last+1,$next);
    $last = $next;
    say "$next $a $b";
}

sub add_data_and_search {
    my ($start, $end) = @_;

    my $s = time;
    for($start..$end){ ### Adding data from $start to $end ...
        $dir->store( Test->new( id => $_, numbers => [$_, $_+1, $_-1] ) );
    }
    my $e = time;
    my $itime = $e-$s;

    my $rtime = do_1000_searches($end);
    return ($itime, $rtime);
};

sub do_1000_searches {
    my $max = shift;
    my $start = time;
    for(1..1000){ ### Searching...
        my $rand = int rand($max - 4) + 2;
        my @records = $dir->search( numbers => $rand );
        #warn join ':', map { $_->get_id } @records;
        die unless @records == 3;
    }
    my $end = time;
    return $end-$start;
}
