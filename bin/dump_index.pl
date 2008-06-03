#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use BerkeleyDB;
use MooseX::Storage::Directory::Index;

my $index = MooseX::Storage::Directory::Index->new( directory => shift @ARGV );

for my $what (qw/forward_index reverse_index/){
    my $cursor = $index->$what->db_cursor or die $BerkeleyDB::Error;
    my ($key, $value) = ('','');
    while($cursor->c_get($key, $value, DB_NEXT) == 0){
        say "$what: $key => $value";
    }
}
