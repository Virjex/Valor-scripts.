#!perl -w # always with warnings on..
#####################################################################
# NAME:	GenFiles_Flex.pl											#
#####################################################################
# PROJECT:	OOTB Scripting Suite									#
#####################################################################
#																	#
#    ---------------------------------------------------------------#
# AUTHOR:   WW DFx Support Team, AEG                                #
#           Edgar Alfonso Ruiz Arellano                             #
#           Flextronics, Guadalajara                                #
#           Carretera Base Aerea #5850-4, La Mora                   #
#           Zapopan, Jalisco, Mexico 45136                          #
#           edgar.arellano@flextronics.com                          #
#           Office +52 (33) 38183200 x6153                          #
#           Mobile +52 (1) 3314664409                               #
#####################################################################
# PURPOSE:	This program generate the output files from Valor		#
#																	#
#####################################################################
# Rev History:	September 18 , 2015  								#
#				- Include the output of dummy file to be able to	#
#				  handle jobs without checklist 					#
#				  for the YE functionality							#
#####################################################################
# 				October 13 , 2015  									#
#				- Include the output of copper balance report		#
#				  													#
#####################################################################
#				August 20 , 2016 Re-build the code to recognize     #
#				- Checklist and actions from valor instead folders  #
#####################################################################

#####################################################################################
#								DEFINE LIBRARY TO USE								#
#####################################################################################
use warnings;
use Tk;
use Tk::Animation;
use Tk::Balloon;
use Tk::BrowseEntry;
use Tk::Dialog;
use Tk::DialogBox;
use Tk::LabFrame;
use Tk::ProgressBar;
use Tk::JPEG;
use Tk::Photo;
use threads;
use threads::shared;
use FindBin;
use Cwd;
use DBI;
use Data::Dumper qw(Dumper);
use File::Basename;
use File::Copy;
use File::Path;
use FileHandle;
use Sys::Hostname;
#use strict;
use Env qw (VALOR_DATA JOB STEP GENESIS_LIB VALOR_DIR VALOR_EDIR VALOR_VER VALOR_HOME VALOR_TMP);
use lib ("$FindBin::Bin/../lib","${VALOR_EDIR}/all/perl",);
use Valor;
use vars qw( $BOM $skip_keepoutgerber $skip_bom $skip_idf $skip_pictures $SURFACE_FINISH $SM_LY_NAME_BOT $SM_LY_NAME_TOP $EXIST_SM_TOP $EXIST_SM_BOT $EXIST_COMP_TOP $EXIST_COMP_BOT $DOINFO $F $JOB $JOBPATH $MW $OUTPUT $PROGRESS_FOLDER $STEP $TMP_DIR $EXTRA_OUTPUT_FILE );
#####################################################################################

#####################################################################################
#									DEFINE VARIABLES								#
#####################################################################################
$JOB				=	$ENV{JOB};
$STEP				=	$ENV{STEP};
$TMP_DIR			=	$ENV{VALOR_TMP};
$F					=	new Valor;
	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};
#--------------------------------------------------------------------
my $wrk              = ("$JOBPATH/output/doinfo/*.wrk*");  
my $pcb_file         = ("$JOBPATH/output/doinfo/pcb.txt"); 
my $entity_attr_file = ("$JOBPATH/output/doinfo/job_entity_attributes.txt");
my $lay_count_file   = ("$JOBPATH/output/doinfo/job_layer_count.txt");
my $brd_size_file    = ("$JOBPATH/output/doinfo/job_board_size.txt");
my $components_file  = ("$JOBPATH/output/doinfo/job_components.txt");
my $bom_export_file  = ("$JOBPATH/output/doinfo/bom_export");
my $chkdir           = ("$JOBPATH/steps/$STEP/chk");
my $work_file        = ("$VALOR_TMP/work");
my $model_file       = ("$VALOR_TMP/erf_models");
my $act_status_file  = ("$VALOR_TMP/act_status");
my $out_title_file   = ("$VALOR_TMP/title");
my $out_file         = ("$JOBPATH/output/doinfo/out");
my $comp_fall_off_file   = "$JOBPATH/output/doinfo/component_fall_off.txt";
my $copper_balance_file  = "$JOBPATH/output/doinfo/copper_balance.txt";
my $hole_size_file  = "$JOBPATH/output/doinfo/hole_size.txt";
$SURFACE_FINISH = 4;



