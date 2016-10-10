#!/usr/bin/perl

# default Perl Lib
use strict;
use warnings;
use Carp;

# libs in CPAN installed in laptop (and /usr/prog/perl/5.10...)
use Bio::Perl;
use Data::Dump;
use Chemistry::Mol;
use DBI;


use lib "~/sn/bioinfo";
use Gene;

my $obj1 = Gene->new( 
	name		=> "Aging",
	organism	=> "Homo sapiens"
);
print $obj1->name . "\n";
##print $obj1->organism . "\n";



# Mastering Perl BioInfo p90:

my $obj2 = bless { key1 => 'value1' }, 'MyObjectIsLikeAHash' ;
##     ie, blessh any hash ref (in this case a ref to an anonymous hash 
##         then second param is the object name to mark the object, and viola!

my $obj3 = bless { 'key1',  'MyValue1' }, 'MyObjectIsLikeAHash' ;
##    The => notation is an alt form to  'string', ... of a hash.

print $obj3->{'key1'} . "\n";
## shouldn't really do above I suppose
## (actually it is stated as so in page 92)
## but an object is a glorified hash (as constructed above)

## object can be constructed by blessing any other data structure really.


