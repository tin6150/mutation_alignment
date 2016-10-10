#!/bin/perl


## POD, read via perldoc tinDbg
## output formatting is probably predictable, but don't know how yet.

=head1 tinDbg

  Tin's personal debugger class.
  (also contain code for learning diff b/w class vs obj/instance data, read the code).

  v3 ... need to omit print to STDERR, or if web object, print to std out...
         need to mangle the OUTPUT handler for prt() (et al?)
	 later...

=head1 Synopsis 

  $dbg1 = tinDbg->new();
  $dbg1->setLevel(2);		         # higher number = more verbosity
  $dbg1->prt("debug message here\n" );
  $dbg1->trace("fn trace msg here" );

=cut


$| = 1; # ie unbuffered
package tinDbg;
## intentiding this to be object based...
## no real need, but wanted to learn oo perl
## and this allows for diff portioin of code to use different debug level (maybe).
## if called as tinDbg->method, then class-based call would essentially work as package method...

use strict;
use warnings;
use Carp;

##  By default, package data is class-wide data.
##  only items having been bless()ed becomes obj/instance data.
##  Perl package data has file-scope, so even outsider using the class can access them.  
##  only when the package ref go out of scope would these variables become unreachable 
##  which in Perl only happens when the program terminates.
##  Caller program can refer to $tinDbg::census, they can set, but don't seems to stick
##    so values set here is what class/object will get.  It is bad practice anyway
my $_classCount2 = 200;		
my $Census = 3000;	# see perltoot "Accessing Class Data" in inheritable fashion
my $Ddebugging = 0;	# Debbug level of this tinDbg.pm.  Used for learning.  see Debugging in perltoot.


## placing in anonymous subroutine would prevent methods outside this class (package) from mucking w/ it.
## The closure nature of Perl implementation would means means these remain as class-wide data
## that is only accessible via subroutines defined here.
## See Tisdall Mastering Perl for BioInformatics, p94.
## According to perltoot, this is just being OCD.
{
	my $_classCount = 0;
	sub get_count  { $_classCount; };
	sub _inc_count { ++$_classCount; };
	sub _dec_count { --$_classCount; };
}


=head1 setLevel( $binNumber )

	not fully using binNumber yet, as not parsing the bits.
	which technically can have 0101 for enabling level 4 and 1, no trace.
	but do obey "level number"
	0....1 = level 1 debug, some message
	0...1. = level 2 debug, enable trace
       	0..1.. = level 4 debug, enable object id printing (not really useful, it is id of the dbg obj)
        0.1... = level 8 debug, dbg message wrapped inside <!-- --> for hiding in html
        01.... = super debug, output would break HTML and thus not runnable in CGI

=cut

sub setLevel {
	my( $self, $dbgLevel ) = @_;
	$self->{_dbgLevel} = $dbgLevel;
	print( "*DBG* Level is set to :: ",  $self->{_dbgLevel} , "\n" ) if( $Ddebugging );

	# will do printing of trace() calls if dbg level is 2+
	if( $self->{_dbgLevel} >= 16 ) {
		$self->{_superDbg} = 1;
	}
	if( $self->{_dbgLevel} >= 8 ) {
		$self->{_htmlHide} = 1;
	}
	if( $self->{_dbgLevel} >= 2 ) {
		$self->{_trace} = 1;
	} else {
		$self->{_trace} = 0;
	}
		
}


## print with object reference info as prefix 
sub prt {
	my( $self, $msg ) = @_;
	#print( "*DBG* Level is :: ",  $self->{_dbgLevel} , "\n" );
	if( ! $msg ) {
		# somehow dbg prt called with empty message at time
		# just skip, don't print anything 
		;
	} elsif( $self->{_htmlHide} ) {
		chomp( $msg );		## 2010.1225
		print( "  <!--_DBG1_ ", $msg, " -->\n" );
	}
	#if( $self->{_dbgLevel} >= 4 ) {
	elsif( $self->{_dbgLevel} >= 4 ) {
		print( STDERR "      _DBG4_ ", $self, "--", $msg  );
	} elsif( $self->{_dbgLevel} >= 1 ) {
		#print( $self->{_dbgDev}, "*DBG*::", @_  );	# need to convert to fh?
		print( STDERR "     _DBG1_ ", $msg  );
	}
}