clear_and_reset();
mergepcbwithoutputfiles();
mergepcbwithcubalancefiles();
mergepcbwithholesizefiles();
merge_pcb_with_other_file("step_up_part.txt");
makedummypcbfile() ;
delete_layers_from_prev_run();
create_temp_layers();
evaluate_product_configuration();
delete_temp_layers();
create_layer_list();
discover_surface_finish();
take_snapshots();
delete_layers_from_prev_run();
clear_and_reset();



sub mergepcbwithcubalancefiles
{

	if (-e $copper_balance_file ) {
	
	my @fileRows = readFile($copper_balance_file);
	
	#$F->PAUSE("rows $fileRows");
	open (OUTPUT, ">>$pcb_file") or die $F->PAUSE("die $pcb_file");;
	for (@fileRows) { # read a line of input from myscript.pl
		#$F->PAUSE("data $_");
		if($_ !~ m/\s\?\s/)   #This field change for Valor 9.5.1 compativility
		{
			 print OUTPUT $_;  # print it to the output handle
		}	
	}
	close OUTPUT;
	}
	else {
		print("NOTE: Component Fall off results NOT exist!\n");
		
	}
	
}


sub mergepcbwithoutputfiles()
{

	#$F->PAUSE("appendToPCBFile $comp_fall_off_file");
	if (-e $comp_fall_off_file ) {
	
	my @fileRows = readFile($comp_fall_off_file);
	
	#$F->PAUSE("rows $fileRows");
	open (OUTPUT, ">>$pcb_file") or die $F->PAUSE("die $pcb_file");;
	for (@fileRows) { # read a line of input from myscript.pl
		#$F->PAUSE("data $_");
		if($_ !~ m/\s\?\s/)   #This field change for Valor 9.5.1 compativility
		{
			 print OUTPUT $_;  # print it to the output handle
		}	
	}
	close OUTPUT;
	}
	else {
		print("NOTE: Component Fall off results NOT exist!\n");
		
	}
	
}

sub discover_surface_finish
{
clear_and_reset ();
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $TMP_DIR			=	$ENV{VALOR_TMP};
my $F				=	new Valor;
my $sidearry_indx 	= 	0;
my $evaluated_value;


		$F->DO_INFO("-t job -e $JOB -m script -d ATTR -u no");
		foreach my $attr(@{$F->{doinfo}{gATTRname}})
	{
		if ( $attr eq "_finish")
		{
			$evaluated_value = $F->{doinfo}{gATTRval}[$sidearry_indx];
			if ($evaluated_value eq "osp")
			{
			$SURFACE_FINISH = 19;  #OPTIONS = set_an_option;enig;hasl;osp;immersion_silver;immersion_tin;other
			}
			if ($evaluated_value eq "enig")
			{
			$SURFACE_FINISH = 23;  #OPTIONS = set_an_option;enig;hasl;osp;immersion_silver;immersion_tin;other
			}
			#else {$SURFACE_FINISH = 4;}
		}
		$sidearry_indx = $sidearry_indx + 1;
	}
	#$F->PAUSE("Surface finish Value : $SURFACE_FINISH ");
}


