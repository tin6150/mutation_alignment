
## #!/usr/bin/perl

use lib "/home/hoti1/sci/bioinfo/"; 	## needed cuz cgi will run in a diff dir, cascaded pm won't refer to cgi dir as cwd

## POD =commands must be wrapped by blank lines.

=head1 orthlogList

	Create an object with data structure to hold the 
	a list of genes that are orthlogs to gene in question
	as well as store the gene sequences of each of this ortholog


=head3 Author

	Tin 2010.1219

=cut

=over

=item 2010.1224

	Got some good trimming done, now file is largely orthologList relevant sub

	Next actions for FIXME ++:
	come up with specific SQL to get ortholog list:
	see response email from Karen, second from last in notes
	need some sort of self join and get ortholog from non human

	need to store proacc too, that should be name to retrieve seq

	to get ball rolling, may just query NCBI...
	then worry about optimize to query local db if seq avail int
	some 60 seq are definatelly internal

	but db source should not need to be spelled out by user?

=item 2010.12..


=back

=cut

package orthologList;
##$| = 1;  # make unbuffered


## a good chunk of this is common oracle db query stuff
## may want to create a base class and inherit from it
## do later...

#push( @INC, "/usr/lib64/perl5/vendor_perl/5.8.8/x86_64-linux-thread-multi/" );
#push( @INC, "/usr/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi" );
#push( @INC, "/usr/lib64/perl5/vendor_perl/5.8.8/x86_64-linux-thread-multi/auto" );
## crap, need DBI and DBD in usr/prog/perl  !!
use DBI;

## http://www.orafaq.com/wiki/Perl
## setting this oracle settings here make prog work in web cgi env.
##my $ORACLE_HOME = "/app/oracle/product/11.2.0/db_1";
my $ORACLE_HOME = "/usr/prog/oracle-client/11.1.0.6";
my $TNS_ADMIN = "/usem/apps/conf/TNS_ADMIN";
#my $ORACLE_SID="orcl";

$ENV{ORACLE_HOME}=$ORACLE_HOME;
$ENV{PATH}="$ORACLE_HOME/bin";
$ENV{TNS_ADMIN}="$TNS_ADMIN";
#$ENV{ORACLE_SID}=$ORACLE_SID;
# $ENV{LD_LIBRARY_PATH}="$ORACLE_HOME/lib";


use strict;
use warnings;
use Carp;
#use CGI qw/:standard/;		# may not need cgi here
use tinDbg;
my $dbg = tinDbg->new();	# this end up being class-wide global, but it is okay.  easier calling.

###--my $scriptDir = "/home/hoti1/sci/bioinfo/";
###--my $dbQuery_mutList_script = $scriptDir . "dbQuery_mutList.plx";

sub objTestStuff {
	my( $self, $objTestVarParam ) = @_;
	#~$self->{$objTestVar} = $objTestVarParam;
	## why the hell this work in tinDbg but not here??!!?

}

=head1 Data structure for this class (as defined in new() )

	- a list of gene comprising the ortholog list
	- gene seq for each of the ortholog
	- implement as 2 arrays with matching index?
	  likely easiest, though not exactly as cool as list of tuples/hash

	- maybe getGeneSeq can be a fn in this class, self retrieve seq
	  but what to do with cosmic etc source info?

=cut

## FIXME adjust to orthologList needed.
sub new {
	my( $class, %arg ) = @_ ;
	$dbg->trace( "mutationList.pm->new begins" );
	my $self = bless {
        _geneName       => $arg{geneName}       || "Error, primary geneName not set yet",
        _geneAccNum     => "tba!!",		## primary gene's ncbi accession number, will be populated by this class.  
        ##_geneId         => "tba!!",	## primary gene's id, will be populated by this class.  
        ##_geneSeq        => "tba!!",	## primary gene's seq, will be populated by this class.  
		## seq stored in $self->{_geneSeqList}->[0]
        _organism       => $arg{organism}       || "human",
        _dbgLevel       => $arg{dbgLevel}       || 0,
		_outDev			=> $arg{outDev}			|| "???",
		_orthologCount  => 0,
		_tmpDir			=> $arg{tmpDir}			|| "/tmp",
	}, $class;
	$dbg->setLevel( $self->{_dbgLevel} );

	#_geneList		=> [],
	#_geneSeq		=> [],
	# above structure don't need to be declared here 
	# populateOrthologList will define them  (see there for exact details)
	# produceFasta will use such extension, no problem.	


	# need a couple of array , maybe something like this...
	# $self->{_orthologLst}->[0]="orthologName1";
	# $self->{_orthologSeq}->[0]="TBA1";              # index parallel ortholog gene name in the array

	# an array of hash that is specific to this object (not class wide)
	# stores a list of mutations, each indexed by the array, 
	# with startPos, stopPos, etc accessible as hash key in individual array record
	###---my( @mutationArray ) = ();
	###--- remember the each( %hash ) fn, though not likely useful here.
	###--- tmp dbg only
	###---$mutationArray[0]{'startPos'} = 100;
	###---$dbg->prt( "\$ mutArr[0]{'startPos'} has value of:--$mutationArray[0]{'startPos'}--\n" );
	###---$mutationArray[3]{'startPos'} = 103;
	###---$dbg->prt( "\$ mutArr[3]{'startPos'} has value of:--$mutationArray[3]{'startPos'}--\n" );

	$dbg->trace( "mutationList.pm->new() ends" );
        return $self;
} # end sub new

