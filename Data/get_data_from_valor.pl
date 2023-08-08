#!perl -w

use strict;
use warnings;
use File::Basename;

#
#	if a script will be located in a folder. having the .'\..' will go up a lvl in the Dir
#	adding a lib to @INC just to be able to use the DFM_Util.pm
#

use lib (dirname(__FILE__).'\..');
use DFM_Util;




#
#	side note: thank you to:
#			Armando Alberto Garza Lara & Edgar Alfonso Ruiz Arellano & Samuel Flores
#			for supplying the original script and saving me time to write it myself.
#

my @attrtobesetlist   = ("_customer",
							"_pcb_fab_number",
							"_pcb_fab_ver",
							"_pcb_assembly_num",
							"_pcb_assembly_ver",
							"_dfm_type",
							"_requisition_id",
							"_dfm_center",
							"_dfm_engineer",
							"_assy_tech_class",
							"_fab_tech_class",
							"_finish",
							"_rohs",
							"_depanelling",
							"_conf_coat",
							"_p_in_hole",
							"_underfill",
							"_rf",
							"_u_via_in_job",
							"_s2s_job");

foreach my $attr2beset (@attrtobesetlist){
	check_attributes ($attr2beset);
}

# now @attrtobesetlist holds all the results from Valor.
# to be able to pass that info to to the FAB GUI ill be using the same method as the caller. just at the JOB folder this time
# no there should be already a file ready

sub check_attributes{
my $JOB			=	$ENV{JOB};
my $STEP		=	$ENV{STEP};
my $TMP_DIR		=	$ENV{VALOR_TMP};
my $V			=	new Valor;
my $counter 	= 	0;
my $attr_name   = $_[0];
	#----------------------------------------------------------#
		$V->DO_INFO("-t job -e $JOB -m script -d ATTR -u no");
		foreach my $attr(@{$V->{doinfo}{gATTRname}})
	{
		if ( $attr eq "$attr_name")
		{  
			$attr_value = $V->{doinfo}{gATTRval}[$counter];
				if ( $attr_name eq "_customer")         {$customer      = $attr_value;}
				if ( $attr_name eq "_pcb_fab_number")   {$pcbname       = $attr_value;}
				if ( $attr_name eq "_pcb_fab_ver")      {$pcbrev        = $attr_value;}
				if ( $attr_name eq "_pcb_assembly_num") {$pcbaname      = $attr_value;}
				if ( $attr_name eq "_pcb_assembly_ver") {$pcbarev       = $attr_value;}
				if ( $attr_name eq "_dfm_type")         {$type          = $attr_value;}
				if ( $attr_name eq "_requisition_id")   {$reqid         = $attr_value;}
				if ( $attr_name eq "_dfm_center")       {$dfmcenter     = $attr_value;}
				if ( $attr_name eq "_dfm_engineer")     {$dfmengineer   = $attr_value;}
				if ( $attr_name eq "_assy_tech_class")  {$assytechclass = $attr_value;}
				if ( $attr_name eq "_fab_tech_class")   {$fabtechclass  = $attr_value;}
				if ( $attr_name eq "_finish")           {$surfacefinish = $attr_value;}
				if ( $attr_name eq "_rohs")             {$rohs          = $attr_value;}
				if ( $attr_name eq "_depanelling")      {$depanel       = $attr_value;}
				if ( $attr_name eq "_conf_coat")        {$conformal     = $attr_value;}
				if ( $attr_name eq "_p_in_hole")        {$pasteinhole   = $attr_value;}
				if ( $attr_name eq "_underfill")        {$underfill     = $attr_value;}
				if ( $attr_name eq "_rf")               {$rfmicrou      = $attr_value;}
				if ( $attr_name eq "_u_via_in_job")     {$microvia      = $attr_value;}
				if ( $attr_name eq "_s2s_job")          {$s2sjob        = $attr_value;}
		}	
		$counter = $counter + 1;
	}
	#----------------------------------------------------------#	
}