sub create_layer_list
{
	my $F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
#####################################################################################
#								START FROM VALID JOB								#
#####################################################################################
if ($JOB eq "" || $STEP eq "")
	{
	$F->PAUSE("Script must start in Graphic Editor Screen!");
	exit 0;
	}
#####################################################################################
my $layer_list_file = ("$JOBPATH/output/doinfo/layer_list.txt");
#####################################################################################
# 					Removes any previous layer list if it exist						#
#####################################################################################
 unlink glob $layer_list_file;
#####################################################################################
# 					Create the layer list file Heather								#
#####################################################################################
	if (-e $JOBPATH . "/output/doinfo/") {
		print("NOTE: user folder exist. Create logfile.","\n");
		open( LISTFILE, ">$layer_list_file");
				
	}
	else {
		print("NOTE: user Folder NOT exist! Create it.\n");
		mkdir($JOBPATH . "/output/doinfo/");
		open( LISTFILE, ">$layer_list_file");
	}
	print LISTFILE ("##########################################################\n");
	print LISTFILE ("#         				LAYER LIST  					 #\n");
	print LISTFILE ("##########################################################\n\n\n");
	close LISTFILE;
#####################################################################################
$F->DO_INFO("-t matrix -e $JOB/matrix -m script -d ROW");
foreach my $_row(@{$F->{doinfo}{gROWrow}})
	{
		my $row = ($_row - 1);
		
		#skip empty rows
		next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
		
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
		#print("Processing row " . $row . "\n");
		
		
		# Process the layers that are only layers in the board
		if(${$F->{doinfo}{gROWcontext}}[$row] eq "board")
		{
			$layer = ${$F->{doinfo}{gROWname}}[$row];
			$layertype = ${$F->{doinfo}{gROWlayer_type}}[$row];
			$layerside = ${$F->{doinfo}{gROWside}}[$row];
			#$F->PAUSE("BOARD LAYER =  $layer");
			#-------------------------------------------------------------------------------------------
						my $attrval='0';
						$F->DO_INFO("-t layer -e $JOB/$STEP/$layer -m script -d ATTR");
						my $counter = 0;
						foreach my $_attr(@{$F->{doinfo}{gATTRname}})
								{					
										if ( $_attr eq ".eda_layers")	
												{
												$attrval = $F->{doinfo}{gATTRval}[$counter];
												$attrval =~ s/ /_/g;
												$attrval =~ s/:/\//g;
												$attrval =~ tr/[A-Z]/[a-z]/;												
												#$F->PAUSE("$layer , $layertype , $attrval");
													open(LISTFILE, ">>$layer_list_file");
													print LISTFILE join (",","$layer","$layertype","$layerside","$attrval", "\n");
													close LISTFILE;
												}
								$counter ++;				
								}						
			#-------------------------------------------------------------------------------------------	
		}
	}
}

sub delete_layers_from_prev_run
{
	$F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
my @working_layers = ('out_flex_01','out_flex_02','out_flex_03','out_flex_04','neg_smtop','neg_smbot','neg_top_copper','neg_bot_copper');
	foreach my $work_layer (@working_layers)
		{
		$F->VOF;
			$F->COM("delete_layer,layer=$work_layer");
		$F->VON;
		}
}



sub makedummypcbfile
{
	my $filesize = -s ($pcb_file); 	#Get the file size
    print ("PCB File Size:", $filesize, "\n");  						#Print in the Valor DOS console the value of the file size read
	if ( $filesize eq "0" )												
	 
	{
	
		print ("No Checklist results found, creating a dummy results file!!","\n");
		open(DUMMYFILE, ">>" . $pcb_file);
		print DUMMYFILE ("STD valor_analysis_signal smd_package none 0 mil 0 0 0 0 0 0 R 0", "\n");
		print DUMMYFILE ("\n");
		

	
	}
	else {
		print ("Checklist results were found, using existing results.","\n");
				
		}
	
}

sub merge_pcb_with_other_file
{
	$F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};
	my $file_name = $_[0];
	my $file = ($JOBPATH . "/output/doinfo/" .$file_name);	
	if (-e $file ) 
	{
		my @fileRows = readFile($file);
		open (OUTPUT, ">>$pcb_file") or die $F->PAUSE("die $pcb_file");;
			for (@fileRows) 
			{
				if($_ !~ m/\s\?\s/)	#This field change for Valor 9.5.1 compativility
				{
					print OUTPUT $_;
				}	
			}
		close OUTPUT;
	}
	else 
	{
		print("NOTE: Component Step up results NOT exist! $file \n");
	}	
}

sub readFile
{
   my ($file) = @_;
   open(INFO, $file); 			# Open the file
   my @stdin = <INFO>; 			# Read it into an array
   #chomp(@stdin);
   close(INFO); 				# Close the file
   return (@stdin);
}

sub delete_temp_layers
{
	$F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my @working_layers = ('out_flex_01','out_flex_02','out_flex_03','out_flex_04');
	
	foreach my $work_layer (@working_layers)
		{
		$F->VOF;
			$F->COM("delete_layer,layer=$work_layer");
		$F->VON;
		}
}
sub mergepcbwithholesizefiles
{

	if (-e $hole_size_file ) {
	
	my @fileRows = readFile($hole_size_file);
	
	#$F->PAUSE("rows $fileRows");
	open (OUTPUT, ">>$pcb_file") or die $F->PAUSE("die $pcb_file");;
	for (@fileRows) { # read a line of input from myscript.pl
		#$F->PAUSE("data $_");
		if($_ !~ m/\s\?\s/)   #This field change for Valor 9.5.1 compativility
		{
			 print OUTPUT $_;  # print it to the output handle
		}	
	}
	close OUTPUT;
	}
	else {
		print("NOTE: Hole Size results NOT exist!\n");
		
	}
	
}