=head1 setup()

	IN:   basic gene name, maybe DB source (eg cosmic), 
	      stuff not passwd to new()
	OUT:  store parameters in obj's internal data structure
	      0 = success, 1 = failure

=cut

sub setup {
	my( $self, %arg ) = @_;
	$dbg->trace("orthologList->setup() begins" );
	#--print( " *** setup:: got geneName of $arg{geneName} ***\n" );
	$self->{_geneName} = $arg{geneName} if $arg{geneName};


	## FIXME ++ need at least genename to be set


	return 0;
} # end sub setup


sub showObjSettings {
	#print h2('==mutationList settings==(cgi)\n' );
	print( "==orthologList settings==\n" );
        #print( "_outDev is ",           $_[0]->{_outDev} ,      "\n" );
        print( "_geneName is ",         $_[0]->{_geneName},     "\n" );
        print( "_dbgLevel is ",         $_[0]->{_dbgLevel},     "\n" );
}

=head1 sub generateMutationList

	NEED REWRITE!!  may delete?  skip to ortholog fn toward the end??
	no longer needed?

=cut


=head1 populateOrthologList()

	IN:  DBI result_array ref obj returned by dbQuery
		 (a pointer to a 2D array)
	     containing list of gene names (et al) representing the ortholog list
	eg: A.geneid, B.taxoid, B.geneid, B.genesymbol,   B.proAcc,      B.progi
	    673       9598      463781    BRAF            XP_001155024.1 114616352
	    673       7165      1278538   AgaP_AGAP004699 XP_318144.4    158298052

	OUT: list of genes orthologs, stored in obj's internal data structure
		 A counter for number of ortholog genes found/populated,
		 this exclude info for the primary gene, which is stored at index 0

	Description:
	parse db output and populate the object's array of hash that has mutation list 
	individually retrievable.

	Also make a couple of additional fn calls the result in further DB query:
	- retrieveGeneSeq( ... );		# get actual gene seq (maybe ncbi!)
	- retrieveOrganism( $taxoid ); 	# convert taxoid to organism name, human friendly :)

    FIXME
	++ add check, eg empty result list
    ++ when preparing clustalw, may want to list B.GENEID (same gene, diff organism)
  
=cut 

sub populateOrthologList {
	###--my( $self, $filename ) = @_;
	my( $self, $result_array_ref ) = @_;
	$dbg->trace(" populateOrthologList begins" );

	#-my( $geneName ) = $self->{_geneName};   # ie, it is in the obj, naming for easy manip
	#-my( $seq );


	## eg for result_array_ref, a row_ref should be like:	 
	## 3197 7955 403065 braf 46849736 NP_991307.2
	## ^0   ^1   ^2     ^3   ^4       ^5
	## 673       9598      463781    BRAF            XP_001155024.1 114616352
	## A.geneid, B.taxoid, B.geneid, B.genesymbol,   B.proAcc,      B.progi
	my( $geneid_X, $taxoid, $geneid, $geneSymbol, $accNum, $progi );
	my( $ortholog_idx ) = (1);   	# idx=0 reserved for primary gene of this obj
	my  $dbg_text = "";
	
	$dbg->trace( "converting array into obj's hash...");
	foreach my $row_ref (@$result_array_ref) {
		##--$dbg->prt( ".populateMutationList count is $count \n" );

		#$self->{_sub_list}->[[]] = 0;

		#--( $x0, $x1, $x2, $geneName, $x4, $accNum ) = @$row_ref;
		( $geneid_X, $taxoid, $geneid, $geneSymbol, $accNum, $progi ) = @$row_ref;
		# geneid_X is A.geneid, always same as obj's primary gene name, so X it out

		# can probably say perl is strange... obj's data structure can be extended here
		# as long as it is a ref (obj pointed to some memory), the hash can be extended
		# and it will be updated correctly for the obj, other obj's fn can access it 
		# eg sub produceFasta()
		#$self->{_geneList}->[$gene_ct] = $$row_ref[3];
		$self->{_geneSymbolList}->[$ortholog_idx] = $geneSymbol;
		$self->{_geneIdList}->[$ortholog_idx] = $geneid;
		$self->{_accNumList}->[$ortholog_idx] = $accNum;
		$self->{_progiList}->[$ortholog_idx]  = $progi;
		$self->{_taxoidList}->[$ortholog_idx] = $taxoid;
		#$self->{_geneSeqList}->[$ortholog_idx] = "";   	# store actual gene seq 
		$self->{_geneSeqList}->[$ortholog_idx] = $self->retrieveGeneSeq( $geneid, $accNum );
		$self->{_orgNameList}->[$ortholog_idx] = $self->retrieveOrganism( $taxoid ); 
		
		$dbg_text = $self->{_geneSymbolList}->[$ortholog_idx] . " " .
		$self->{_geneIdList}->[$ortholog_idx] . " " .
		$self->{_accNumList}->[$ortholog_idx] . " " .
		$self->{_progiList}->[$ortholog_idx]  . " " .
		$self->{_taxoidList}->[$ortholog_idx] . " " .
		$self->{_geneSeqList}->[$ortholog_idx];
		$dbg->prt( "ortholog array has this info stored :: $dbg_text (entry  $ortholog_idx)::\n" );
		#$dbg->prt( "build array with info :: $$row_ref[3] ::  (line $count)\n" );

		++$ortholog_idx;
	}
	$self->{_orthologCount} = $ortholog_idx - 1;	# strip off rounding error, may get -1 if no ortholog returned by db	## bug alert ?? ++
	$dbg->trace("populateOrthologList() ends" );
} # end sub 


