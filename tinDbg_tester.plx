#!/usr/prog/perl/5.10.1/bin/perl 


# !/usr/bin/perl

# default Perl Lib
use strict;
use warnings;
#use Carp;


=head1 tinDbg_tester

a perl script that use my debugger and learn OO programing (instance data vs class-wide data)
originally part of bioperl1, but cutting that stuff off.

=cut 

#use lib "~/sn/bioinfo";
use tinDbg;


## testing with tinDbg, learning about class data, closure.
print( "===CLASS call=======================================================\n" );
tinDbg->tinDbgSetting( 1 );
$tinDbg::Ddebugging=0;
$tinDbg::Census=4000;
$tinDbg::_classCount2=100;
print( "Test for accessing pakcage data (the ugly way): $tinDbg::_classCount2 \n" );
## strangely, the above can access data but don't stick!

tinDbg->showSetting();

print( "===dbg1=======================================================\n" );
my $dbg1 = tinDbg->new( objId=>1 );
#$dbg1->$_classCount2 = 111;
$dbg1->setObjIdNum(11);
#$dbg2->setObjIdNum(22);
#$dbg2->$objIdNum = 22;    ## obviously don't work.

$dbg1->tinDbgSetting( 1 );
#$dbg1->showObjSetting() ;
$dbg1->showSetting();
print( "+++++\n" );
$dbg1->showSetting();
print( "+++++\n" );
$dbg1->showSetting();

print( "===dbg2=======================================================\n" );
my $dbg2 = tinDbg->new( objId=>2 );
$dbg2->showObjSetting();
$dbg2->showSetting();
print( "=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`=`\n" );


print "\nThe End.\n" ;

