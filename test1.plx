#!/usr/bin/perl

use warnings;
use strict;

print( "hello world from Cygwin Perl.\n" );

my $var  = 123;
my $varref  = \$var;

print( "$var \n" );
print( "$$varref\n" );
