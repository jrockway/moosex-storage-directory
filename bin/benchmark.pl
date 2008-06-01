#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Directory::Scratch;
use MooseX::Storage::Directory;
use Time::HiRes qw(time);
use List::Util qw(shuffle);

use Smart::Comments;

my $dir = Directory::Scratch->new;

{ package Class;
  use Moose;
  with 'MooseX::Storage::Directory::Id';
  has 'id'  => (is => 'ro', required => 1, isa => 'Int');
  has 'num' => (is => 'ro', required => 1, isa => 'Int');
  sub get_id { shift->id };
}

my $storage = MooseX::Storage::Directory->new(
    class     => Class->meta,
    directory => "$dir",
);

Class->meta->make_immutable;

my $RAND_MAX = 100_000;

my @random_numbers = shuffle(1..$RAND_MAX);
my @intervals = ( 10, map { int ($_ * 1000) }(.1, .5, 1..100) );
my $last = 0;
my $next = 10;
my $i = 0;
my ($hit, $miss) = (0,0);

$|++;
push @intervals, 0;
open my $datafile, '>', 'out' or die "datafile open: $!";
while(1){
    my $how_many = $next-$last; $last = $next; $next = shift @intervals;

    # create objects
    for(1..$how_many){ ### Creating $how_many objects [%]
        my $obj = Class->new( id => $i++, num => shift @random_numbers );
        $storage->store($obj);
    }

    # search
    print {$datafile} "$last, ";
    my $start = time;
    for(1..3000){ ### Running 3000 searches on $last objects [%]
        my $num = int rand $RAND_MAX;
        my ($obj, @others) = $storage->search({ num => $num });
        #die 'uh oh' unless $obj && $obj->num == $num;
    }
    my $end = time;
    say {$datafile} $end-$start;
    last unless @intervals;
}
close $datafile;

say {*STDERR} "$hit hits, $miss misses";
