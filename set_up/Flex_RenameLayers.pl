#!perl -w

#####################################################################################
#							NAME:DFM Process GUI									#
#####################################################################################
#	PROJECT:	Flex DFM tools Suite compatible with Valor NPI						#
#####################################################################################
#	PURPOSE: Provide DFM engineers at Flextronics with a suite of tools that 		#
#			 assit them during the DFM job preparation and set up in order			#
#			 to speed the DFM cycle time											#
#####################################################################################
#	DISCLAIMER: Is strictelly prohibith the copy, modification or any kind of  		#
#			 alteration in the content of this script except for the author			#
#			 or authorized personel.												#
#####################################################################################
#	AUTHOR: WW DFx Support Team, AEG												#
#			Armando Alberto Garza Lara & Edgar Alfonso Ruiz Arellano				#
#			armando.garza@flextronics.com	+52 (33) 38183200 x3171					#
#			edgar.arellano@flextronics.com	+52 (33) 38183200 x6153					#
#			Flextronics, Guadalajara												#
#			Carretera Base Aerea #5850-4, La Mora									#
#			Zapopan, Jalisco, México 45136											#
#####################################################################################
#	Revision History: Wed March 16 08:59:09 2016	-Initial release				#
#																					# 
#	2016, Nov 14 - Include capability to handle multiple steps in the same job 		#
#					and also include the validation on the usage for Flextronics	#
#					domain and for DFM engineers inside Flextronics					#
#####################################################################################

#####################################################################################
#								DEFINE LIBRARY TO USE								#
#####################################################################################
use warnings;
use Tk;
use Tk::Balloon;
use Tk::BrowseEntry;
use Tk::Dialog;
use Tk::DialogBox;
use Tk::LabFrame;
use Tk::ProgressBar;
use Tk::JPEG;
use Tk::Photo;
use Tk::Pane;
use FindBin;
use Cwd;
use DBI;
use Data::Dumper qw(Dumper);
use File::Basename;
use File::Copy;
use File::Path;
use FileHandle;
use Sys::Hostname;
use strict;
use Env qw (VALOR_DATA JOB STEP GENESIS_LIB VALOR_DIR VALOR_EDIR VALOR_VER VALOR_HOME VALOR_TMP);
use lib ("$FindBin::Bin/../lib","${VALOR_EDIR}/all/perl",);
use Valor;
use vars qw(%RenameLyrs $F $JOB $STEP $TMP_DIR $MW $PROGRESS_FOLDER);
#####################################################################################

#####################################################################################
#									DEFINE VARIABLES								#
#####################################################################################
$JOB				=	$ENV{JOB};
$STEP				=	$ENV{STEP};
$TMP_DIR			=	$ENV{VALOR_TMP};
$F					=	new Valor;
my $prev_page		=	('Matrix_Review.pl');
my $mode            =   ('interactive');
my $input1	        =   shift;
if ($input1 ne ''){$mode = $input1;}
#####################################################################################
#								START FROM VALID JOB								#
#####################################################################################
if ($JOB eq "" || $STEP eq "")
	{
	$F->PAUSE("Script must start in Graphic Editor Screen!");
	exit 0;
	}
#####################################################################################
#								DEFINE PROGRESS FOLDER								#
#####################################################################################
validation();
progress_folder_read();
#####################################################################################
#								SCRIPT START HERE									#
#####################################################################################
#$F->PAUSE ("Hola Mundo!!!" );	
#####################################################################################
# 						Welcome informative Pause									#
#####################################################################################
if ($mode eq "interactive")
{
welcome_message(
"
This script will rename the outer layers of the board
inner layers keep with original names, drill layers are renamed
using a consecutive number when exist more than one drill layer","rename layers.gif"
);
}
verify_existing_layers();
main();
find_throughhole_drills();
remove_layer_subtype();

$F->COM("matrix_page_close,job=$JOB,matrix=matrix");
$F->COM("datum,x=0,y=0");

	my @drc_layers = ('fab_drc','drc_rout_keepin','keepin_layer','drc_tp_keepin','drc_rout_keepout','keepout_layer','drc_pad_keepout','drc_via_keepout','drc_trace_keepout','drc_plane_keepout','drc_comp_height','drc_tp_keepout');
	$F->DO_INFO("-t matrix -e $JOB/matrix -d NUM_LAYERS");