## plain print, no object reference info
sub print {
	#prt @_;
	shift;		# get rid of $self ref of object before printing
	print "  ", @_;
}



## trace calls, called to do $dbg->trace("my Fn starts/end")
## and will be printed if _trace is set to 1 (dbgLevel3)
sub trace {
	my( $self, $msg ) = @_;
	shift;		# get rid of $self ref of object before printing
	if( $self->{_trace} ) {
		if( $self->{_htmlHide} ) {
			print( "   <!--_TRC_ @_ -->\n" );
		} else {
			print( STDERR "       _TRC_ @_ \n" );
		}
	}
}

## 

sub new {
        my( $class, %arg ) = @_ ;
        my $self = bless {
		_dbgLevel	=> $arg{dbgLevel}	|| 0,
		_dbgDev		=> $arg{dbgDev}		|| "STDERR",
		_objId		=> $arg{objId}		|| "objIdNotGiven",
		_objCt		=> 0,			## some counter for testing persistence in object and away from class
        }, $class;

	# will do printing of trace() calls if dbg level is 3+
	if( $self->{_dbgLevel} >= 3 ) {
		$self->{_trace} = 1;
	} else {
		$self->{_trace} = 0;
	}
		

	## can I expand the hash with more key and values after bless??   
	## seems to be yes, and also doable in other methods too.  
	## all it takes is for bless() on an object (ie reference) and refer to things from there.
	$self->{_objNick} = "objNickName";
	

	# these are for testing object stuff only
	if( $self->{_dbgLevel} > 0 ) {
		# it is bad to use this in CGI env, 
		# as it tends to print before HTML header and hide err msg
        	print( "~~class is --$class--\n") ;
        	print( "~~self is --$self--\n") ;
	}
	$_classCount2++;
	$class->_inc_count();		# can also do $self->_inc_count(), so perl allow for some confusion :(
	$self->_inc_count();		
	_inc_count();			# each new object has this count done 3 times--just to show syntax :) 


	##??  $self->{$_classCount++};
	$self->{"_CENSUS"} = \$Census;	# use pointer so that it points to class-wide data, inheritable. see perltoot.
	++ ${ $self->{"_CENSUS"} };
	## CENSUS probably isn't fully working... 


	# !! these obj declaration below is likely WRONG !!
	# they are not part of the bless, so when "new" finishes, they are gone
	# not sure how I was able to use them...
	# OKAY, if "use strict", then they will fail!
	# w/o strict, perl may have promoted them to become global!!   or kept as some closure that isn't proper...
	my $_objCount = 0;
	my $_objCall = 0;
	my $objIdNum = 0;

	# return an obj (address) to caller.
        return $self;
}

## Perl autocalled destructor
sub DESTROY {
	my $self = shift;
	##$_classCount++;
	$_classCount2--;
	-- ${ $self->{"_CENSUS"} };
	$self->_dec_count();		
	$self->_dec_count();		# $class not defined here, so do $self twice.
	_dec_count();			# each new object has this count done 3 times in new() 
	if( $Ddebugging ) { 
		carp "Destroying $self " . "(obj # " . $self->{_objId} . ") ... " ;
		print "_CENSUS is now " . ${ $self->{"_CENSUS"} } . "\n"; 
	};
}


