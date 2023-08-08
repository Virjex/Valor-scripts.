#!perl -w

use strict;
use warnings;
use File::Basename;
use Valor;
#
#	if a script will be located in a folder. having the .'\..' will go up a lvl in the Dir
#	adding a lib to @INC just to be able to use the DFM_Util.pm
#

use lib (dirname(__FILE__).'\..');
use DFM_Util;

my $V = Valor->new();
my $JOB = $ENV{JOB};
my $STEP = $ENV{STEP};

DFM_Util::valor("matrix_add_row,job=$JOB,matrix=matrix");
$V->DO_INFO("-t matrix -e $JOB/matrix");
my $layer_count = $V->{doinfo}{gNUM_ROWS};
my $lastrow = 0;
#run till ill hit a first misc and save the result to know till what row i should be coppying.
foreach my $_row(@{$V->{doinfo}{gROWrow}}){
	my $row = ($_row - 1);
	#skip empty rows
	if(${$V->{doinfo}{gROWtype}}[$row] eq "empty" || ${$V->{doinfo}{gROWcontext}}[$row] eq "misc"){
		$lastrow = $row;
		last;
	};
}
( $layer_count ) = $layer_count =~ /(\d+)/;
my $change_to_mixed = 0;
my $name = '';
my $i = $lastrow;
while( $i > 0 ){
	if(${$V->{doinfo}{gROWname}}[$i-1] eq 'top') {
		$change_to_mixed = 0;
	}
	if( ${$V->{doinfo}{gROWname}}[$i-1] eq 'comp_+_top' || ${$V->{doinfo}{gROWname}}[$i-1] eq 'comp_+_bot' || ${$V->{doinfo}{gROWlayer_type}}[$i-1] eq "dielectric" ){
		$i--;
		next ;
	} elsif ($change_to_mixed) {
		$name = ${$V->{doinfo}{gROWname}}[$i-1];
		DFM_Util::valor("matrix_layer_type,job=$JOB,matrix=matrix,layer=$name,type=mixed");
	}
	DFM_Util::valor("matrix_copy_row,job=$JOB,matrix=matrix,row=$i,ins_row=$layer_count",
					"matrix_refresh,job=$JOB,matrix=matrix");
	
	if ( ${$V->{doinfo}{gROWname}}[$i-1] eq 'bottom' ){
		$change_to_mixed = 1;
	} 
	
	
	$i--;	
	$V->DO_INFO("-t matrix -e $JOB/matrix");
	$name = ${$V->{doinfo}{gROWname}}[$layer_count-1];	
	DFM_Util::valor("matrix_layer_context,job=$JOB,matrix=matrix,layer=$name,context=misc",
			"matrix_layer_type,job=$JOB,matrix=matrix,layer=$name,type=document");

}