foreach my $drc_layer (@drc_layers)
	{
				my $STAT;
				$F->VOF;
					$F->COM("display_layer,name=$drc_layer,display=yes,number=1");
					$STAT = $F->{STATUS};
				$F->VON;
				$F->COM("clear_layers");
				$F->COM("affected_layer,mode=all,affected=no");

				if ($STAT == 0) 
				
					{
			
			
if ($mode ne "designers"){
warning_popup("
The layer $drc_layer already exist!!
It will be renamed to bk_$drc_layer
to avoid interference with Flex standard analysis
");}
					$F->COM("clear_layers");
					$F->COM("affected_layer,mode=all,affected=no");
					$F->COM("display_layer,name=$drc_layer,display=yes,number=1"); 
					$F->COM("work_layer,name=$drc_layer");

	my @drc_attributes = ('.area_name','.drc_bend_keepout','.drc_board','.drc_mech','.drc_etch_lyrs_all','.drc_comp_keepin','.drc_tp_keepin','.drc_route_keepin','.drc_comp_keepout','.drc_tp_keepout','.drc_trace_keepout','.drc_pad_keepout','.drc_plane_keepout','.drc_via_keepout','.drc_route_keepout','.drc_comp_height','.drc_ref_des','.drc_etch_lyrs','.drc_etch_lyrs_bit','.drc_assembly_lyrs','.drc_max_height','.drc_min_height',);					
	foreach my $drc_attributes (@drc_attributes)
										{
					$F->COM("sel_delete_atr,attributes=$drc_attributes\;,pkg_attr=no");  #Deleting of the attributes
										}
					$F->COM("clear_layers");
				    $F->COM("affected_layer,mode=all,affected=no");					
					
						my $STAT1;
						$F->VOF;
						$F->COM("display_layer,name=bk_$drc_layer,display=yes,number=1"); # Verify if the "bk_drc_ " layers already exist
						$STAT1 = $F->{STATUS};
						$F->VON;
					
						if ($STAT1 == 0) {
						$F->COM("delete_layer,layer=bk_$drc_layer"); }		#if the "bk_drc_ " layers already exist then they are deleted
					
					$F->COM("rename_layer,name=$drc_layer,new_name=bk_$drc_layer");					
					$F->COM("clear_layers");
				    $F->COM("affected_layer,mode=all,affected=no");
	}
	}

write_in_log ("Rename Layers");
create_flag_file ("Rename Layers");
exit (0);
#####################################################################################
#####################################################################################
#				SUB-RUTINE TO AUTOMATICALLY RUN THE NEXT SCRIPT 					#
#####################################################################################
sub run_next_script
{


#$F->PAUSE("Aqui vamos $mode");
if ($mode eq "silence"){
my $script_file_name	= 'set_board_thickness.pl';
alarm 0;
my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Matrix_review/" . $script_file_name);
my $a = $_[0];
system("perl $script $a") or print("NOTE: Script $script_file_name does not exist.","\n");
}

if ($mode eq "designers"){
my $script_file_name	= 'create_rout.pl';
my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Matrix_review/" . $script_file_name);
alarm 0;
my $a = $_[0];
system("perl $script $a") or print("NOTE: Script $script_file_name does not exist.","\n");
}

#if ($mode eq "interactive"){
#my $script_file_name	= 'set_board_thickness.pl';
#my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Matrix_review/" . $script_file_name);
#my $a = $_[0];
#system("perl $script $a") or print("NOTE: Script $script_file_name does not exist.","\n");
#}

}

sub main
{
	print("START SCRIPT...","\n");
	my $F = new Valor ;
	
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my $TempFile = ($ENV{VALOR_TMP} . "/infoout");

	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};

	## start a logfile
	my $logfilename = 'flex_dfm_process.log';
	if (-e $JOBPATH . "/user") {
		print("NOTE: user folder exist. Create logfile.","\n");
		open(LOGFILE, ">>" . $JOBPATH . "/user/" . $logfilename);
		
	}
	else {
		print("NOTE: user Folder NOT exist! Create it.\n");
		mkdir($JOBPATH . "/user");
		open(LOGFILE, ">>" . $JOBPATH . "/user/" . $logfilename);
	}


	#print("Job Path    = ", $JOBPATH, "\n");
	print("Job Name    = ", $JOB, "\n"); ##DEBUG
	#print("Step Name   = ", $STEP, "\n"); ##DEBUG
	#print("User Name   = ", $ENV{USERNAME}, "\n"); ##DEBUG
	#print("Temp Folder = ", $ENV{VALOR_TMP}, "\n"); ##DEBUG

	print LOGFILE ("SCRIPT				=	", "Rename Layers Script", "\n");
	print LOGFILE ("User Name      		= 	", $ENV{USERNAME}, "\n");
	print LOGFILE ("Job Path       		= 	", $JOBPATH, "\n");
	print LOGFILE ("Job Name       		= 	", $JOB, "\n"); 
	print LOGFILE ("Step Name      		= 	", $STEP, "\n"); 
	 

	$F->DO_INFO("-t matrix -e $JOB/matrix");
	foreach my $_row(@{$F->{doinfo}{gROWrow}})
	{
		my $row = ($_row - 1);
		#skip empty rows
		next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
		
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
				
		print("Processing row " . $row . "\n");
		# Process the layers and filter them for each layer type 
		# just renaming the outer layers right now.  Drill handling later.
		#-----------------------------------------------------------------
		
		#TOP SIDE LAYERS
#		sstop					Top Side Silkscreen                                #
#		Smtop					Top Side Soldermask                                #
#		pmtop					Top Side Solder Paste                              #
#		Top						Top Side Copper           		
		if((${$F->{doinfo}{gROWside}}[$row] eq "top")   )
		{
			if(${$F->{doinfo}{gROWlayer_type}}[$row] eq "silk_screen")
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "sstop";
			}
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "solder_mask")
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "smtop";
			}
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "solder_paste")
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "pmtop";
			}
			if ((${$F->{doinfo}{gROWlayer_type}}[$row] eq "signal") || (${$F->{doinfo}{gROWlayer_type}}[$row] eq "power_ground"))
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "top";
			}		
		}

		#BOTTOM SIDE LAYERS		