################################################################################
################################################################################
## mostly for debug/coding aid purpose.
## FIXME  2010.1219   can this stay the same as from mutationList ?? ++
## this is probably not needed anymore...  produceFasta will do print for dbg anyway.
sub print_dbQuery_resultArray {
	my( $self, $result_array_ref ) = @_;
	$dbg->trace("print_dbQuery_resultArray begins" );
	my( $c ) = 0;	# formerly $count, but isn't really a count but index...
	print( "print_dbQuery_resultArray has contents as:\n" );
	#my( $geneName, $variantType, $aaVarStart, $aaVarStop, $sumMutFlag );
	foreach my $row_ref (@$result_array_ref) {
		printf( "._%2d:", $c );
		foreach my $i ( 0, 1, 2, 3, 4, 5 ) {
			## $row_ref is an array with possibly undefined elements in middle!
			##print "@$row_ref[$i]_" if defined @$row_ref[$i];
			if( defined $$row_ref[$i] ){
				print "$$row_ref[$i] ";
				#$self->{_sub_list}->[$count][$i] = $$row_ref[$i];	# works
			} else { 
				print "_ ";
				#$self->{_sub_list}->[$count][$i] = "_";
			}
		}
		print( "\n" );
		++$c;
	}
	print( "End of result from dbQuery (result_array_ref)\n" );

	$dbg->prt( "obj total mutationCount is $self->{_mutationCount} \n" );  # yes, persistent even when set by other method.

	## tmp dbg only, to see how to use the build up arrays:
	# obj's hash pointing to anon array (of anon array).  see perl bioinfo p48
	#$self->{_sub_list} = [ [0,1,2,3,4,5], [00,10,20,30,40,50] ];  #@row[$i] emulation
#	$dbg->prt( "del_list has eg: $self->{_del_list}->[0][2], $self->{_del_list}->[0][3].\n" );
#	$dbg->prt( "ins_list has eg: $self->{_ins_list}->[1][2], $self->{_ins_list}->[1][3].\n" );
#	$dbg->prt( "wil_list has eg: $self->{_wil_list}->[0][4], $self->{_wil_list}->[0][5].\n" );
#	$dbg->prt( "sub_list has eg: $self->{_sub_list}->[0][2], $self->{_sub_list}->[0][3].\n" );
#	$dbg->prt( "sub_list has eg: $self->{_sub_list}->[1][4], $self->{_sub_list}->[1][5].\n" );

	$dbg->trace(" print_dbQuery_resultArray ends" );
} #end sub print_dbQuery_resultArray 



################################################################################
################################################################################

=head1 execute()

	INFO: main fn called by alignmentAndMutation.pm
	IN:   NIL.  Depends on obj's initialized data (new() a/o setup())
	OUT:  0 = success
	      ortholog list and their gene seq populated in obj's data struct

	INFO: calls various obj's fn to retrieve ortholog list
	      need to iteratively get seq for each ortholog gene


	main fn that 
	- query for primary gene id, 
	- query primary gene seq, populate into $self->{_geneSeqList}->[0]
	
	- store result in data structure of this class 
	  (populateOrthologList())
	  	- orchestrate call to dbQuery_mutList
		- creatae SQL (fn calls)

=cut