sub readValueFromFile
{
	my $file = $_[0];
	my $property = $_[1];
	
	my @feature_list = readFile($file);
	
	foreach my $row (@feature_list){
		chop $row;

		# ignore blanks and lines that start with #
		if (($row ne '') && ($row !~ /^#/)) {
			# get parameters and their values and put into an array
			($parameterName, $parameterValue) = split(/=/, $row);
			if($parameterName eq $property){
				return $parameterValue;
			}
		}
	}
	return 0;
}

sub create_temp_layers
{
	$F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my @working_temp_layers = ('out_flex_01','out_flex_02','out_flex_03','out_flex_04');
	
	$F->DO_INFO("-t matrix -e $JOB/matrix -d NUM_LAYERS");
	my $num = ($F->{doinfo}{gNUM_LAYERS});
	$num =~ s/\'//g;
	$num ++;
	#$F->PAUSE("Number of layers in the JOB : $num");
		foreach my $work_temp_layer (@working_temp_layers)
			{
			$F->COM("matrix_insert_row,job=$JOB,matrix=matrix,row=$num");
			$F->COM("matrix_refresh,job=$JOB,matrix=matrix");
			$F->COM("matrix_add_layer,job=$JOB,matrix=matrix,layer=$work_temp_layer,row=$num,context=misc,type=document,polarity=positive,sub_type=");
			$num ++;
			}
}

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

sub evaluate_product_configuration
{
	$F = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
#################################  TOP SOLDER MASK ###############################				
				my $sm_layer_top_2 = ("smtop");
				#Checking if it exists as the standard Flex name
				$F->DO_INFO ("-t layer -e $JOB/$STEP/$sm_layer_top_2 -d EXISTS");
				if ($F->{doinfo}{gEXISTS} eq "yes")
				{
					$SM_LY_NAME_TOP=$sm_layer_top_2;
					$EXIST_SM_TOP = ("Yes");
				}				
				my $sm_layer_top_1 = ("smtop-increased");
				#Checking if it exists as the standard Flex name
				$F->DO_INFO ("-t layer -e $JOB/$STEP/$sm_layer_top_1 -d EXISTS");
				if ($F->{doinfo}{gEXISTS} eq "yes")
				{
					$SM_LY_NAME_TOP=$sm_layer_top_1;
					$EXIST_SM_TOP = ("Yes");
				}				
				else 
				{
					$F->DO_INFO("-t matrix -e $JOB/matrix");
					foreach my $_row(@{$F->{doinfo}{gROWrow}})
					{
						my $row = ($_row - 1);
						#skip empty rows
						next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
						
						#skip non-Board layers
						next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
						#TOP SIDE LAYERS  		
						if((${$F->{doinfo}{gROWside}}[$row] eq "top")   )
						{
							if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "solder_mask")
							{
								$EXIST_SM_TOP = ("Yes");
								$SM_LY_NAME_TOP = $F->{doinfo}{gROWname}[$row];
							}
						}
					}						
				}				

				if ($EXIST_SM_TOP eq "Yes")
				{
				$F->COM("sr_fill,polarity=positive,step_margin=0,step_max_dist=100,sr_margin=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,dest=layer_name,layer=out_flex_01,attributes=no");
				$F->COM("rename_layer,name=out_flex_01,new_name=neg_smtop");
				$F->COM("sr_fill,polarity=positive,step_margin=0,step_max_dist=100,sr_margin=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,dest=layer_name,layer=out_flex_03,attributes=no");
				$F->COM("rename_layer,name=out_flex_03,new_name=neg_top_copper");				
				$F->COM("affected_layer,name=$SM_LY_NAME_TOP,mode=single,affected=yes");
				$F->COM("sel_reverse");
				$F->COM("sel_copy_other,dest=layer_name,target_layer=neg_smtop,invert=yes,dx=0,dy=0,size=0");
				$F->COM("affected_layer,mode=all,affected=no");
				$F->COM("affected_layer,name=neg_smtop,mode=single,affected=yes");
				$F->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
				$F->COM("affected_layer,mode=all,affected=no");
				#------- enhancement for pictures --------
				$F->COM("affected_layer,name=neg_smtop,mode=single,affected=yes");
				$F->COM("sel_reverse");
				$F->COM("sel_copy_other,dest=layer_name,target_layer=neg_top_copper,invert=yes,dx=0,dy=0,size=0");
				$F->COM("affected_layer,name=neg_smtop,mode=single,affected=no");
				$F->COM("display_layer,name=neg_top_copper,display=yes,number=1");
				$F->COM("work_layer,name=neg_top_copper");
				$F->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
				$F->COM("display_layer,name=neg_top_copper,display=no,number=1");				
				}
	#----------------------------------------------------------------------------------	
		clear_and_reset ();
	#----------------------------------------------------------------------------------					
#################################  BOTTOM SOLDER MASK ###############################				
				my $sm_layer_bot_2 = ("smbot");
				#Checking if it exists as the standard Flex name
				$F->DO_INFO ("-t layer -e $JOB/$STEP/$sm_layer_bot_2 -d EXISTS");
				if ($F->{doinfo}{gEXISTS} eq "yes")
				{
					$SM_LY_NAME_BOT=$sm_layer_bot_2;
					$EXIST_SM_BOT = ("Yes");
				}				
				my $sm_layer_bot_1 = ("smbot-increased");
				#Checking if it exists as the standard Flex name
				$F->DO_INFO ("-t layer -e $JOB/$STEP/$sm_layer_bot_1 -d EXISTS");
				if ($F->{doinfo}{gEXISTS} eq "yes")
				{
					$SM_LY_NAME_BOT=$sm_layer_bot_1;
					$EXIST_SM_BOT = ("Yes");
				}				
				else 
				{
					$F->DO_INFO("-t matrix -e $JOB/matrix");
					foreach my $_row(@{$F->{doinfo}{gROWrow}})
					{
						my $row = ($_row - 1);
						#skip empty rows
						next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
						
						#skip non-Board layers
						next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
						#BOTTOM SIDE LAYERS  		
						if((${$F->{doinfo}{gROWside}}[$row] eq "bottom")   )
						{
							if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "solder_mask")
							{
								$EXIST_SM_BOT = ("Yes");
								$SM_LY_NAME_BOT = $F->{doinfo}{gROWname}[$row];
							}
						}
					}						
				}				

				if ($EXIST_SM_BOT eq "Yes")
				{
				$F->COM("sr_fill,polarity=positive,step_margin=0,step_max_dist=100,sr_margin=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,dest=layer_name,layer=out_flex_02,attributes=no");
				$F->COM("rename_layer,name=out_flex_02,new_name=neg_smbot");
				$F->COM("sr_fill,polarity=positive,step_margin=0,step_max_dist=100,sr_margin=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,dest=layer_name,layer=out_flex_04,attributes=no");
				$F->COM("rename_layer,name=out_flex_04,new_name=neg_bot_copper");				
				$F->COM("affected_layer,name=$SM_LY_NAME_BOT,mode=single,affected=yes");
				$F->COM("sel_reverse");
				$F->COM("sel_copy_other,dest=layer_name,target_layer=neg_smbot,invert=yes,dx=0,dy=0,size=0");
				$F->COM("affected_layer,mode=all,affected=no");
				$F->COM("affected_layer,name=neg_smbot,mode=single,affected=yes");
				$F->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
				$F->COM("affected_layer,mode=all,affected=no");
				#------- enhancement for pictures --------
				$F->COM("affected_layer,name=neg_smbot,mode=single,affected=yes");
				$F->COM("sel_reverse");
				$F->COM("sel_copy_other,dest=layer_name,target_layer=neg_bot_copper,invert=yes,dx=0,dy=0,size=0");
				$F->COM("affected_layer,name=neg_smbot,mode=single,affected=no");
				$F->COM("display_layer,name=neg_bot_copper,display=yes,number=1");
				$F->COM("work_layer,name=neg_bot_copper");
				$F->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
				$F->COM("display_layer,name=neg_bot_copper,display=no,number=1");				
				}				
	#----------------------------------------------------------------------------------	
		clear_and_reset ();
	#----------------------------------------------------------------------------------	
}	