#		Bottom					Bottom Side Copper                                 #
#		Pmbot					Bottom Side Solder Paste                           #
#		Smbot					Bottom Side Soldermask                             #
#		Ssbot					Bottom Side Silk Screen                            #		
		if((${$F->{doinfo}{gROWside}}[$row] eq "bottom")   )
		{
			if(${$F->{doinfo}{gROWlayer_type}}[$row] eq "silk_screen")
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "ssbot";
			}
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "solder_mask")
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "smbot";
			}
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "solder_paste")
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "pmbot";
			}
			if ((${$F->{doinfo}{gROWlayer_type}}[$row] eq "signal") || (${$F->{doinfo}{gROWlayer_type}}[$row] eq "power_ground"))
			{
				$RenameLyrs{${$F->{doinfo}{gROWname}}[$row]}->{newname} = "bottom";
			}		
		}

	}
	
	# rename the top and bottom layers
	print LOGFILE ("\n Renaming Outer layers \n-----------------------\n\n");
	for my $oldlyr ( keys %RenameLyrs )
	{
		my $value = $RenameLyrs{$oldlyr}->{newname};
		print ("$oldlyr => $value \n");
		print LOGFILE ("$oldlyr => $value \n");
		
		$F->COM("open_entity,job=$JOB,type=matrix,name=matrix,iconic=no");
		$F->COM("matrix_rename_layer,job=$JOB,matrix=matrix,layer=$oldlyr,new_name=$value ");
	}
	
	print LOGFILE ("\n");
	print LOGFILE ("   ---------------------------------------------   ", "\n");
	print LOGFILE ("\n");
	
}
	
sub find_throughhole_drills
{
	my $F = new Valor ;
	$JOB = $ENV{JOB};
	my $drill_seq = 0;
	my $ndrill_seq = 0;
	
	$STEP = $ENV{STEP};
	my $TempFile = ($ENV{VALOR_TMP} . "/infoout");

	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};

	## start a logfile
	my $logfilename = 'flex_dfm_process.log';
	if (-e $JOBPATH . "/user") {
		print("NOTE: user folder exist. Create logfile.","\n");
		open(LOGFILE, ">>" . $JOBPATH . "/user/" . $logfilename);
		
	}
	else {
		print("NOTE: user Folder NOT exist! Create it.\n");
		mkdir($JOBPATH . "/user");
		open(LOGFILE, ">>" . $JOBPATH . "/user/" . $logfilename);
	}


	print LOGFILE ("\n Renaming Drill layers \n-----------------------\n\n");
	
	$F->DO_INFO("-t matrix -e $JOB/matrix");
	foreach my $_row(@{$F->{doinfo}{gROWrow}})
	{
		my $row = ($_row - 1);
		#skip empty rows
		next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
		
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
		
		if(${$F->{doinfo}{gROWlayer_type}}[$row] eq "drill")		
		{
			print("Processing drill layer in row " . $row . "\n");
			my $start_drill_span = ${$F->{doinfo}{gROWdrl_start}}[$row];
			my $end_drill_span = ${$F->{doinfo}{gROWdrl_end}}[$row];
			
			print ("Start is: $start_drill_span and end is: $end_drill_span for layer: ${$F->{doinfo}{gROWname}}[$row] \n");
			
			if (($start_drill_span eq "sstop") || ($start_drill_span eq "smtop") || ($start_drill_span eq "pmtop") || ($start_drill_span eq "top") || ($start_drill_span eq "comp_+_top"))
			{
				if (($end_drill_span eq "bottom") || ($end_drill_span eq "pmbot") || ($end_drill_span eq "smbot") || ($end_drill_span eq "ssbot") || ($end_drill_span eq "comp_+_bot"))
				{
					print("Looks like we have a through hole drill for layer:  ${$F->{doinfo}{gROWname}}[$row] \n");
					my $drillname = ${$F->{doinfo}{gROWname}}[$row];
					# Let's find out if the layer is purely non-plated or plated (??do we want to consider via??)
					my $drl_type = get_drill_type($drillname);
					print("We have a $drl_type type of layer \n");
					
					if ($drl_type eq "non_plated")
					{
						if ($ndrill_seq == 0)
						{
							print ("$drillname => Npdrill \n");
							print LOGFILE ("$drillname => Npdrill \n");
							$F->COM("open_entity,job=$JOB,type=matrix,name=matrix,iconic=no");
							$F->COM("matrix_rename_layer,job=$JOB,matrix=matrix,layer=$drillname,new_name=npdrill ");
							$ndrill_seq++;
						} else
						{
							my $ndrillname = ("Npdrill_" . $ndrill_seq);
							print ("$drillname => $ndrillname \n");
							print LOGFILE ("$drillname => $ndrillname \n");
							$F->COM("open_entity,job=$JOB,type=matrix,name=matrix,iconic=no");
							$F->COM("matrix_rename_layer,job=$JOB,matrix=matrix,layer=$drillname,new_name=$ndrillname ");	
							$ndrill_seq++;							
						}
					}
					
					if ($drl_type eq "plated")
					{
						if ($drill_seq == 0)
						{
							print ("$drillname => drill \n");
							print LOGFILE ("$drillname => drill \n");
							$F->COM("open_entity,job=$JOB,type=matrix,name=matrix,iconic=no");
							$F->COM("matrix_rename_layer,job=$JOB,matrix=matrix,layer=$drillname,new_name=drill ");
							$drill_seq++;
						} else
						{
							my $seqdrillname = ("drill_" . $drill_seq);
							print ("$drillname => $seqdrillname \n");
							print LOGFILE ("$drillname => $seqdrillname \n");
							
							$F->COM("open_entity,job=$JOB,type=matrix,name=matrix,iconic=no");
							$F->COM("matrix_rename_layer,job=$JOB,matrix=matrix,layer=$drillname,new_name=$seqdrillname ");
							$drill_seq++;							
						}
					}
					
				}

			}			
			
		}   
	}
	print LOGFILE ("\n");
	print LOGFILE ("   #############################################   ", "\n");
	print LOGFILE ("\n");
	