sub execute {
	my( $self, $nil ) = @_;
	$dbg->trace("orthologList::execute() begin" );

	my $sqlString = "oracle sql string tba";
	my $resultArrayRef;
	my $priGeneSeq;
	my $priGeneId;

	### === prepare pirmary gene info === ###
	#   geneSymbol is populated in new() or setup(), very basic obj's data
	#   add it right away to "ortholog list" index 0
	my $priGeneSymbol = $self->{_geneName};
	$self->{_geneSymbolList}->[0] = $priGeneSymbol;
	# store some static data into obj's primary gene info (ortholog index 0
	$self->{_taxoidList}->[0] = "9606";
	#$self->{_taxoidList}->[0] = "00_9606";		## ++ FIXME tmp tricking sort...
	$self->{_orgNameList}->[0] = "00_Human";
	$self->{_geneIdList}->[0] = "uninitialized at this point";
	$self->{_progiList}->[0]  = "uninitialized at this point";

	### == approach 1, get gene seq using gene id, abandoned == ###
	#my $priGeneId;
	# get gene id number from gene symbol, update into "ortholog list" index 0
	$sqlString = $self->prepareSQL_lookupGeneIdQ( $priGeneSymbol );
	$resultArrayRef = $self->dbQuery( $sqlString );
	$priGeneId = $self->resultArrayRef2string( $resultArrayRef );
	$self->{_geneId} = $priGeneId;
	$self->{_geneIdList}->[0] = $priGeneId;
	# lookup seq for primary gene, populate into orth list idx 0
	#~~ $priGeneSeq = $self->retrieveGeneSeq( $priGeneId );			#~~ query below

	### == approach 2, get gene seq using ncbi accession number == ###
	my $priGeneAccNum;
	$sqlString  = "select proacc from egene.homologene where  taxoid=9606 and genesymbol='";
	$sqlString .= uc( $priGeneSymbol );			##almost all uppercase, except 8603=C4orf8, 8725=c19orf2
	$sqlString .= "'";
	$resultArrayRef = $self->dbQuery( $sqlString );
	$priGeneAccNum = $self->resultArrayRef2string( $resultArrayRef );
	# store accession number into obj's primary gene info
	$self->{_geneAccNum} = $priGeneAccNum;
	$self->{_accNumList}->[0] = $priGeneAccNum;
	# lookup seq for primary gene
	#$priGeneSeq = $self->retrieveGeneSeq( $priGeneAccNum );
	$priGeneSeq = $self->retrieveGeneSeq( $priGeneId, $priGeneAccNum );		# for now, pass both id and acc#


	### === store the primary gene seq (into orth list idx 0) === ##
	$self->{_geneSeqList}->[0] = $priGeneSeq;

	### === prepare ortholog list === ###
	$sqlString = $self->prepareSQL_orthologQ();
	$resultArrayRef = $self->dbQuery( $sqlString );
	$self->populateOrthologList( $resultArrayRef );

	$dbg->trace("orthologList::execute() ending" );
	return 0;
} # end sub 


=head1 getOrthologCount()

	OUT: 	number indicating number of gene ortholog in this obj
		0 = gene itself, not an ortholog
		1 and above are actual orthologs

=cut

sub getOrthologCount {
	my( $self ) = @_;
	return $self->{_orthologCount};
}

=head1 retreieveOrganism()

	IN:		taxoid integer
	OUT:	organism name, string
	DESC:	essentially does SQL lookup of
			select organism from egene.taxonomy where taxo_id='9606'

			9606 	==> Homo sapiens
			315 	==> Pseudomonas sp. ATCC19151

	NOTE:	organism name slightly fixed for desired alignment output seq
			eg: Homo sapiens 		==> 00_Homo_sapiens
	            Canis familiaris	==> 20_Canis_familiaris
				Mus musculus		==> 30_Mus_musculus

	TBA:	Future, may add "relatedness score" in front of organism name
			so that alignment output will list org closest to human first
			would hopefully get the info in the DB

=cut

sub retrieveOrganism {
	my( $self, $taxoid ) = @_;

	## TBA ++ add taxoid check to be safe
	my $sqlQueryStr  = "select organism from egene.taxonomy where taxo_id='" ;
	$sqlQueryStr 	.= $taxoid;
	$sqlQueryStr 	.= "'";
	my $organismName = "org name";

	my $resultArrayRef = $self->dbQuery( $sqlQueryStr );
	my $dbResult = $self->resultArrayRef2string( $resultArrayRef );

	$dbResult =~ s/ /_/g;				# convert space to _
	if( $dbResult =~ 'Homo_Sapiens' ) {
		$organismName = "00_" . $dbResult;
	} elsif( $dbResult =~ 'Canis_familiaris' ) {
		$organismName = "20_" . $dbResult;
	} elsif( $dbResult =~ 'Mus_musculus' ) {
		$organismName = "30_" . $dbResult;
	} else {
		$organismName = $dbResult;
	} 
	# TBA++ add other relatedness score  or query for them from DB

	return $organismName;
} # end sub