##sub showObjSettings {    renamed to w/o s ending.
## !! this should be obsoleted in favor of showSettingI()
sub showObjSetting {
	# depending on whether method is called via CLASS::method or $obj->method
	# the first arg could be the instance or the class.
	my( $self, %arg ) = @_;							# $self need to be initiated before use
	print( "===tinDbg.pm showObjSetting()==\n" );
	print( '$ self->objId is ',  $self->{_objId},   "\n" );			# is ok, $self and $_[0] seems same 	
	print( '$ _[0]->objId is ',  $_[0]->{_objId},   "\n" );
	#print( '$ self->objIdNum is ',  $self->{$objIdNum},   "\n" );		## these should NOT work, var went out of scope when new() ended.
	#print( '$ _[0]->objIdNum is ',  $_[0]->{$objIdNum},   "\n" );
	# the rest are very confusing...  ignore...    don't think there is diff  b/w $self and $_[0]
	#print( '$ self->objCt is ',  $self->{_objCt}++,   "\n" );
	#print( '$ _[0]objCt is ',    $_[0]->{_objCt}++,   "\n" );
	#print( '$ _classCount  is ', $_classCount,  "\n" );
	#print( '$ _classCount2 is ', $_classCount2, "\n" );
	#print( '$ _objCount is ',    $_objCount,   "\n" );
	#print( '$ _objCall  is ',    $_objCall++,   "\n" );
	#print( "*DBG* Level is set to :: ",  $self->{_dbgLevel} , "\n" );
	#print( "===tinDbg.pm end of showObjSettings==\n" );
	return 777;
}

## will check whether called from class or obj (instance) 
## see perltoot debug()  later portion
sub showSetting {
	##my $self = shift;		# if use shift, then item actually poped out of @_ and so $_[0] isn't same as $self
	my( $self, %arg ) = @_;
	if( ref( $self ) ) {

		## obj/instance only data
		$self->{_objNick2} = $self->{_objNick} . $self->{_objCt};	## adding new key/attrib to hash
		carp( "object (instance) call..." ) if $Ddebugging;
		print( "==>>==tinDbg.pm showSetting()==\n" );
		print( "_CENSUS is: "  . ${ $self->{"_CENSUS"} } .   "\n" ); 	## the ref ${ ... } won't work if $self is actually a class.
		print( '$ self->objNick  is ',  $self->{_objNick},   "\n" );	
		print( '$ self->objNick2 is ',  $self->{_objNick2},  "\n" );	

		print( '$ self->get_count() is: ' . $self->get_count() . " (div by 3 for actual number)\n" );	
		print( '$ self->objId is ',  $self->{_objId},   "\n" );	    # is ok, $self and $_[0] is same 	  
		print( '$ _[0]->objId is ',  $_[0]->{_objId},   "\n" );	    # iff value of $self wasn't obtained by "shift" or poping it out of @_
		print( '$ self->objCt is ',  ++$self->{_objCt},   " (this is a pseudo call count to chk persistency only)\n" );	
		print( '$ _[0]->objCt is ',  ++$_[0]->{_objCt},   "\n" );
		print( '$ _classCount2 is ', $_classCount2, "\n" );
		#print( '$ _objCall  is ',    $_objCall++,   "\n" );	  ## this should NOT work, var went out of scope when new() ended.
		print( "*DBG* Level is set to :: ",  $self->{_dbgLevel} , "\n" );
	} else {
		carp( "class call..." ) if $Ddebugging;
		## class-wide only data

		## if class call, no obj refering to $self would work.
	}

	## class-wide and obj/instance data
	##~~ print( "$ _classCount  is  $_classCount  \n" );		## how to access stuff in anon method {}  see master perl bio book again... tbd ++ 
	print( '$ _classCount2 is  ' . $_classCount2 . "\n" );		## this is just package var, so work,   

} # end sub showSetting()

## see perltoot debug()
sub tinDbgSetting {
	my $class = shift;
	if( ref $class ) { 
		#confess "method tinDbgSetting() called as object method." ;
		print "method tinDbgSetting() called as object method.\n" ;
	} else {
		print "method tinDbgSetting() called as class method.\n" ;
	};
	if( @_ > 1 ) {
		confess "Invalid call.  Usage: CLASSNAME->tinDbgSettings(level).\n" ;
		## confess would still cause an exit
	}
	$Ddebugging = shift;
}
	

sub setObjIdNum {
	my( $self, $objIdNumber ) = @_;
	$self->{_objId} = $objIdNumber;
	print( "^^setObjIdNum ... value is--$self->{_objId}--\n" );

	## don't work in strict!   don't want to use them.   need to use hash key that is part of anon hash and been blessed.
	##$self->{$objIdNum} = $objIdNumber;
	#print( "^^setObjIdNum ... value is--$self->{$objIdNum}--\n" );
}

1;