#---------------------------------------------------------------------------------------------------#
#                                          Set progress percentage                                  #
#---------------------------------------------------------------------------------------------------#
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_job_progress,value=10%");
#---------------------------------------------------------------------------------------------------#
}

sub get_drill_type
{
# checking if all the drill in the layer are of type plated/via or non_plated.  if so, 
# return one of the following non_plated, plated or mixed
#------------------------------------------
	my ($drillname) = @_;
	my $F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	
	my $non_plated_cnt = 0;
	my $plated_cnt = 0;
	my $via_cnt = 0;
	
	$F->DO_INFO("-t layer -e $JOB/$STEP/$drillname");
	foreach my $_toolnum(@{$F->{doinfo}{gTOOLnum}})
	{
		my $toolnum = ($_toolnum - 1);
		print("toolnum: $toolnum type is ${$F->{doinfo}{gTOOLtype}}[$toolnum] \n");
		
		if(${$F->{doinfo}{gTOOLtype}}[$toolnum] eq "non_plated")
		{
			$non_plated_cnt++;
		}
		if(${$F->{doinfo}{gTOOLtype}}[$toolnum] eq "plated")
		{
			$plated_cnt++;
		}
		if(${$F->{doinfo}{gTOOLtype}}[$toolnum] eq "via")
		{
			$via_cnt++;
		}
	}

	if (($non_plated_cnt > 0) && ($plated_cnt == 0) && ($via_cnt == 0))
	{
		# Got a Non-plated only drill layer
		print("found non_plated drill layer for layer $drillname \n");
		return("non_plated");
	} elsif  (($non_plated_cnt == 0) && (($plated_cnt > 0) || ($via_cnt > 0)))
	{
		# Got a plated only drill layer
		print("found plated drill layer for layer $drillname \n");
		return("plated");
	} else
	{
		# got a mixed drill layer
		print("found mixed drill layer for layer $drillname \n");
		return("plated");
	}
	
}

#####################################################################################
#		SUB-RUTINE to remove the backdrill subtype from layers inthe job			#
#####################################################################################
sub remove_layer_subtype
{
#--------------Set Variables ---------------
	my $JOB	= $ENV{JOB};
	my $STEP= $ENV{STEP};
	my $F	= new Valor;

	$F->DO_INFO("-t matrix -e $JOB/matrix");
	foreach my $_row(@{$F->{doinfo}{gROWrow}})
	{
		my $row = ($_row - 1);
		#skip empty rows
		next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
		
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
		
		#if(${$F->{doinfo}{gROWlayer_subtype}}[$row] eq "backdrill")
		if(${$F->{doinfo}{gROWcontext}}[$row] eq "board")			
		{
			if(${$F->{doinfo}{gROWlayer_subtype}}[$row] ne "")
			{
			my $layer_name = ${$F->{doinfo}{gROWname}}[$row];
			my $layer_subtype_name = ${$F->{doinfo}{gROWlayer_subtype}}[$row];
			$F->PAUSE("The subtype -- $layer_subtype_name -- will be remove for layer $layer_name");
			$F->COM("matrix_layer_sub_type,job=$JOB,matrix=matrix,layer=$layer_name,sub_type=");
			}
		}
	
	}
}