=head1 retrieveGeneSeq()


	IN:		gene id number  <<< for now, req both input ... 
	IN: 	nucaccnum instead (ncbi accession number, eg NM_053056.1).
	OUT:	string with gene's sequence

	DESC: 	lookup in DB to see if geneid has sourceDB=GAD,
			For Human seq, likely yes (have some 56 rec) and use our internal Seq in Oracle
			For ortholog, it is likely have no info in sourceDB, retrieve seq from NCBI
			That's why use two input, most of the time this fn is to retrieve ortholog seq
			and caller already have Accession number, so easier that way
			

	SQL approach:
	Step 1:	use table GAD.GENE_VW, key = egeneid (geneid) 
	A:		SourceDB = GAD 	... query internal db for protein seq  (56 of these)
	B:		SourceDB = COSMIC 	... query NCBI  (some 18,487 entries)
				(store the NCBI Accession number while at it, 
				called AccNum or nucaccnum)

	

	GAD.transcript table has transcript_aa_seq column, 
		search by = Egeneid (eg 672, 595)
					(don't recommend) nucaccnum (eg NM_007294.1, NM_053056.1 ) 
		this table has 56 entries (GAD source) only.
		many entry would return two rows, sourceDB=GAD and then another =COSMIC
		Just really care to see if there is GAD

=cut

sub retrieveGeneSeq {
	my( $self, $geneId, $nucaccnum ) = @_;
	#my( $self, $nucaccnum, $tba ) = @_;
	#my( $self, $geneId, $tba ) = @_;
	$dbg->trace("orthologList::retrieveGeneSeq() starts.  params==@_==" );

	my( $sqlQuery, $resultArrayRef, $sourcedb, $geneSeq );
	#$geneSeq = "geneSeq = FIXME  ... not coded yet !! ++"; ## TMP only ++  FIXME <<
	$geneSeq = "x";		# some gene may not lookup to a seq, leave this for the alignment 
	#$sqlQuery = $self->prepareSQL_geneSeqQ( $geneId );

	### === find out where we can retrieve protein seq, GAD vs COSMIC (public) === ###
	#$sqlQuery  = "select sourcedb from gad.gene_vw where accnum='" . $nucaccnum . "'";
	$sqlQuery  = "select sourcedb from gad.gene_vw where egeneid='" . $geneId . "'";
	$resultArrayRef = $self->dbQuery( $sqlQuery );
	$sourcedb = "uninitialized";
	$sourcedb = $self->resultArrayRef2string( $resultArrayRef );

	### === check source and act accordingly === ###
	### for human, would find GAD and get seq locally
	### for non-human, the ortholog will have no entry for sourcedb, so will fall thru for sure and use ncbi_get()
	if( uc( $sourcedb ) =~ "GAD" ) {
		### === use internal DB for seq === ###
		# method 1, query by geneid  (recommended by Karen)
		$dbg->prt("orthologList::retrieveGeneSeq() GAD section, lookup ==$geneId==" );
		$sqlQuery  = "select transcript_aa_seq from gad.transcript where egeneid = '$geneId'";
		# method 2, query by accession num
		#2: $dbg->prt("orthologList::retrieveGeneSeq() GAD section, lookup ==$nucaccnum==" );
		#2: $sqlQuery  = "select transcript_aa_seq from gad.transcript where nucaccnum = '$nucaccnum'";
		$resultArrayRef = $self->dbQuery( $sqlQuery );
		$geneSeq = $self->resultArrayRef2string( $resultArrayRef );
	#} elsif( "COSMIC" eq uc( $sourcedb ) ) {
	} elsif( uc( $sourcedb ) =~ "COSMIC" ) {
		$dbg->prt("orthologList::retrieveGeneSeq() sourcedb did not contain GAD ==$sourcedb==, so will use ncbi_get()" );
		# not clear what is in cosmic...  
		# but it seems no seq info in oracle, just do ncbi query to genebank
	}


	### === use NCBI for seq === ###
	# if sequence length is too short, it obviously was not found in DB, so query NCBI instead
	if( length( $geneSeq ) < 15 )  {
		#$dbg->prt( "orthologList::retrieveGeneSeq(), calling ncbi_get w/ sourceDB==$sourcedb== ncbi get ==$nucaccnum==" );
		$geneSeq = $self->ncbi_get( $nucaccnum );
	}

	my $dbgText = substr( $geneSeq, 0, 10 );
	$dbg->trace("orthologList::retrieveGeneSeq() ends. used sourcedb==$sourcedb== geneSeq10==$dbgText==" );
	return $geneSeq;
} # end sub


=head1 ncbi_get()

	IN: 	NCBI Accession number eg NP_004332.2 (with version)
	OUT:	aa seq as simple string

	NOTE:	assume want to use specific version number
			may need to add some logic here to double check
			<< ++ FIXME

=cut

sub ncbi_get {
	my( $self, $accNum ) = @_;
	$dbg->trace("orthologList::ncbi_get() begin.  params :: @_ ::" );
	my $geneSeq = "NCBI seq info pending";
	my $gb;					# genband handler
	my $seq;                # will get a Bio:seq object
	my $seqText = "";		# scratch use

	#$seq = $gb->get_Seq_by_acc('NP_004324');                #Accession Number, no ver
	#print "\naa seq: "				. $seq->seq();
	#print "\nseq alphabet: "        . $seq->alphabet();
	#print "\nseq desc: "            . $seq->desc();
	#print "\ndisplay id: "          . $seq->display_id();  # = accession number
	#print "\nprimary id: "          . $seq->primary_id();
	#print "\nannotation: "          . $seq->annotation();   # return obj list
	#print "\n\n\n";

	eval {
		$gb = new Bio::DB::GenBank;
		$seq = $gb->get_Seq_by_version($accNum);  #Accession by spec ver
        # if above is not done, the error above cause program to terminate.
	};
	if( $@ ) {
        $dbg->prt( "ncbi_get returned an error, likely sequence :: $accNum :: not found \n" );
		$geneSeq = "x";
	} else {
        $dbg->prt( "ncbi_get ran fine for :: $accNum :: alphabet is ::" . $seq->alphabet() . "::\n" );
		$geneSeq = $seq->seq();
	}

	my $dbgText = substr( $geneSeq, 0, 10 );
	$dbg->trace("orthologList::ncbi_get() ends. geneSeq10==$dbgText==" );
	return $geneSeq;
} # end sub

=head1 produceFasta()

	IN:		full path to output a filename
	OUT:   	put out obj's ortholog list and their gene seq in FASTA format
	        usable by clustalw as input
	NOTE:	hope this is all that is needed as output
		may need to dump to a given filename
	FIxME ++ check this is what clustalw fn wants... and that it is sufficient
	2010.1220  	should be fine, bio:...:clustalw take fasta IN, 
			produce obj for my prog (alignmentAndMutation) to use

=cut

sub produceFasta {
	my( $self, $out, $tba ) = @_;
	$dbg->trace("orthologList::produceFasta() starting.  params and oututput ==@_==" );

	my $dbg_text = "";
	my $totalOrtholog = $self->{_orthologCount};
	my $ortholog_idx = 0;
	my $fastaLine;

	open FH, "+>", $out or Carp( "unable to write to tmp file $out\n" );

	#print FH "testing from produceFasta().  tin.\n" ;


	# ++ FIXME tmp code only, for now, just make sure getting right data...
	#--my $geneName = $self->{_geneIdList}->[0];
	my $geneName = $self->{_geneName};
	#my $geneSeq = $self->{_geneSeq};
	$dbg->prt( "obj primary gene name is  :: $geneName ::" ); 
	#$dbg->prt( "obj primary gene seq is :: $geneSeq ::" );     ## NO more gene seq  use idx=0...

	#$dbg->prt( "produceFasta reading from obj's {_geneIdList}[0] :: $self->{_geneIdList}->[0] ::\n" );

	#for( my $i=0; $i <= $totalOrtholog; $i++ ) {
	## FIXME idx=0 may not have fulll data... but this for loop is for testing for now only...
	for( my $i=0; $i <= $totalOrtholog; $i++ ) {

		$ortholog_idx = $i;
		#$dbg_text = $self->{_geneSymbolList}->[$ortholog_idx] . " " .
		#$self->{_geneIdList}->[$ortholog_idx] . " " .
		#$self->{_accNumList}->[$ortholog_idx] . " " .
		#$self->{_progiList}->[$ortholog_idx]  . " " .
		#$self->{_taxoidList}->[$ortholog_idx] . " " .
		#$self->{_geneSeqList}->[$ortholog_idx];
		#$dbg->prt( "produceFasta retrieved from obj :: $dbg_text (ortholog idx $ortholog_idx)::\n" );

		$fastaLine 	= '> ';
		$fastaLine .= $self->{_orgNameList}->[$ortholog_idx] ;
		$fastaLine .= '_';
		$fastaLine .= $self->{_accNumList}->[$ortholog_idx] ;
		$fastaLine .= '_';
		$fastaLine .= $self->{_taxoidList}->[$ortholog_idx] ;
		$fastaLine .= '_';
		$fastaLine .= $self->{_geneSymbolList}->[$ortholog_idx] ;
		$fastaLine .= "\n";
		print FH $fastaLine;
		print FH $self->{_geneSeqList}->[$ortholog_idx];
		print FH "\n";
	}

	close FH;
	$dbg->trace("orthologList::produceFasta() ending.  Last ortholog index==$ortholog_idx== file==$out==" );
	return 0;
} # end sub 


=head1 prepareSQL_orthologQ()

	IN: use obj's internal param 
	OUT: string with SQL stm for dbQuery to use (oracle sql)
	eg:  "select * from EGENE.HOMOLOGENE where GENESYMBOL='BRAF' "

	Final SQL (genename will be variable): 
	select A.geneid, B.taxoid, B.geneid, B.genesymbol, B.proAcc, B.progi
	from egene.homologene A left outer join egene.homologene B 
	on A.orthid = B.orthid 
	where B.taxoid<>9606 and
	A.geneid=(select geneid from egene.homologene where taxoid=9606 and genesymbol='BRAF');

	++ FIXME validate SQL to be valid, esp use of left outer join!

	Result table eg:
	673 9598 463781  BRAF            XP_001155024.1 114616352
	673 7165 1278538 AgaP_AGAP004699 XP_318144.4    158298052

    ++ when preparing clustalw, may want to list B.GENEID (same gene, diff organism)

	NOTE: see getOrthologList in alignmentAndMutation.pm, 
		likely can remove that code

=cut

sub prepareSQL_orthologQ {
	my( $self, $tba ) = @_;
	$dbg->trace("orthologList::prepareSQL_orthologQ begins" );
	#my $sqlQuery= 'select GENEID from EGENE.HOMOLOGENE' ;
	#my $sqlQuery= "select GENEID from EGENE.HOMOLOGENE where GENESYMBOL='BRAF' AND TAXOID=9606" ;
	#my $sqlQuery= "select * from EGENE.HOMOLOGENE where GENESYMBOL='BRAF' AND TAXOID=9606" ;
	#my $sqlQuery = "select * from EGENE.HOMOLOGENE where GENESYMBOL='BRAF' ";    # careful with ' and "
	## select stm above work! ^_^
	#my $sqlQuery = "select * from EGENE.HOMOLOGENE where GENESYMBOL='";
	my $sqlQuery = "";
	#$sqlQuery  = "select * from EGENE.HOMOLOGENE where GENESYMBOL='";
	#$sqlQuery .= uc( $self->{_geneName} );	
	#$sqlQuery .= "'";

	$sqlQuery  = "select A.geneid, B.taxoid, B.geneid, B.genesymbol, B.proAcc, B.progi ";
	$sqlQuery .= "from egene.homologene A left outer join egene.homologene B ";
	$sqlQuery .= "on A.orthid = B.orthid ";
	$sqlQuery .= "where B.taxoid<>9606 and ";
	$sqlQuery .= "A.geneid=(select geneid from egene.homologene where taxoid=9606 and genesymbol='";
	$sqlQuery .= uc( $self->{_geneName} );	
	$sqlQuery .= "')";

    $dbg->prt( "orthologList::prepareSQL_orthologQ will return sqlQuery of: $sqlQuery" );
    $dbg->trace("orthologList::prepareSQL_orthologQ ends" );
	return $sqlQuery;
} # end sub prepareSQL_orthologQ


=head1 prepareSQL_lookupGeneIdQ()

	IN:  string with gene symbol (gene name, english text string)
	OUT: string with SQL to query for geneid number from gene symbol, usable by dbQuery
         select geneid
    	 from egene.homologene 
    	 where  taxoid=9606 and genesymbol='BRAF';

	NOTE: fn may no longer be necessary, need ncbi accession number insteaed
		  and execute() create the query by itself.

=cut

sub prepareSQL_lookupGeneIdQ {
	my( $self, $geneSymbol ) = @_;
	$dbg->trace("orthologList::prepareSQL_lookupGeneIdQ begins" );
	#my $geneIdString = "0";
	my $sqlQuery = "TBA: oracle SQL query string goes here";

	$sqlQuery  = "select geneid from egene.homologene where  taxoid=9606 and genesymbol='";
	$sqlQuery .= uc( $geneSymbol );
	$sqlQuery .= "'";

    $dbg->prt( "returning sqlQuery of: $sqlQuery" );
	$dbg->trace("orthologList::prepareSQL_lookupGeneIdQ ends" );
	#return $geneIdString;
	return $sqlQuery;
} # end sub



=head1 prepareSQL_geneSeqQ()

	IN:  string with gene id number
	OUT: string with SQL to query for gene, usable by dbQuery
	NOTE: not sure if have to deal with multiple DB source...

	NOTE: alignmentAndMutation.pm getGeneSeq can probably move to here.

=cut

sub prepareSQL_geneSeqQ {
	my( $self, $tba ) = @_;
	$dbg->trace("orthologList::prepareSQL_geneSeqQ begins" );
	my $sqlQuery = "TBA: oracle SQL query string goes here";
	## ++ FIXME add code
	$sqlQuery = "select geneid from egene.homologene where genesymbol='FIXME'";

    $dbg->prt( "returning sqlQuery of: $sqlQuery" );
	$dbg->trace("orthologList::prepareSQL_geneSeqQ ends" );
	return $sqlQuery;
	
} # end sub

=head1 populateGeneSeq()

	IN:  DBI result_array ref obj returned by dbQuery
	     containing  gene name (or gene id) and long string with gene seq
	OUT: gene seq stored in obj's internal data structure

	FIXME:  this is obsolete sub that is no longer used,
	
=cut

## 	FIXME may not need this if execute() and populateGeneOrtholog() does the work.
sub populateGeneSeq {
	my( $self, $tba ) = @_;


	# FIXME add code, below is snipplet for eg ref use only

        $dbg->trace("PopulateGeneSeq() begins");
        #--$dbg->trace("xx  PopulateOrthologList begins");
        ##shift if( ref( $_[0] ) );
        # my( $self ) = $_[0];
        my( $geneName ) = $self->{_geneName};   # ie, it is in the obj, naming for easy manip
        my( $seq );

        ## FIXME  query DB for actual ortholog list
        $self->{_orthologsCount}=0;


                ## old block can be deleted...
                ## FIXME  for each ortholog, get seq
                ## add loop...
                $seq = getGeneSeq( "orthologName2" );

                ## need some array structure to store the orthologlist...
                $self->{_orthologLst}->[0]="orthologName1";
                $self->{_orthologSeq}->[0]="TBA1";              # index parallel ortholog gene name in the array
                $self->{_orthologLst}->[1]="orthologName2";
                $self->{_orthologSeq}->[1]=$seq;
				# some of the above usable in populateOrthologList  ++


} # end subpopulateGeneSeq


################################################################################

=head1 dbQuery() formerly dbQuery_mutList()

   	IN:  	SQL statement 
   	OUT:  	result_array_ref obj containing list of ortholog genes names
   			(std DBI result stuff, RTFM)
	NOTE: candidate for a DB-class to be inherited by this class
	NOTE: use dbQuery_... karen code as basis.
	## FIXME should place db username password etc here.


   db query code, adapted from Karen's code

   Does DB lookup:
## get ortholog lists...
## ref Perl cookbook p510
##  actually, can have caller construct SQL, this just return an array containing rows, 
## no need for specific procedure...
## caller may need special method to construct diff SQL, especially when trying to see if it has COSMIC or GAD seq.

   DBI->connect, if printError, will gable STDOUT !! 
   best find way to save STDOUT before this and then restore it...   
   2010.0923.

=cut 

##  this fn may not be complete R 2010.1224
sub dbQuery { 

	##return 004;

	$dbg->trace("orthologList::dbQuery() starting..." );

	my( $self, $query ) = @_;	
	#my( $query ) = @_;	## FIXME refine input param later

	## 2010.1212
	## ++ ortholog list may need to be a diff object, 
	## or place in separate module.. (but then procedure like :(
	## for now, just doing procedure-like call from alignmnetAndMutation.pm
	$dbg->prt("dbQuery will run sql of :: $query ::" );


	## if moving to dedicated DB module, consider dsn, user pw as obj's data.
	my( $dsn, $user, $passwd ); 	
    $user 	= "gad";                 
    $dsn 	= "dbi:Oracle:olydv1";          # olydv1 is dev
    $dsn 	= "dbi:Oracle:olytest1";        # olytest1 is test
    $passwd = "gad2dv1";					# gad
    $passwd = "gad2pr1";					# gad prod

    $user 	= "gad_r";                 
    $passwd = "gad_r";						# gad_r

	# ++ FIXME ortholog query don't work in gad_r, chk w/ Larry.

	my $dbh = DBI->connect($dsn,$user,$passwd,{PrintError => 1, RaiseError => 1, AutoCommit => 0, LongReadLen=> 5242880, LongTruncOk => 0});

	#my $query_symbol = 'BRAF'; ## FIXME  this is eg only.
	#my $SQL = "SELECT ... GENEID FROM EGENE.HOMOLOGENE WHERE GENESYMBOL=$query_symbol AND TAXOID=9606";
	## FIXME, above query not right, likely more convoluted than that to get ortholog list...

	my $sth = $dbh->prepare( $query );
	$sth->execute;
    my $array_ref = $sth->fetchall_arrayref();

	my $count;
	##--$dbg->prt( " ..dbQuery_orthList: @$array_ref" );
	$dbg->prt( " ..dbQuery_orthList: individual rows follow... " );
	foreach my $row (@$array_ref) {
		$count++;
		#my ($aaSyntax,$aaVarStart,$aaVarStop,$limitFlag,$mutCountPosition) = @$row;
		#print "$aaSyntax\t$aaVarStart\t$aaVarStop\t$mutCountPosition\n";
		## some record don't have aaVarStart, aaVarStop, eg
		## braf wildtype   0 3106
		##++print "@$row\n";
		$dbg->prt( "..dbQuery_orthList row...: @$row\n" ) if defined($row);
		## $row is a reference to an array, how to find out if it was populated??  <<FIXME
		## FIXME only if want to print stuff out here, else this for loop isn't needed.
	}
	$dbg->trace( "dbquery_orthList:: SQL call completed" );
	$sth->finish;
	$dbh->disconnect;
	$dbg->trace("dbQuery() ends" );
	return $array_ref;
}

=head1 resultArrayRef2string()

	convert dbQuery90's ref obj called resultArrayRef and turn it into a simple string
	useful for queries that return a single column, single row of data
	so that this generic fn parse the result and produce a string that can be stored and used

	IN:		reference obj retuned by dbQuery (DBI result_array_ref thingy)
	OUT: 	simple string

	NOTE:   if DBI result array ref has more than 1x1 table,
			everything get mushed up into a single string
			- end of column would be marked by ;
			## - end of row would be marked by :
			Could have a version that return list, but here I want text!

=cut

sub resultArrayRef2string {
	my( $self, $result_array_ref ) = @_;

	#$dbg->trace("resultArrayRef2string beings" );
	#my $resultString = "TBA... first row first column of db result table goes in here";
	my $resultString = "";
	my $resultCount = 0;
	foreach my $row_ref (@$result_array_ref) {
		#foreach my $row_element (@$row_ref) {
			$resultString .= " ; " if $resultCount;
			$resultString .= $$row_ref[0];
			#$resultString .= $row_element;
			++$resultCount;
		#}
		#$resultString .= " : ";
	}
	#if( $resultCount > 1 ) {
		#$dbg->prt("WARNING: resultArrayRef2string found more than 1 row, returning info from last row!!\n" );
	#}
	$dbg->prt("resultArrayRef2string will return==$resultString==\n" );
	#$dbg->trace("resultArrayRef2string ends" );
	return $resultString;
} # end sub




# end of package:
1;
