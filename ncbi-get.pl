#!/usr/prog/perl/5.10.1/bin/perl
# !/usr/bin/perl

=head1

	Example script to retrieve seq from NCBI GenBank
	ref: http://doc.bioperl.org/releases/bioperl-1.4/Bio/DB/GenBank.html

=cut



use strict;
use warnings;
use Carp;
#use CGI;
use Bio::DB::GenBank;
use tinDbg;
#use lib "/home/hoti1/sci/bioinfo/";

##-- $| = 1;  # make unbuffered
my $dbg = tinDbg->new();
$dbg->setLevel(8);



my $gb = new Bio::DB::GenBank;
#my $gb = new Bio::DB::GenBank(-format => 'Fasta');
my $seq;		# will get a Bio:seq object
my $seqio;		# will get a Bio::SeqIO stream obj

my $seqText;

$seq = $gb->get_Seq_by_acc('NP_004324');		#Accession Number, no ver
$dbg->prt("completed gb->get_Seq_by...\n" );
$seqText = $seq->seq();
print $seqText . "\n";
print "\nseq alphabet: " 	. $seq->alphabet();
print "\nseq desc: "		. $seq->desc();
print "\ndisplay id: "		. $seq->display_id();  # = accession number
print "\nprimary id: "		. $seq->primary_id();
print "\nannotation: "		. $seq->annotation();	# return obj list
print "\n\n\n";



$seq = $gb->get_Seq_by_version('NP_004324.2');	#Accession by spec ver
$dbg->prt("completed gb->get_Seq_by...\n" );
$seqText = $seq->seq();
print $seqText . "\n";


$seqio = $gb->get_Stream_by_acc(['NP_004324', 'NP_004325'] );
$dbg->prt("completed gb->get_Stream_by...\n" );
$seqio = $gb->get_Stream_by_version(['NP_004324.2', 'NP_004325.1'] );
$dbg->prt("completed gb->get_Stream_by...\n" );
## but no get_Stream_by_version as of bioperl 1.4  FIXME



eval {
	$seq = $gb->get_Seq_by_version('throw_error');	#Accession by spec ver
	# if above is not done, the error above cause program to terminate.
};
if( $@ ) {
	print "get_Seq_... returned an error\n";
} else {
	print "get_Seq_... ran fine\n";
}

#$dbg->prt("completed gb->get_Seq_by...\n" );

# the end for now...
print "the end for now.\n";
exit 0;



$dbg->print( "Test dbg object\n" );
$dbg->setLevel(8);
#$dbg->setLevel(0);
$dbg->prt( "Test dbg object.  This print only when debug level is set to > 0\n" );


exit 0;