#####################################################################################
#					SUB-RUTINE TO Verify if layer exist								#
#####################################################################################
sub verify_existing_layers
{
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $F				=	new Valor;

	foreach my $side ("top","bottom")
	{
		my $exist_ss        = 0;
		my $exist_sp        = 0;
		my $exist_sm        = 0;
		my $layer_name      = 'none';
		$F->DO_INFO("-t matrix -e $JOB/matrix");
		foreach my $_row(@{$F->{doinfo}{gROWrow}})
		{	
			my $row = ($_row - 1);
				if($F->{doinfo}{gROWside}[$row] eq "$side")
				{	
					if ($F->{doinfo}{gROWlayer_type}[$row] eq 'silk_screen')
					{	
						$layer_name=$F->{doinfo}{gROWname}[$row];
						$exist_ss ++;
						if ($exist_ss == 2)
						{
						$F->PAUSE("WARNING!!! There are two or more silkscreen layers in $side side please keep only one for the job and re-run this script");
						exit 0;
						}
						clear_and_reset ();
					}
					if ($F->{doinfo}{gROWlayer_type}[$row] eq 'solder_paste')
					{	
						$layer_name=$F->{doinfo}{gROWname}[$row];
						$exist_sp ++;
						if ($exist_sp == 2)
						{
						$F->PAUSE("WARNING!!! There are two or more solder paste layers in $side side please keep only one for the job and re-run this script");
						exit 0;
						}
						clear_and_reset ();
					}
					if ($F->{doinfo}{gROWlayer_type}[$row] eq 'solder_mask')
					{	
						$layer_name=$F->{doinfo}{gROWname}[$row];
						$exist_sm ++;
						if ($exist_sm == 2)
						{
						$F->PAUSE("WARNING!!! There are two or more soldermask layers in $side side please keep only one for the job and re-run this script");
						exit 0;
						}
						clear_and_reset ();
					}					
				}

		}
		
	if ($mode ne "designers"){
		if ($exist_ss == 0)
			{
			$F->PAUSE("WARNING!!! Silkscreen layer does not exist in $side side");
			}
		if ($exist_sp == 0)
			{
			$F->PAUSE("WARNING!!! Solderpaste layer does not exist in $side side");
			}
		
							}
		if ($exist_sm == 0)
			{
			$F->PAUSE("WARNING!!! Soldermask layer does not exist in $side side");
			}
	}

}
#####################################################################################
#					SUB-RUTINE TO WRITE IN THE LOG FILE								#
#####################################################################################
sub write_in_log
{
	print("START LOG CREATION...","\n");
	my $F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my $datestamp = localtime ();
	my $host = hostname;
	my $script_name = $_[0];
	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};
	my $logfilename = 'flex_dfm_process.log';
	if (-e $JOBPATH . "/user")
		{
		print("NOTE: USER folder exist. Create logfile.","\n");
		open(LOGFILE, ">>" . $JOBPATH . "/user/" . $logfilename);
		}
	else{
		print("NOTE: USER Folder NOT exist! Create it.\n");
		mkdir($JOBPATH . "/user");
		open(LOGFILE, ">>" . $JOBPATH . "/user/" . $logfilename);
		}
	print LOGFILE ("SCRIPT				=	", $script_name, "\n");
	print LOGFILE ("Last Run Time		=	", $datestamp, "\n");
	print LOGFILE ("By User				=	", $ENV{USERNAME}, "\n");
	print LOGFILE ("From Computer		=	", $host, "\n");
	print LOGFILE ("In Domain			=	", $ENV{USERDNSDOMAIN}, "\n");
	print LOGFILE ("Job Name			=	", $JOB, "\n"); 
	print LOGFILE ("Step Name			=	", $STEP, "\n");
	print LOGFILE ("Job Path			=	", $JOBPATH, "\n");
	print LOGFILE ("Temporal Folder		=	", $ENV{VALOR_TMP}, "\n");
	print LOGFILE ("Valor Directory		=	", $ENV{VALOR_DIR}, "\n");
	print LOGFILE ("Executable Directory=	", $ENV{VALOR_EDIR}, "\n");
	print LOGFILE ("Valor Version		=	", $ENV{VALOR_VER}, "\n");
	print LOGFILE ("Valor Home			=	", $ENV{VALOR_HOME}, "\n");
	print LOGFILE ("\n");
	print LOGFILE ("   #############################################   ", "\n");
	print LOGFILE ("\n");
	close LOGFILE;
}
#####################################################################################
#					SUB-RUTINE TO CREATE FLAG FILES									#
#####################################################################################
sub create_flag_file
{
	print("START FLAG CREATION...","\n");
	my $F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my $datestamp = localtime (); 
	my $host = hostname;
	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};
	my $script_name = $_[0];
	my $logfilename = ($PROGRESS_FOLDER . "/" . $script_name . ".txt");
	if (-e $PROGRESS_FOLDER)
		{
		print("NOTE: Step Progress folder exist. Create flag_file.","\n");
		open(LOGFILE2, ">>" . $logfilename);
		}
	else{
		print("NOTE: Step Progress folder NOT exist! Create it.\n");
		mkdir($PROGRESS_FOLDER);
		open(LOGFILE2, ">>" . $logfilename);
		}
	print LOGFILE2 ("Last Run Time			=	", $datestamp, "\n");
	print LOGFILE2 ("By User				=	", $ENV{USERNAME}, "\n");
	print LOGFILE2 ("From Computer			=	", $host, "\n");
	print LOGFILE2 ("In Domain				=	", $ENV{USERDNSDOMAIN}, "\n");
	print LOGFILE2 ("Job Name				=	", $JOB, "\n"); 
	print LOGFILE2 ("Step Name				=	", $STEP, "\n");
	print LOGFILE2 ("Job Path				=	", $JOBPATH, "\n");
	print LOGFILE2 ("Temporal Folder		=	", $ENV{VALOR_TMP}, "\n");
	print LOGFILE2 ("Valor Directory		=	", $ENV{VALOR_DIR}, "\n");
	print LOGFILE2 ("Executable Directory	=	", $ENV{VALOR_EDIR}, "\n");
	print LOGFILE2 ("Valor Version			=	", $ENV{VALOR_VER}, "\n");
	print LOGFILE2 ("Valor Home				=	", $ENV{VALOR_HOME}, "\n");
	print LOGFILE2 ("\n");
	print LOGFILE2 ("   #############################################   ", "\n");
	print LOGFILE2 ("\n");
	close LOGFILE2;
}
#####################################################################################
#					SUB-RUTINE TO READ AND DEFINE PROGRESS FOLDER					#
#####################################################################################
sub progress_folder_read
{
#-------------------------Define Variables when no job is selected---------------------------------#
if ($JOB eq "" || $STEP eq "")
	{
	$PROGRESS_FOLDER	=	($TMP_DIR . "/progress");
	}
else 
	{
	#-------------------------GET JOB PATH---------------------------------#
	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};
	#----------------------------------------------------------#
	if (-e $JOBPATH . "/steps")
		{
			print("NOTE: Steps folder exist.","\n");
		}
			else{
				print("NOTE: Steps folder NOT exist! Create it.\n");
				mkdir($JOBPATH . "/steps")or print "NOTE: Can not create Steps folder";
				}
	#----------------------------------------------------------#
	$F->DO_INFO("-t job -e $JOB -d STEPS_LIST");
	foreach my $_stepslist(@{$F->{doinfo}{gSTEPS_LIST}})
		{
			#----------------------------------------------------------#			
			if (-e $JOBPATH . "/steps/" . $_stepslist . "/progress")
				{
					print("NOTE: STEP progress folder exist.","\n");
				}
					else{
						print("NOTE: STEP progress folder NOT exist! Create it.\n");
						mkdir($JOBPATH . "/steps/" . $_stepslist . "/progress")or print "NOTE: Can not create STEP progress folder";
						}		
			#----------------------------------------------------------#		
		}
	$PROGRESS_FOLDER	=	($JOBPATH . "/steps/" . $STEP . "/progress");
	}
}
#####################################################################################
#					SUB-RUTINE TO VALIDATE USER AND DOMAIN							#
#####################################################################################
sub validation
{
my $user     = $ENV{USERNAME};
my $domain   = $ENV{USERDNSDOMAIN};
my $computer = $ENV{COMPUTERNAME};
my $dfmuser  = $ENV{DFMR_FLEX_USER};
 if ($domain !~ /(flextronics)|(FLEXTRONICS)/ )
 {
 $F->PAUSE("Hi $user , you are not detected as Flextronics user, you are not authorized to use this solution please abort.");
 exit (0);
 }
  if ($dfmuser ne 'YES' )
 {
 $F->PAUSE("Hi $user , you are not detected as DFM Engineer, you are not authorized to use this solution please abort.");
  exit (0);
 }
}
#####################################################################################
#					SUB-RUTINE TO CREATE WELCOME POPUP								#
#####################################################################################
sub welcome_message
{
#----------------------GUI FORMAT  Variables-----------------------------------------
my $gui_title		= ("Flex Global DFM support");
my $bg_color		= ("black");
my $Fg_color		= ("white");
my $shadow_color	= ("grey50");
my $hgt_color		= ("orange");
my $btnbody_color	= ("dark grey");
my $exit_color		= ("red");
my $big_font		= ("Helvetica 18 italic bold");
my $medium_font		= ("Helvetica 12 italic");
my $small_font		= ("Helvetica 10 italic");
my $sentence		= $_[0];
#my $F				= new Valor;
#----------------------GUI Main construction----------------------------------------
alarm 60;
$SIG{ALRM} = sub { print "Flex RenameLayers Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
$MW = new MainWindow;
$MW->configure	(-title => 'Info');
$MW->geometry	("+200+50");
$MW->configure	(-background => $bg_color);
my $image_file_name = 'logo.bmp';
my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
my $picture_file_name = $_[1];
my $picture 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $picture_file_name);
my $icon 			= $MW->Photo(-file => $image);
$MW->idletasks;
$MW->iconimage	($icon);
my $balloon = $MW->Balloon();
#-----------------------------------------------------------------------------------

	my $msg_frame	= $MW->Frame(
								-relief => 'flat',
								-background => $bg_color,
								#-borderwidth => 6
								)
									->pack(
											-side => 'top', 
											-fill => 'x'
										   );
	my $mensaje = $msg_frame->Label(
				-pady		=> '1', 
				-padx		=> '1',
				-relief		=> 'flat', 
				-state		=> 'normal',
				-text		=> $sentence,
				-justify	=> 'center',
				-font		=> $big_font,
				-background => $bg_color,
				-foreground => $Fg_color,
				)
				->pack;
						
#-----------------------------------------------------------------------------

	my $pic_frame	= $MW->Frame(
								-relief => 'flat',
								-background => $bg_color,
								#-borderwidth => 6
								)
									->pack(
											-side => 'top', 
											-fill => 'x'
										   );
if (-e $picture)
	{
	my $Fotografia	= $pic_frame->Photo(-file => $picture);
	my $chk_btn01	= $pic_frame->Label(
										-pady 				=> '1', 
										-relief 			=> 'flat', 
										-padx 				=> '1', 
										#-state 				=> 'normal', 
										-justify 			=> 'left', 
										#-text 				=> $stage_01,
										#-font 				=> $medium_font,
										-background 		=> $bg_color,
										#-foreground 		=> $Fg_color,
										-activebackground	=> $hgt_color,
										#-activeforeground	=> $hgt_color,
										-image		=> $Fotografia	,
										)
											->pack(
													-side => 'top',
													-padx => 1,
													-pady => 1
													);
}

#-----------------------------------------------------------------------------

	my $but_frame	= $MW->Frame(
								-relief => 'flat',
								-background => $bg_color,
								#-borderwidth => 6
								)
									->pack(
											-side => 'top', 
											-fill => 'x'
										   );	
	my $button01 = $but_frame->Button(
				-pady				=> '1',
				-relief				=> 'raised', 
				-padx				=> '1', 
				-state				=> 'normal', 
				-justify			=> 'center', 
				-background			=> $btnbody_color,
				-activebackground	=> $hgt_color,
				-foreground			=> $bg_color,
				-text    			=> 'Continue',
				-font 				=> $small_font,
				-command 			=> [$MW => 'destroy']
				)
				->pack(
						-side => 'right'
						);
	my $button02 = $but_frame->Button(
				-pady				=> '1',
				-relief				=> 'raised', 
				-padx				=> '1', 
				-state				=> 'normal', 
				-justify			=> 'center', 
				-background			=> $btnbody_color,
				-activebackground	=> $exit_color,
				-foreground			=> $bg_color,
				-text    			=> 'Abort Script',
				-font 				=> $small_font,
				-command 			=> sub{exit(0)},
				)
				->pack(
						-side => 'left'
						);										   
MainLoop;
}
#####################################################################################
#					SUB-RUTINE TO CREATE FINISH POPUP								#
#####################################################################################
sub success_run
{
#----------------------GUI FORMAT  Variables-----------------------------------------
my $gui_title		= ("Flex Global DFM support");
my $bg_color		= ("black");
my $Fg_color		= ("white");
my $shadow_color	= ("grey50");
my $hgt_color		= ("orange");
my $btnbody_color	= ("dark grey");
my $exit_color		= ("red");
my $big_font		= ("Helvetica 18 italic bold");
my $medium_font		= ("Helvetica 12 italic");
my $small_font		= ("Helvetica 10 italic");
my $sentence = $_[0];
#----------------------GUI Main construction----------------------------------------
$MW = new MainWindow;
$MW->configure	(-title => 'Info');
$MW->geometry	("+300+300");
$MW->configure	(-background => $bg_color);
my $image_file_name = 'logo.bmp';
my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
my $icon 			= $MW->Photo(-file => $image);
$MW->idletasks;
$MW->iconimage	($icon);
my $balloon = $MW->Balloon();
#-----------------------------------------------------------------------------------
	$MW->Label(
				-pady		=> '1', 
				-padx		=> '1',
				-relief		=> 'flat', 
				-state		=> 'normal',
				-text		=> $sentence,
				-justify	=> 'center',
				-font		=> $big_font,
				-background => $bg_color,
				-foreground => $Fg_color,
				)
				->pack;
	$MW->Button(
				-pady				=> '1',
				-relief				=> 'raised', 
				-padx				=> '1', 
				-state				=> 'normal', 
				-justify			=> 'center', 
				-background			=> $btnbody_color,
				-activebackground	=> $hgt_color,
				-foreground			=> $bg_color,
				-text    			=> 'close',
				-font 				=> $small_font,
				-command 			=> [$MW => 'destroy']
				)
				->pack(
						-side => 'top'
						);
MainLoop;
}
#####################################################################################
#					SUB-RUTINE TO RETURN TO MENU									#
#####################################################################################
sub back_to_menu 
{
my $script_file_name	= $_[0];
my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/" . $script_file_name);
system("perl $script") or print("NOTE: Script $script_file_name does not exist.","\n");
}
#####################################################################################
#					SUB-RUTINE TO CLEAR AND RESET									#
#####################################################################################
sub clear_and_reset
{
	# Clears selects, highlights, layers, and resets filters
	my $F = new Valor;
	
	$F->COM("zoom_home");
	$F->COM("clear_highlight");
	$F->COM("sel_clear_feat");
	$F->COM("filter_reset,filter_name=popup");
	$F->COM("filter_atr_reset");
	$F->COM("cur_atr_reset");
	$F->COM("affected_layer,name=,mode=all,affected=no");
	$F->COM("clear_layers");
	$F->COM("zoom_refresh");
}