sub gen_strtonum
{
	# Purpose : Function converts a string to a number
	# Input : string
	# Output : number
	my ($strnum) = @_;
	
	$strnum =~ s/\'//g;
	#$strnum =~ s/^0+//g;
	
	return $strnum;
}

sub take_snapshots 
{
######Make sure use inches as units
$F->COM("units,type=inch"); 
clear_and_reset();
#########################################################################
# Get Profile extents -top                                                   #
#########################################################################
$F->DO_INFO("-t step -e $JOB/$STEP -d PROF_LIMITS -u no");
my $gPROF_LIMITSymin = gen_strtonum($F->{doinfo}{gPROF_LIMITSymin});
my $gPROF_LIMITSymax = gen_strtonum($F->{doinfo}{gPROF_LIMITSymax});
my $gPROF_LIMITSxmin = gen_strtonum($F->{doinfo}{gPROF_LIMITSxmin});
my $gPROF_LIMITSxmax = gen_strtonum($F->{doinfo}{gPROF_LIMITSxmax});
#my $win_size_issue =320;
my $win_size =800;
my $win_cord =200;
my $margin = 0.1;
my $x_min = ($gPROF_LIMITSxmin-$margin);
my $x_max = ($gPROF_LIMITSxmax+$margin);
my $y_min = ($gPROF_LIMITSymin-$margin);
my $y_max = ($gPROF_LIMITSymax+$margin);
#########################################################################################

	#################################CONFIGURE COLORS ########################
	$F->VOF;
		$F->COM("affected_layer,name=drill,mode=single,affected=yes");
		$F->COM("sel_reverse");	
		#-----------------------
		$F->COM("display_layer,name=comp_+_top,display=yes,number=3");
		$F->COM("work_layer,name=comp_+_top");
		# Highlights PTH
		$F->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=thmt");
		$F->COM("clear_highlight");
		$F->COM("filter_highlight,layer=,filter_name=popup,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		# Selects Press Fit
		$F->COM("filter_atr_reset");
		$F->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=pressfit");
		$F->COM("filter_area_strt");
		$F->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$F->COM("filter_reset,filter_name=popup");
		$F->COM("zoom_home");
		$F->COM("zoom_refresh");		
		#-----------------------
		$F->COM("display_layer,name=sstop,display=yes,number=13");			
		$F->COM("display_layer,name=neg_smtop,display=yes,number=2");		
		$F->COM("display_layer,name=neg_top_copper,display=yes,number=$SURFACE_FINISH");
	$F->VON;
	#$F->PAUSE ("Pausa1" );
	#################################CREATE WINDOW AND TAKE PICTURE #########
	$F->COM("zoom_pv_open,x1=$x_min,y1=$y_max,x2=$x_max,y2=$y_min,x_win=$win_cord,y_win=$win_cord,w_win=$win_size,h_win=$win_size");
	my $Ventana = $F->{COMANS};
	$F->COM("zoom_pv_print,popview=$Ventana,fname=$JOBPATH/output/snapshots/top.jpg");
	
	$F->PAUSE("take your photo");
	$F->COM("zoom_pv_close,all=no,popview=$Ventana");
	#########################################################################
	clear_and_reset();
	#################################CONFIGURE COLORS ########################
	$F->VOF;
		$F->COM("affected_layer,name=drill,mode=single,affected=yes");
		$F->COM("sel_reverse");	
		#-----------------------
		$F->COM("display_layer,name=comp_+_bot,display=yes,number=3");
		$F->COM("work_layer,name=comp_+_bot");
		# Highlights PTH
		$F->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=thmt");
		$F->COM("clear_highlight");
		$F->COM("filter_highlight,layer=,filter_name=popup,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		# Selects Press Fit
		$F->COM("filter_atr_reset");
		$F->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=pressfit");
		$F->COM("filter_area_strt");
		$F->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$F->COM("filter_reset,filter_name=popup");
		$F->COM("zoom_home");
		$F->COM("zoom_refresh");		
		#-----------------------
		$F->COM("display_layer,name=ssbot,display=yes,number=13");			
		$F->COM("display_layer,name=neg_smbot,display=yes,number=2");		
		$F->COM("display_layer,name=neg_bot_copper,display=yes,number=$SURFACE_FINISH");
	$F->VON;
	#$F->PAUSE ("Pausa2" );
	#################################CREATE WINDOW AND TAKE PICTURE #########
	$F->COM("zoom_pv_open,x1=$x_min,y1=$y_max,x2=$x_max,y2=$y_min,x_win=$win_cord,y_win=$win_cord,w_win=$win_size,h_win=$win_size");
	my $Ventana = $F->{COMANS};
	$F->COM("zoom_pv_print,popview=$Ventana,fname=$JOBPATH/output/snapshots/bottom.jpg");
	#print "$JOBPATH/output/snapshots/bottom.jpg" ;
	$F->PAUSE("take your photo");
	$F->COM("zoom_pv_close,all=no,popview=$Ventana");
	#########################################################################
	clear_and_reset();
	$F->COM("save_job,job=$JOB,override=no");
}