#####################################################################################
#					SUB-RUTINE TO CREATE WARNING POPUP								#
#####################################################################################
sub warning_popup
{
#----------------------GUI FORMAT  Variables-----------------------------------------
my $gui_title		= ("Flex Global DFM support");
my $bg_color		= ("black");
my $fg_color		= ("white");
my $shadow_color	= ("grey50");
my $hgt_color		= ("orange");
my $btnbody_color	= ("dark grey");
my $exit_color		= ("red");
my $big_font		= ("Helvetica 18 italic bold");
my $medium_font		= ("Helvetica 12 italic");
my $small_font		= ("Helvetica 10 italic");
my $sentence = $_[0];
#----------------------GUI Main construction----------------------------------------
$MW = new MainWindow;
$MW->configure	(-title => 'Error Message');
$MW->geometry	("+100+300");
$MW->configure	(-background => $bg_color);
my $image_file_name = 'logo.bmp';
my $error = 'warning.bmp';
my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
my $errorimage 		= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $error);
my $icon 			= $MW->Photo(-file => $image);
$MW->idletasks;
$MW->iconimage	($icon);
my $balloon = $MW->Balloon();
#-----------------------------------------------------------------------------

	my $pic_frame	= $MW->Frame(
								-relief => 'flat',
								-background => $bg_color,
								#-borderwidth => 6
								)
									->pack(
											-side => 'left', 
											-fill => 'x'
										   );
if (-e $errorimage)
	{
	my $fotografia	= $pic_frame->Photo(-file => $errorimage);
	my $chk_btn01	= $pic_frame->Label(
										-pady 				=> '1', 
										-relief 			=> 'flat', 
										-padx 				=> '1', 
										#-state 				=> 'normal', 
										-justify 			=> 'left', 
										#-text 				=> $stage_01,
										#-font 				=> $medium_font,
										-background 		=> $bg_color,
										#-foreground 		=> $fg_color,
										-activebackground	=> $hgt_color,
										#-activeforeground	=> $hgt_color,
										-image		=> $fotografia	,
										)
											->pack(
													-side => 'top',
													-padx => 1,
													-pady => 1
													);
}

#-----------------------------------------------------------------------------

	my $msg_frame	= $MW->Frame(
								-relief => 'flat',
								-background => $bg_color,
								#-borderwidth => 6
								)
									->pack(
											-side => 'left', 
											-fill => 'x'
										   );

	my $lbl01=$msg_frame->Label(
				-pady		=> '1', 
				-padx		=> '1',
				-relief		=> 'flat', 
				-state		=> 'normal',
				-text		=> $sentence,
				-justify	=> 'center',
				-font		=> $big_font,
				-background => $bg_color,
				-foreground => $fg_color,
				)
				->pack;
#-----------------------------------------------------------------------------------


	my $btn01=$msg_frame->Button(
				-pady				=> '1',
				-relief				=> 'raised', 
				-padx				=> '1', 
				-state				=> 'normal', 
				-justify			=> 'center', 
				-background			=> $btnbody_color,
				-activebackground	=> $hgt_color,
				-foreground			=> $bg_color,
				-text    			=> 'close',
				-font 				=> $small_font,
				-command 			=> [$MW => 'destroy']
				)
				->pack(
						-side => 'top'
						);
MainLoop;

}