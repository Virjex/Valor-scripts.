#!perl -w

#####################################################################################
#							NAME:DFM Process GUI									
#####################################################################################
#	PROJECT:	Flex DFM tools Suite compatible with Valor NPI						
#####################################################################################
#	PURPOSE: Provide DFM engineers at Flextronics with a suite of tools that 		
#			 assit them during the DFM job preparation and set up in order			
#			 to speed the DFM cycle time																							
#####################################################################################
#	AUTHOR: WW DFx Support Team, AEG												
#			Armando Alberto Garza Lara & Edgar Alfonso Ruiz Arellano				
#			armando.garza@flextronics.com	+52 (33) 38183200 x3171					
#			edgar.arellano@flextronics.com	+52 (33) 38183200 x6153					
#			Flextronics, Guadalajara												
#			Carretera Base Aerea #5850-4, La Mora									
#			Zapopan, Jalisco, México 45136											
#####################################################################################
#	Revision History: Wed March 16 08:59:09 2016	-Initial release				
#																					 
#	2016, Nov 14 - Include capability to handle multiple steps in the same job 		
#					and also include the validation on the usage for Flextronics	
#					domain and for DFM engineers inside Flextronics					
#	2017, Jun 13 - Include handle irregular Symbols, with rotation 0 or 180			
#
#	2023, Feb 20 - changing this script to support modern wave assmbly
#				wave derection isnt a consern in now todays.
#				main chacks for keep out area was set to 100 mils (2.5mm from the component PTH edge)
#					changing according to Midgal Ha-Emek DFx department findings by -Sam Miles
#					* Orignial files backuped in a folder called back up with the orignal name of the script.
#					* chnages were marked and saved a back up of original code as well
#
#	2023, Jul 17 - added Thermal check support for external script support -Sam Miles
#					* added a requremnt to use the DFM_Util module.
#
#####################################################################################

#####################################################################################
#								DEFINE LIBRARY TO USE								#
#####################################################################################
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
use Sys::Hostname;
use Env qw (VALOR_DATA JOB STEP GENESIS_LIB VALOR_DIR VALOR_EDIR VALOR_VER VALOR_HOME VALOR_TMP);
use File::Basename;
use lib ("$FindBin::Bin/../lib","${VALOR_EDIR}/all/perl",dirname(__FILE__).'\..');
use DFM_Util; # custom made
use Valor;
use vars qw( $SKIP_PTH $GROW_FACTOR $checkbtn_mount $mount_entry $KEEPOUT_FOR_WAVE $MOUNT_CLEARANCE $INCLUDE_MOUNT $INCLUDE_SHIELDS $BANDERA_TOP $BANDERA_BOT $TOP_PROC $BOT_PROC $GUI_PROC_BASE $GUI_PROC_HGHT $GUI_PROC_CHAMF $GUI_PROC_WALLTHK $V $JOB $STEP $TMP_DIR $MW $PROGRESS_FOLDER);
#####################################################################################

#####################################################################################
#									DEFINE VARIABLES								#
#####################################################################################
$JOB			=	$ENV{JOB};
$STEP			=	$ENV{STEP};
$TMP_DIR		=	$ENV{VALOR_TMP};
our $V				=	new Valor;
my $prev_page	= 	('Component_Attr_and_set_up.pl');
my $mode            =   ('interactive');
my $input1	        =   shift;
our %issue;
our @Refdes_List;
if ($input1 ne ''){$mode = $input1;}
#####################################################################################
#								START FROM VALID JOB								#
#####################################################################################
if ($JOB eq "" || $STEP eq "")
	{
	$V->PAUSE("Script must start in Graphic Editor Screen!");
	exit 0;
	}
#####################################################################################
#								DEFINE PROGRESS FOLDER								#
#####################################################################################
#validation();
progress_folder_read();
#####################################################################################
#							DEFINE ADDITIONAL VARIABLES								#
#####################################################################################
#----- Variables to be used for the aperture in the pallet -----
	$TOP_PROC      = "SMT";
	$BOT_PROC      = "SMT";
	$GUI_PROC_BASE = 80;
	$GUI_PROC_HGHT = 200;
	$GUI_PROC_CHAMF = 30;
	$GUI_PROC_WALLTHK = 1;
	$GROW_FACTOR = 20;
#----- Variables to evaluate product configuration -----
	$EXIST_PTH_ON_TOP;
	$EXIST_PTH_ON_BOT;
	$EXIST_PTH_DRILL;
	$INCLUDE_SHIELDS = 0;
#----- Variables to evaluate Flow Direction -----	
	$BANDERA_BOT = 0;
	$BANDERA_TOP = 0;
#----- Variables used for keepout -----
	$INCLUDE_MOUNT = 0;
	$MOUNT_CLEARANCE = 200;
	$mount_entry;
	$KEEPOUT_FOR_WAVE = 1;
#----- Variables used for non-populated PTH components -----	
	$SKIP_PTH = 0;
#----- Variables used for Legacy support -----	
	$GUI_PROC_RADIUS = 100;
	$LEGACY_MODE = 0;
	$legacy_entry;
	$legacy_entry_width;
	$legacy_entry_length;
	$legacy_entry_chamfer;
	$legacy_entry_thickness;
	$checkbtn_01b; 			#'Consider wave solder areas as component keepout zone'		#Sam: ?
	$checkbtn_01c;			#'Include Shields Areas for Process Map'					#Sam: ?
#####################################################################################

#####################################################################################
#								SCRIPT START HERE									#
#####################################################################################
#$V->PAUSE ("Hola Mundo!!!"); 		
###########################################################################
#Change units to Inches
###########################################################################
	$V->COM("units,type=inch");
#####################################################################################
#
#	testing area
#



#####################################################################################
# 						Welcome informative Pause									#
#####################################################################################
	if ($mode eq "interactive")
	{
welcome_message(
"
This script will bring a user interface to define the dimensions to be 
used for the wave solder pallet simulation, the default values presented
in the interface are the standar recommended values, but DFM engineer
can use different values if the board will be process with special equipment.","procmap.gif"
);
	}
#####################################################################################
# 				Clear and Reset Filters or selections								#
#####################################################################################
clear_and_reset ();
#####################################################################################
# 	Set in Job Attributes the DRC layers to be used for Flex Analysis Process		#
#####################################################################################
set_drc_layers ();
#####################################################################################
# 				Delete Layers from previous Run										#
#####################################################################################
delete_layers_from_prev_run ();
#####################################################################################
# 				Evaluate product configuration										#
#####################################################################################

#Cheaks for components on diffrent sides of the PCB
evaluate_product_configuration (); 

#$V->PAUSE("Variables  TOP : $EXIST_PTH_ON_TOP  Bottom : $EXIST_PTH_ON_BOT   Drill : $EXIST_PTH_DRILL ");

#########################################################################################
#  Launch the GUI to ask for the aperture values										#
#########################################################################################

procmap_gui();
process_gui();


if ($LEGACY_MODE){
#------Build Cases -----
if (($EXIST_PTH_DRILL eq "Yes") && ($EXIST_PTH_ON_TOP eq "Yes") &&($EXIST_PTH_ON_BOT eq "Yes"))
{
#$V->PAUSE("Case 1 PTH drills - PTH TOP - PTH BOT");
discover_flow_direction();
	if ($mode ne "designers") 
	{
		#procmap_gui();
		#process_gui();
	}	
create_temp_layers ();
if ($INCLUDE_SHIELDS != 0) {create_shiled_areas ("top");create_shiled_areas ("bottom");}
if ($INCLUDE_MOUNT != 0) {create_mount_areas ();}
get_pth_toeprints ("top");
convert_appertures("top");
get_pth_toeprints ("bottom");
convert_appertures("bottom");
fill_procmap("top");
fill_procmap("bottom");
fill_keepout ();
}
if (($EXIST_PTH_DRILL eq "Yes") && ($EXIST_PTH_ON_TOP eq "Yes") &&($EXIST_PTH_ON_BOT eq "No"))
{
#$V->PAUSE("Case 2 PTH drills - PTH TOP");
discover_flow_direction();
	if ($mode ne "designers") 
	{
		#procmap_gui();
		#process_gui();
	}	
create_temp_layers ();
if ($INCLUDE_SHIELDS != 0) {create_shiled_areas ("top");create_shiled_areas ("bottom");}
if ($INCLUDE_MOUNT != 0) {create_mount_areas ();}
get_pth_toeprints ("top");
convert_appertures("top");
fill_procmap("top");
fill_procmap("bottom");
fill_keepout ();
}
if (($EXIST_PTH_DRILL eq "Yes") && ($EXIST_PTH_ON_TOP eq "No") && ($EXIST_PTH_ON_BOT eq "Yes"))
{
#$V->PAUSE("Case 3 PTH drills - PTH BOT");
discover_flow_direction();
	if ($mode ne "designers") 
	{
		#procmap_gui();
		#process_gui();
	}	
create_temp_layers ();
if ($INCLUDE_SHIELDS != 0) {create_shiled_areas ("top");create_shiled_areas ("bottom");}
if ($INCLUDE_MOUNT != 0) {create_mount_areas ();}
get_pth_toeprints ("bottom");
convert_appertures("bottom");
fill_procmap("top");
fill_procmap("bottom");
fill_keepout ();
}
if (($EXIST_PTH_DRILL eq "Yes") && ($EXIST_PTH_ON_TOP eq "No") && ($EXIST_PTH_ON_BOT eq "No"))
{
#$V->PAUSE("Case 4 PTH drills only");
	if ($mode ne "designers") 
	{
		#procmap_gui_slim ();
	}
create_temp_layers ();
if ($INCLUDE_SHIELDS != 0) {create_shiled_areas ("top");create_shiled_areas ("bottom");}
if ($INCLUDE_MOUNT != 0) {create_mount_areas ();}
fill_procmap("top");
fill_procmap("bottom");
}
if ($EXIST_PTH_DRILL eq "No")
{
#$V->PAUSE("Case 5 NO PTH drills - NO PTH TOP - NO PTH BOT");
	if ($mode ne "designers") 
	{
		#procmap_gui_slim ();
	}
create_temp_layers ();
if ($INCLUDE_SHIELDS != 0) {create_shiled_areas ("top");create_shiled_areas ("bottom");}
if ($INCLUDE_MOUNT != 0) {create_mount_areas ();}
fill_procmap("top");
fill_procmap("bottom");
}
} else {

#########################################################################################
#			End of legacy code and switching to 2nd verstion
#
#	procmap_gui_slim (); was deleted due to it being obsulite. is called for the same verion of the normal GUI just with two options
#	1. include keep out area for mouting holes. Valor checks for a distace between a mouting hole and components
#	2. include shields (off by defult). 
#	
#	moved the GUI calling to before the switch.
#	reason: same methods just a bit diffrent handeling
#	
#	generating a wave mask for a PCB wihtout a PTH components is just useless
#
#########################################################################################

create_temp_layers();
new_wave_mask();	#see this method for the the updated method

exit (0);
}

delete_temp_layers ();
#####################################################################################
# 		Create DRC layers Flex Analysis Process	in case they do not exist			#
#####################################################################################
create_drc_layers_if_not_exist ();
	$V->COM("save_job,job=$JOB,override=no");
#########################################################################################
#  Other subrutines																		#
#########################################################################################
#write_in_log ("Process Map Creation");		#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
#create_flag_file ("Process Map Creation");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
#####################################################################################
# 						Welcome informative Pause									#
#####################################################################################

if ($mode ne "designers"){
welcome_message(
"
Please complement manually if necessary the layers used for Restrictions 
features kepout areas and features kepin areas \"drc_xxx_xxx\".
Remember for component height restriction use the layer \"drc_comp_height\"
where you can create areas for height restrictions if customer provide
mechanical data that allow you to create them.","height_restrictions.gif"
);
sleep (1);
welcome_message(
"
Please complement manually if necessary the layers used for Restrictions 
features kepout areas and features kepin areas \"drc_xxx_xxx\". 
Remember for component keep out areas use the layer \"keepout_layer\" where you
can create the areas where should not be place any component like
chassis contact areas or sliding zones.","comp_keepout.gif"
);
sleep (1);
						}
	if ($mode eq "interactive")
	{
	success_run("Script finish successfully!!");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE   - Sam: i got no idea who wrote it or why!?
	back_to_menu ("$prev_page");
	exit (0);
	}
	if (($mode eq "silence") or ($mode eq "designers"))
	{
			my $path = ($VALOR_DIR . "/sys/scripts/FlexScripts/Compt_Attr_set_up/thieving_pad.pl");
			run_next_script ("$mode","$path");
			exit (0);
	}
exit (0);

sub new_wave_mask{

#	first a few things!
#	$F was chnaged to $V to the Valor module refference. V for Valor. just makes more sence to me
#	The method valor. is a custom method.. see it at the bottom of the script
#	it does the same as "$V-COM();" just with a multi line support.
#	just to keep this more neat and help to read the code better.
#	The method pop_up is the same as "$V->PAUSE();" just in a simple way to look at.
#	yes the PAUSE is pausing the script. but it's main useage is to delever some info to the use by a pop-up
#	the rest you can read up with in this file.

my $comps_top 		= 	'flex_temp_01';
my $comps_bot 		= 	'flex_temp_02';
my $drill 			= 	'flex_temp_03';
my $pads_top		= 	'flex_temp_04';
my $pads_bot		= 	'flex_temp_05';
my $keepout_layer	= 	'flex_temp_06';
my $thermal			= 	'flex_temp_09';
my $refz;
my $refz_list;
my $tFlag;
my $bFlag;


#First select all needed components from TOP side
$tFlag = draw_components_pins("top",$comps_top);
$bFlag = draw_components_pins("bot",$comps_bot);

if (!$tFlag and !$bFlag) { 
	$V->VOF();
	delete_temp_layers();
	pop_up ("No components we selected <br>
			exising script"); 
	$V->VON();
	exit(0);
}

valor(	"display_layer,name=drill,number=9,display=yes"
		,"filter_reset"
		,"work_layer,name=drill"
		,"filter_atr_set,filter_name=popup,attribute=.drill,entity=feature,condition=yes,option=plated"
		,"filter_area_strt"
		,"filter_area_end,layer=,filter_name=popup,operation=select"
		,"sel_copy_other,dest=layer_name,target_layer=$drill"
		,"display_layer,name=drill,number=9,display=no"
		);


if ($tFlag) {
	get_pads($comps_top,"top",$pads_top);
	remove_unwantted_pad($comps_top,$pads_top,"Top");
} 
if ($bFlag) {
	get_pads($comps_bot,"bottom",$pads_bot);
	remove_unwantted_pad($comps_bot,$pads_bot,"Bot");
}

#resizing the pads and copping it to the keepout_layer
$size = $GUI_PROC_RADIUS * 2;
valor(	"display_layer,name=$pads_top,display=yes,number=4"
		,"work_layer,name=$pads_top"
		,"sel_resize,size=$size"
		,"display_layer,name=comp_+_top,display=yes,number=1"
		,"sel_reverse");
		
		if(get_count()){
			pop_up("Edit openings used for the top somponents");
		}
		valor("display_layer,name=$pads_top,display=yes,number=1",
			"work_layer,name=$pads_top",
			"sel_all_feat",
			"sel_copy_other,dest=layer_name,target_layer=$thermal,invert=no,dx=0,dy=0,size=0"
			);
		
		clear_and_reset();
		$V->VOF();
		valor(
		"sel_clear_feat"
		,"display_layer,name=$pads_top,display=yes,number=1"
		,"work_layer,name=$pads_top"
		,"sel_reverse"
		,"sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y"
		
		,"sel_copy_other,dest=layer_name,target_layer=$keepout_layer,invert=no,dx=0,dy=0,size=0"
		,"display_layer,name=$keepout_layer,display=yes,number=9"
		,"work_layer,name=$keepout_layer"
		,"cur_atr_reset"
		,"cur_atr_set,attribute=.drc_assembly_lyrs,option=bottom"
		,"cur_atr_set,attribute=.drc_comp_keepout"
		,"sel_change_atr,mode=add,pkg_attr=no"
		,"cur_atr_reset"
		,"display_layer,name=$keepout_layer,display=no,number=9"
		,"display_layer,name=$pads_bot,display=yes,number=4"
		,"work_layer,name=$pads_bot"
		,"sel_resize,size=$size"
		,"display_layer,name=comp_+_bot,display=yes,number=1"
		,"sel_reverse");
		
		if(get_count()){
			pop_up("Edit openings used for the bottom somponents");
		}
		
		valor("display_layer,name=$pads_bot,display=yes,number=1",
			"work_layer,name=$pads_bot",
			"sel_all_feat",
			"sel_copy_other,dest=layer_name,target_layer=$thermal,invert=no,dx=0,dy=0,size=0",
			"display_layer,name=$thermal,display=yes,number=1",
			"work_layer,name=$thermal",
			"sel_resize,size=" . (($size * -1) +10)
			);
		clear_and_reset();
		valor(
		"display_layer,name=$pads_bot,display=yes,number=1"
		,"work_layer,name=$pads_bot"
		,"sel_reverse"
		,"sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y"
		
		,"sel_copy_other,dest=layer_name,target_layer=flex_temp_07,invert=no,dx=0,dy=0,size=0"
		,"display_layer,name=flex_temp_07,display=yes,number=9"
		,"work_layer,name=flex_temp_07"
		
		,"cur_atr_reset"
		,"cur_atr_set,attribute=.drc_assembly_lyrs,option=top"
		,"cur_atr_set,attribute=.drc_comp_keepout"
		,"sel_change_atr,mode=add,pkg_attr=no"
		,"cur_atr_reset"
		
		,"cur_atr_set,attribute=.drc_assembly_lyrs,option=top"
		,"sel_change_atr,mode=add,pkg_attr=no"
		,"sel_copy_other,dest=layer_name,target_layer=$keepout_layer,invert=no,dx=0,dy=0,size=0"
		,"display_layer,name=flex_temp_07,display=no,number=9"
		,"display_layer,name=$keepout_layer,number=1"
		,"cur_atr_reset");
		clear_and_reset();
		$V->VON();
#end of keepout layer

#getting the ref that in side of the keep out area.

get_ref("top", $pads_bot) if ($bFlag);
get_ref("bot", $pads_top) if ($tFlag);

fill_area($pads_top) if ($tFlag); 
fill_area($pads_bot) if ($bFlag);


#renaming the layers
	valor("matrix_rename_layer,job=$JOB,matrix=matrix,layer=$keepout_layer,new_name=keepout_layer"
	,"matrix_rename_layer,job=$JOB,matrix=matrix,layer=$pads_bot,new_name=procmap_top"
	,"matrix_rename_layer,job=$JOB,matrix=matrix,layer=$pads_top,new_name=procmap_bot"
	,"matrix_rename_layer,job=$JOB,matrix=matrix,layer=$thermal,new_name=thermal"
	,"matrix_page_close,job=$JOB,matrix=matrix"
	,"delete_layer,layer=flex_temp_01"
	,"delete_layer,layer=flex_temp_02"
	,"delete_layer,layer=flex_temp_03"
	,"delete_layer,layer=flex_temp_07"
	,"delete_layer,layer=flex_temp_08"
	,"delete_layer,layer=flex_temp_10"
	,"delete_layer,layer=flex_temp_11"
	,"delete_layer,layer=flex_temp_12"
	);
	clear_and_reset();

show_results();

}

sub get_results_data{
	my @lines = @{$_[0]};
	valor("affected_layer,name=comp_+_top,mode=single,affected=yes" , "affected_layer,name=comp_+_bot,mode=single,affected=yes");
	foreach my $usedref (sort keys %issue) {

		$V->COM("filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$usedref");
		$V->COM("filter_area_strt");  
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select");  
		$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p centroidx -o select");
		my $x = ($V->{doinfo}{gCOMPcentroidx});
		if(!${$x}[0]){
			${$x}[0] = "$usedref was not found";
		} else {
			${$x}[0]*=1000;
		}
		$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p centroidy -o select");
		my $y = ($V->{doinfo}{gCOMPcentroidy});
			if(!${$y}[0]){
			${$y}[0] = "$usedref was not found";
		} else {
			${$y}[0]*=1000;
		}
		$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p SIDE -o select");
		my $side = ($V->{doinfo}{gCOMPside});
		${$side}[0] = "$usedref was not found" if(!${$side}[0]);
		valor("sel_clear_feat");
		
		
		$issue{$usedref} = {
			x => ${$x}[0],
			y => ${$y}[0],
			side => ${$side}[0],
		};
	
	}
	valor("affected_layer,name=comp_+_top,mode=single,affected=no" , "affected_layer,name=comp_+_bot,mode=single,affected=no");
	
	
}

sub show_results{
	
	if(!(@Refdes_List)){
		pop_up ("No issues were found");
		exit 0;
	}
	
	get_results_data(\@Refdes_List);
	
	my $filename = 'C:\MentorGraphics\Valor\vNPI_TMP\Wave_reseults.txt';

	# saving the issues to a txt file and showing it
	open(my $fh, '>',$filename) or die "Clound not open file.";
	
	foreach my $i (sort keys %issue) {
		print $fh $issue{$i}{side} . "\t" . $i . "\t" . $issue{$i}{x} . "\t" .$issue{$i}{y} . "\n";
	}
	
	close($fh);

	system(1,"notepad.exe $filename");
}

sub get_ref(){
	
	# the point is to get the refdes of the components that located on the other side of the pads.
	# so if the pads coming from the top we need the compoents with the pads  on the BOTTOM side
	
	my $side = shift;
	my $openings = shift;
	my $refz;
	clear_and_reset();
	valor( 
		"display_layer,name=comp_+_". ( $side eq "top" ? "top" : "bot" ) .",display=yes,number=1",
		"work_layer,name=comp_+_". ( $side eq "top" ? "top" : "bot" ),
		"sel_ref_feat,layers=$openings,use=filter,mode=touch,f_types=pad\;surface,polarity=positive\;negative"
		);
		
		
	$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p refdes -o select");
	$refz = $V->{doinfo}{gCOMPrefdes};
	
	if(${$refz}[0]){
		for(my $i = 0; $i < scalar @$refz -1; $i++){
			push(@Refdes_List, ${$refz}[$i]);
			$issue{${$refz}[$i]} = undef;
		}
	}
	clear_and_reset();
	
	
	# this will need to be chnage for to check the leads att's??
	valor( 
		"affected_layer,name=sm$side,mode=single,affected=yes",
		"sel_ref_feat,layers=$openings,use=filter,mode=touch,f_types=pad\;surface,polarity=positive\;negative",
		"display_layer,name=comp_+_". ( $side eq "top" ? "top" : "bot" ) .",display=yes,number=1",
		"work_layer,name=comp_+_". ( $side eq "top" ? "top" : "bot" ));
	if(get_count()){
		valor("sel_ref_feat,layers=,use=select,mode=touch,f_types=pad\;surface");
		$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p refdes -o select");
		$refz = $V->{doinfo}{gCOMPrefdes};
		
		if(${$refz}[0]){
			for(my $i = 0; $i < scalar @$refz -1; $i++){
				push(@Refdes_List, ${$refz}[$i]);
				$issue{${$refz}[$i]} = undef;
			}
		}
	}
			
}

sub fill_area{
	my $layer = shift;
	clear_and_reset();
	valor ("display_layer,name=$layer,display=yes,number=1"
	
				,"sel_reverse"
				,"cur_atr_set,attribute=.area_name,text=SELWAV"
				,"sel_change_atr,mode=add,pkg_attr=no"
				,"sel_delete_atr,attributes=.pattern_fill;,pkg_attr=no"
				,"cur_atr_reset"
	,"work_layer,name=$layer"
	,"sr_fill,polarity=positive,step_margin=0,step_max_dist=100,sr_margin=0,nest_sr=yes,consider_feat=yes,feat_margin=0,consider_drill=no,drill_margin=0,dest=affected_layers,layer=$layer,attributes=no"
		,"filter_atr_set,filter_name=popup,attribute=.pattern_fill,entity=feature,condition=yes"
		,"filter_area_strt"
		,"filter_area_end,layer=,filter_name=popup,operation=select"
		,"cur_atr_set,attribute=.area_name,text=SMT"
		,"sel_change_atr,mode=add,pkg_attr=no"
		,"cur_atr_reset"
	#	,"filter_area_strt"
	#	,"filter_area_end,layer=,filter_name=popup,operation=select"
		);
		

}


sub remove_unwantted_pad{
	
	my $comp_layer 	= shift;
	my $pad_layer	= shift;
	my $side 		= shift;	
		
	valor ("filter_reset"
		,"display_layer,name=$pad_layer,display=yes,number=4"
		,"display_layer,name=comp_+_$side,display=yes,number=1"
		,"work_layer,name=$pad_layer"
		,"sel_ref_feat,layers=flex_temp_03,use=filter,mode=touch,f_types=pad\;surface\;line,polarity=positive\;negative"
		,"sel_reverse");
		if(get_count()){
			valor("sel_delete");
		}
		valor("sel_ref_feat,layers=$comp_layer,use=filter,mode=touch,f_types=pad\;surface,polarity=positive\;negative"		
		);
	if(get_count()){
		valor ("sel_reverse");
		if(get_count()){
			valor("sel_delete");
		}
	} else {
		valor ("sel_reverse");
		if(get_count()){
			valor("sel_delete");
		}
	}
	valor("display_layer,name=$pad_layer,display=no,number=4");
}

sub get_pads{
	
	my $leads 			= shift;
	my $side			= shift;
	my $pad_layer		= shift;
	
	#going by the leads of the components that were selected!
	valor	("display_layer,name=$side,display=yes,number=1"
			,"filter_reset"
			,"filter_atr_set,filter_name=popup,attribute=.pad_usage,entity=feature,condition=yes,option=toeprint"
			,"sel_ref_feat,layers=$leads,use=filter,mode=touch,f_types=line\;pad\;surface,polarity=positive\;negative"
			,"sel_copy_other,dest=layer_name,target_layer=$pad_layer,invert=no"
			,"display_layer,name=$pad_layer,display=yes,number=1"
			,"filter_reset"
			,"filter_atr_set,filter_name=popup,attribute=.smd,entity=feature,condition=yes"
			,"filter_area_strt"
			,"filter_area_end,layer=,filter_name=popup,operation=select"
			);
	if (get_count() != 0){
		valor("sel_delete");
	}	
}


sub get_count{
	$V->COM("get_select_count"); 
	return $V->{COMANS};
}

sub draw_components_pins{
	my $side 			= shift;
	my $layer 			= shift;

	$V->VOF();
	valor("filter_reset","sel_clear_feat"
	,"display_layer,name=comp_+_$side,display=yes,number=1" 
	,"filter_atr_set,filter_name=popup,attribute=_comp_type_component,entity=component,condition=yes,option=pth-component"
	,"filter_comp_set,filter_name=popup,update_popup=no,cpn_names=\*"
	,"filter_area_strt"
	,"filter_area_end,layer=,filter_name=popup,operation=select");
	
	$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p refdes -o select");	
	$refz = $V->{doinfo}{gCOMPrefdes};
	$refs_list = return_list($refz);
	
	pop_up("Check if all components were selected for $side side <br>
			Current select is: <b> ${\get_count()} </b> <br>
			Refdes: <br>
			<b>$refs_list </b>");
	if ( get_count() != 0){

		$V->COM("filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$refs_list");
		if ($side eq "top") {
			valor("comp_draw_to_layer,layer_mode=library,side=top,layer_name_top=flex_temp_01,comp_mode=outline,draw_pins=yes,draw_pins_mode=surface,draw_centroids=no,name=no,draw_board_outline=no,fit2box=no,component_outline_mode=Body,draw_font=24,draw_selected=yes",
			"comp_draw_to_layer,
		
		layer_mode=library,
		side=" . ($side eq "top" ? "top" : "bottom") .",
		". ($side eq "top" ? "layer_name_top=comp_pins_top" : "layer_name_bot=comp_pins_bot") .",
		draw_pins=yes,
		draw_pins_mode=surface,
		draw_centroids=no,
		name=no,
		draw_board_outline=no,
		fit2box=no,
		draw_font=24,
		draw_selected=yes,
		use_placed_comp_only=yes");
		} else {
			valor("comp_draw_to_layer,layer_mode=library,side=bottom,layer_name_bot=flex_temp_02,comp_mode=outline,draw_pins=yes,draw_pins_mode=surface,draw_centroids=no,name=no,draw_board_outline=no,component_outline_mode=Body,draw_font=24,draw_selected=yes",
		
		"comp_draw_to_layer,
		layer_mode=library,
		side=" . ($side eq "top" ? "top" : "bottom") .",
		". ($side eq "top" ? "layer_name_top=comp_pins_top" : "layer_name_bot=comp_pins_bot") .",
		draw_pins=yes,
		draw_pins_mode=surface,
		draw_centroids=no,
		name=no,
		draw_board_outline=no,
		fit2box=no,
		draw_font=24,
		draw_selected=yes,
		use_placed_comp_only=yes",);
		
			}
		valor("filter_reset"
		,"display_layer,name=comp_+_$side,display=yes,number=1"
		,"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$refs_list");
		if ($side eq "top") {
			valor("comp_draw_to_layer,layer_mode=library,side=top,layer_name_top=flex_temp_12,comp_mode=outline,component_outline_mode=Body,draw_font=24,draw_selected=yes"
			,
			"comp_draw_to_layer,
		layer_mode=library,
		side=" . ($side eq "top" ? "top" : "bottom") . ",
		". ($side eq "top" ? "layer_name_top=comp_body_top" : "layer_name_bot=comp_body_bot") .",
		comp_mode=surface,
		draw_pins=no,
		draw_pins_mode=surface,
		draw_centroids=no,
		name=no,
		draw_board_outline=no,
		fit2box=no,
		component_outline_mode=Body,
		draw_font=24,
		draw_selected=yes"
			
			
			,"display_layer,name=flex_temp_01,display=yes,number=1"
			,"sel_ref_feat,layers=flex_temp_12,use=filter,mode=cover,f_types=line;arc,polarity=positive\;negative"
			,"sel_delete");
			
		} else {
			valor("comp_draw_to_layer,layer_mode=library,side=bottom,layer_name_bot=flex_temp_12,comp_mode=outline,component_outline_mode=Body,draw_font=24,draw_selected=yes",
			"comp_draw_to_layer,
		layer_mode=library,
		side=" . ($side eq "top" ? "top" : "bottom") . ",
		". ($side eq "top" ? "layer_name_top=comp_body_top" : "layer_name_bot=comp_body_bot") .",
		comp_mode=surface,
		draw_pins=no,
		draw_pins_mode=surface,
		draw_centroids=no,
		name=no,
		draw_board_outline=no,
		fit2box=no,
		component_outline_mode=Body,
		draw_font=24,
		draw_selected=yes"
			
			,"display_layer,name=flex_temp_02,display=yes,number=1"
			,"sel_ref_feat,layers=flex_temp_12,use=filter,mode=cover,f_types=line;arc,polarity=positive\;negative"
			,"sel_delete");	
			}
		
		}
	
		DFM_Util::valor(
			"display_layer,name=". ($side eq "top" ? "comp_pins_top" : "comp_pins_bot") .",display=yes,number=1",
			"work_layer,name=". ($side eq "top" ? "comp_pins_top" : "comp_pins_bot"),
			"filter_reset",
			
			"filter_set,filter_name=popup,update_popup=yes,feat_types=line\;arc",
			"filter_area_strt",			"filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0",
			"sel_delete",
			"filter_reset",
		);
		
		if ($side ne "top"){
		DFM_Util::valor(
			"display_layer,name=comp_pins_bot,display=yes,number=1",
			"work_layer,name=comp_pins_bot",
			"sel_all_feat",
			"sel_move_other,target_layer=comp_pins_top,invert=no,dx=0,dy=0,size=0",
			"delete_layer,layer=comp_pins_bot",
			
			"display_layer,name=comp_body_bot,display=yes,number=1",
			"work_layer,name=comp_body_bot",
			"sel_all_feat",
			"sel_move_other,target_layer=comp_body_top,invert=no,dx=0,dy=0,size=0",
			"delete_layer,layer=comp_body_bot",
			
			"rename_layer,name=comp_body_top,new_name=comp_body",
			"rename_layer,name=comp_pins_top,new_name=comp_pins"
			
			);
		}
	
	$V->VON();
	valor("display_layer,name=$layer,display=yes,number=1","sel_reverse");
	return get_count() > 0 ? 1 : 0;
}

sub return_list{
	my ($ref_arry) = @_;
	return join(";",@$ref_arry);
}



#####################################################################################
#				SUB-RUTINE TO AUTOMATICALLY RUN THE NEXT SCRIPT 					#
#####################################################################################
#####################################################################################
#				SUB-RUTINE TO AUTOMATICALLY RUN THE NEXT SCRIPT 					#
#####################################################################################
sub run_next_script
{
my $a      = $_[0];
my $script = $_[1];
alarm 0;
system("perl $script $a") or print("NOTE: Script $script does not exist.","\n");
}
#####################################################################################
#				SUB-RUTINE to Fill Process Map Layers								#
#####################################################################################
sub fill_procmap
{
#--------------Set Variables ---------------
	my $JOB	= $ENV{JOB};
	my $STEP= $ENV{STEP};
	my $V	= new Valor;
	my $worklayer1;
	my $worklayer2;
	my $sorcelayer1;
	my $sorcelayer2;
	my $sorcelayer3;
	my $prc_map_layer;
	my $attr_used;
	my $side = $_[0];
	my $oposit_attr_used;
	my $flag_used	= 0;
	if ($side eq "top")
	{
		$worklayer1			= ('flex_temp_07');
		$worklayer2			= ('flex_temp_08');
		$sorcelayer1		= ('flex_temp_09');
		$sorcelayer2		= ('flex_temp_03');	
		$sorcelayer3		= ('flex_temp_05');	
		$prc_map_layer		= ('procmap_top');
		$oposite_map_layer	= ('procmap_bot');
		$attr_used			= $TOP_PROC;

		
	}	
	if ($side eq "bottom")
	{
		$worklayer1			= ('flex_temp_08');
		$worklayer2			= ('flex_temp_07');
		$sorcelayer1		= ('flex_temp_10');
		$sorcelayer2		= ('flex_temp_05');
		$sorcelayer3		= ('flex_temp_03');	
		$prc_map_layer		= ('procmap_bot');
		$oposite_map_layer	= ('procmap_top');
		$attr_used			= $BOT_PROC;
	
	}
#--------------------------------------------

			$V->COM("sr_fill,polarity=positive,step_margin=0,step_max_dist=100,sr_margin=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,dest=layer_name,layer=$worklayer1,attributes=no");
			$V->COM("affected_layer,name=$worklayer1,mode=single,affected=yes");
			$V->COM("sel_reverse");
			$V->COM("sel_copy_other,dest=layer_name,target_layer=$worklayer2,invert=no,dx=0,dy=0,size=0");
			$V->COM("affected_layer,mode=all,affected=no");
#If exist shields -------------	
			if ($INCLUDE_SHIELDS != 0) 
					{
						$V->COM("affected_layer,name=$sorcelayer1,mode=single,affected=yes");
						$V->COM("sel_reverse");
						$V->COM("sel_copy_other,dest=layer_name,target_layer=$worklayer1,invert=yes,dx=0,dy=0,size=0");
						$V->COM("affected_layer,mode=all,affected=no");
						$V->COM("affected_layer,name=$worklayer1,mode=single,affected=yes");
						$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
						$V->COM("affected_layer,mode=all,affected=no");

					}
#-----------------------------
						$V->COM("affected_layer,name=$sorcelayer3,mode=single,affected=yes");
						$V->COM("sel_reverse");
						$V->COM("sel_copy_other,dest=layer_name,target_layer=$worklayer1,invert=yes,dx=0,dy=0,size=0");
						$V->COM("affected_layer,mode=all,affected=no");
						$V->COM("affected_layer,name=$worklayer1,mode=single,affected=yes");
						$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
						$V->COM("affected_layer,mode=all,affected=no");


#-----------------------------			
			$V->COM("affected_layer,name=$worklayer1,mode=single,affected=yes");
			$V->COM("cur_atr_set,attribute=.area_name,text=$attr_used");
			$V->COM("sel_change_atr,mode=add,pkg_attr=no");
			$V->COM("cur_atr_reset");
			$V->COM("affected_layer,mode=all,affected=no");
#If exist shields -------------	
			if ($INCLUDE_SHIELDS != 0) 
					{			
						$V->COM("affected_layer,name=$sorcelayer1,mode=single,affected=yes");
						$V->COM("sel_move_other,target_layer=$worklayer1,invert=no,dx=0,dy=0,size=0");
						$V->COM("affected_layer,mode=all,affected=no");
					}
#-----------------------------	
						$V->COM("affected_layer,name=$sorcelayer3,mode=single,affected=yes");
						$V->COM("sel_move_other,target_layer=$worklayer1,invert=no,dx=0,dy=0,size=0");
						$V->COM("affected_layer,mode=all,affected=no");
#-----------------------------		
			$V->COM("affected_layer,name=$worklayer1,mode=single,affected=yes");
			$V->COM("sel_move_other,target_layer=$prc_map_layer,invert=no,dx=0,dy=0,size=0");
			$V->COM("affected_layer,mode=all,affected=no");			
			clear_and_reset();	
#----------------------------------------------------------------------------------------------------------------------
			
}

#####################################################################################
#				SUB-RUTINE to Fill Process Map Layers								#
#####################################################################################
sub fill_keepout
{
#--------------Set Variables ---------------
	my $JOB	= $ENV{JOB};
	my $STEP= $ENV{STEP};
	my $V	= new Valor;
	my $kp_layer		= ('keepout_layer');
	my $souce_01		= ('flex_temp_12');
	my $souce_02		= ('flex_temp_02');	
	my $souce_03		= ('flex_temp_04');
	my $souce_04		= ('flex_temp_11');
#--------------------------------------------
			clear_and_reset();
			$V->COM("affected_layer,name=$souce_01,mode=single,affected=yes");
			$V->COM("affected_layer,name=$souce_02,mode=single,affected=yes");
			$V->COM("affected_layer,name=$souce_03,mode=single,affected=yes");
			$V->COM("affected_layer,name=$souce_04,mode=single,affected=yes");
			$V->COM("sel_move_other,target_layer=$kp_layer,invert=no,dx=0,dy=0,size=0");
			$V->COM("affected_layer,mode=all,affected=no");
}

#####################################################################################
#		SUB-RUTINE to Create Surrounding Mountin hole Keppout Areas					#
#####################################################################################
sub create_mount_areas
{
#--------------Set Variables ---------------
	my $JOB	= $ENV{JOB};
	my $STEP= $ENV{STEP};
	my $V	= new Valor;
	my $worklayer = ('flex_temp_12');
	my $tmplayer  = ('flex_temp_11');
	my $kparea = ($MOUNT_CLEARANCE * 2);
#--------------------------------------------
			clear_and_reset();
			$V->COM("affected_layer,name=drill,mode=single,affected=yes");
			$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.mount_hole");
			$V->COM("filter_area_strt");
			$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
			$V->COM("filter_reset,filter_name=popup");
			$V->COM("get_select_count");    					#Command to get number of selected features and is storage on $COMANS variable
			my $selection_01 = $V->{COMANS};
			#$V->PAUSE("Tooling holes detected : $selection_01 ");
			if ( $selection_01 != 0)
			{
				$V->COM("display_layer,name=drill,display=yes,number=1");   
				$V->COM("work_layer,name=drill");
				$V->COM("affected_layer,mode=all,affected=no");
				$V->COM("affected_filter,filter=\(context=board\&type=signal\|power_ground\|mixed\&side=top\|bottom\)");
				$V->COM("filter_set,filter_name=popup,update_popup=no,feat_types=pad");
				$V->COM("filter_set,filter_name=popup,update_popup=no,polarity=positive");
				$V->COM("sel_ref_feat,layers=,use=select,mode=touch,f_types=pad,polarity=positive,include_syms=,exclude_syms=");
				$V->COM("filter_reset,filter_name=popup");
				$V->COM("display_layer,name=drill,display=no,number=1");
				$V->COM("get_select_count");
				my $selection_02 = $V->{COMANS};
				#$V->PAUSE("Features detected : $selection_02 ");
				if ( $selection_02 != 0)
				{
				$V->COM("sel_copy_other,dest=layer_name,target_layer=$tmplayer,invert=no,dx=0,dy=0,size=0");
				$V->COM("affected_layer,mode=all,affected=no");
				$V->COM("affected_layer,name=$tmplayer,mode=single,affected=yes");
				$V->COM("sel_copy_other,dest=layer_name,target_layer=$worklayer,invert=no,dx=0,dy=0,size=$kparea"); #####
				$V->COM("affected_layer,name=$worklayer,mode=single,affected=yes");
				$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
				$V->COM("affected_layer,name=$worklayer,mode=single,affected=no");
				$V->COM("sel_copy_other,dest=layer_name,target_layer=$worklayer,invert=yes,dx=0,dy=0,size=0");
				$V->COM("sel_delete");
				$V->COM("affected_layer,mode=all,affected=no");
				$V->COM("affected_layer,name=$worklayer,mode=single,affected=yes");
				$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
				$V->COM("cur_atr_set,attribute=.drc_comp_keepout");
				$V->COM("cur_atr_set,attribute=.drc_assembly_lyrs,option=both");
				$V->COM("sel_change_atr,mode=add,pkg_attr=no");
				$V->COM("cur_atr_reset");
				$V->COM("affected_layer,mode=all,affected=no");				
				}
			}			
		clear_and_reset();	
}
#####################################################################################
#						SUB-RUTINE to Create Shield Areas							#
#####################################################################################
sub create_shiled_areas
{
#--------------Set Variables ---------------
	my $JOB	= $ENV{JOB};
	my $STEP= $ENV{STEP};
	my $V	= new Valor;
	my $shieldlayer;
	my $side = $_[0];
	my $flag_used	= 0;
	if ($side eq "top")
	{
		$shieldlayer			= ('flex_temp_09');
	}	
	if ($side eq "bottom")
	{
		$shieldlayer			= ('flex_temp_10');
	}
#--------------------------------------------
			clear_and_reset();
			$V->COM("display_layer,name=$shieldlayer,display=yes,number=1");
			$V->COM("work_layer,name=$shieldlayer");
			$V->PAUSE("Draw manually Shields areas located in $side side if or just click Continue.");
			$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");

			$V->COM("cur_atr_set,attribute=.area_name,text=IN");
			$V->COM("sel_change_atr,mode=add,pkg_attr=no");
			$V->COM("display_layer,name=$shieldlayer,display=no,number=1");
			clear_and_reset();
}




#####################################################################################
#			SUB-RUTINE to identify the flow solder direction in the JOB				#
#####################################################################################

sub convert_appertures
{
#--------------Set Variables ---------------
	my $JOB	= $ENV{JOB};
	my $STEP= $ENV{STEP};
	my $V	= new Valor;
	my $wallresize = ($GUI_PROC_WALLTHK * 2);
	my $worklayer;
	my $templayer1;
	my $templayer2;
	my $oposite_comp_side;
	my $oposite_keepout_side;
	my $side = $_[0];
	my $flag_used	= 0;
	my $dim1;
	my $dim2;
	if ($side eq "top")
	{
		$flag_used 				= $BANDERA_TOP;
		$oposite_comp_side 			= ('comp_+_bot');
		$oposite_keepout_side 			= ('bottom');
		$worklayer				= ('flex_temp_01');
		$templayer1				= ('flex_temp_02');
		$templayer2				= ('flex_temp_03');
	}	
	if ($side eq "bottom")
	{
		$flag_used 				= $BANDERA_BOT;
		$oposite_comp_side 			= ('comp_+_top');
		$oposite_keepout_side 			= ('top');
		$worklayer				= ('flex_temp_01');
		$templayer1				= ('flex_temp_04');
		$templayer2				= ('flex_temp_05');
	}
#$V->PAUSE("Work Layer : $worklayer , Temp 1 :$templayer1 , Temp2 : $templayer2");
#---------------Check if exist drills as a toeprints-------------------------------------------	
	$V->COM("display_layer,name=$worklayer,display=yes,number=1");
	$V->COM("work_layer,name=$worklayer");
	$V->COM("sel_reverse");
	$V->COM("get_select_count");    					#Command to get number of selected features and is storage on $COMANS variable
			my $selection_01 = $V->{COMANS};			
			if ( $selection_01 == 0)
			{
				$V->COM("display_layer,name=$worklayer,display=no,number=1");
				print("No toeprints in drill layer was found \n");
			} 
#------------------------------------------------------------------------------------------------
else
	{
	$V->COM("sel_line2pad,max_length=500,diagonal=yes");
	$V->COM("display_layer,name=$worklayer,display=no,number=1");
			#Get drill size histogram from procmap_bot
			# ---------------------------------------------
			$V->DO_INFO("-t layer -e $JOB/$STEP/$worklayer");
			foreach my $toolsym(@{$V->{doinfo}{gSYMS_HISTsymbol}})
			{
				my $PROC_BASE 	= 0;	#Set variable base to 0
				my $PROC_ALTURA = 0;
				my $cycle_flag  = 0;
				print("Found symbol: $toolsym \n");
				#$V->PAUSE("Found symbol: $toolsym");
								
				if (($toolsym =~ /^r[0-9]+/) || ($toolsym =~ /^s[0-9]+/))
				{
						#my $toolsize = ${$V->{doinfo}{gTOOLdrill_size}}[$symindx];
						my $toolsize = $toolsym;
						$toolsize =~ s/r//g;
						$toolsize =~ s/s//g;
						print("Found ROUND: $toolsym and size $toolsize \n");
						if ( ($flag_used == 1) || ($flag_used == 3)) 
						{
							$PROC_BASE = $toolsize + $GUI_PROC_BASE + $GROW_FACTOR;	  # Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							$PROC_ALTURA = $toolsize + $GUI_PROC_HGHT + $GROW_FACTOR;	  # Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							
						} else
						{
							$PROC_BASE = $toolsize + $GUI_PROC_HGHT + $GROW_FACTOR; 	# Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							$PROC_ALTURA = $toolsize + $GUI_PROC_BASE+ $GROW_FACTOR; 	#Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							
						}
				$cycle_flag  = 1;		
				} 
				if (($toolsym =~ /^rect[0-9]+/) || ($toolsym =~ /^oval[0-9]+/))
					{
						my $toolsize = $toolsym;
						$toolsize =~ s/rect//g;
						$toolsize =~ s/oval//g;
						($dim1,$dim2) = split('x', $toolsize);
						print("Found ROUND: $toolsym and size $dim1 x $dim2 \n");
						if ( ($flag_used == 1) || ($flag_used == 3)) 
						{
							$PROC_BASE = $dim2 + $GUI_PROC_BASE + $GROW_FACTOR;	  # Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							$PROC_ALTURA = $dim1 + $GUI_PROC_HGHT + $GROW_FACTOR;	  # Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							#$V->PAUSE("Found symbol: $toolsym and size $dim1 x $dim2  aperture  $PROC_BASE x $PROC_ALTURA");
						} else
						{
							$PROC_BASE = $dim1 + $GUI_PROC_HGHT + $GROW_FACTOR; 	# Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							$PROC_ALTURA = $dim2 + $GUI_PROC_BASE+ $GROW_FACTOR; 	#Create the new shape by use drill size + input in GUI + 154 as a grow factor later this factor will be compensate
							#$V->PAUSE("Found symbol: $toolsym and size $dim1 x $dim2  aperture  $PROC_BASE x $PROC_ALTURA");
						}
					$cycle_flag  = 1;	
					}
				# if (($toolsym !~ /^r[0-9]+/) || ($toolsym !~ /^s[0-9]+/) || ($toolsym !~ /^rect[0-9]+/) || ($toolsym !~ /^oval[0-9]+/))

				if ($cycle_flag  == 0) 
				{
				    if ($mode ne "designers"){
				$V->PAUSE(" Your job has special symbols , the script will try to process them but is necessary you review the final result for wave apertures in the PTH pads with symbol $toolsym .");
										}	
				if (($flag_used == 1) || ($flag_used == 3) ) 
						{
							$PROC_BASE =  40 + $GUI_PROC_BASE + $GROW_FACTOR; 	# Create the new shape by use input in GUI + 154 as a grow factor later this factor will be compensate
							$PROC_ALTURA =  40 + $GUI_PROC_HGHT + $GROW_FACTOR; 	# Create the new shape by use input in GUI + 154 as a grow factor later this factor will be compensate
							
						} else
						{
							$PROC_BASE = 40 + $GUI_PROC_HGHT + $GROW_FACTOR;	  # Create the new shape by use input in GUI + 154 as a grow factor later this factor will be compensate
							$PROC_ALTURA =  40 + $GUI_PROC_BASE + $GROW_FACTOR;	  # Create the new shape by use input in GUI + 154 as a grow factor later this factor will be compensate							
						}
				}
				
				print(" :PROC_BASE  $PROC_BASE  x PROC_ALTURA: $PROC_ALTURA \n");
				#$V->PAUSE(" Length : $PROC_BASE  Width : $PROC_ALTURA Chamfer : $GUI_PROC_CHAMF");
				clear_and_reset();
				#----- Select drills and re-shape them ------
				$V->COM("display_layer,name=$worklayer,display=yes,number=3");
				$V->COM("work_layer,name=$worklayer");
				$V->COM("filter_set,filter_name=popup,update_popup=no,include_syms=$toolsym");
				$V->COM("zoom_refresh");
				$V->COM("filter_area_strt");
				$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
				my $tmpcmd = ("sel_change_sym,symbol=rect" . $PROC_BASE . "x" . $PROC_ALTURA . "xr" . $GUI_PROC_CHAMF);
				$V->COM("$tmpcmd");
				$V->COM("display_layer,name=$worklayer,display=no,number=3");
				$V->COM("filter_reset,filter_name=popup");
				#$F->PAUSE("Check size of appertures");
			}
			
			
	#----------------------------------------------Process to assign attribute and generate keepout zones-------------------------------------
			clear_and_reset();
			$V->COM("display_layer,name=$worklayer,display=yes,number=1");		#Display procmap_bot layer
			$V->COM("work_layer,name=$worklayer");					#Set as working layer
			$V->COM("sel_reverse");		#Do a reverse selection an active layer to select all features														
			$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
			$V->COM("sel_reverse");
			$V->COM("sel_copy_other,dest=layer_name,target_layer=$templayer1,invert=no,dx=0,dy=0,size=-$GROW_FACTOR");
			$V->COM("sel_delete");
			$V->COM("display_layer,name=$worklayer,display=no,number=1");
			$V->COM("display_layer,name=$templayer1,display=yes,number=3");
			$V->COM("work_layer,name=$templayer1");
			$V->VOF;
			$V->COM("display_layer,name=$oposite_comp_side,display=yes,number=1");
			$V->COM("display_layer,name=drill,display=yes,number=2");
			$V->VON;
				if ($mode ne "designers"){
			$V->PAUSE("Make editions in the Wave Pallet appertures if necessary");
										}
			$V->VOF;
			$V->COM("display_layer,name=$oposite_comp_side,display=no,number=1");
			$V->COM("display_layer,name=drill,display=no,number=2");
			$V->VON;
			$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
			$V->COM("sel_copy_other,dest=layer_name,target_layer=$templayer2,invert=no,dx=0,dy=0,size=0");
			$V->COM("display_layer,name=$templayer1,display=no,number=1");
			$V->COM("display_layer,name=$templayer2,display=yes,number=1");
			$V->COM("work_layer,name=$templayer2");
			$V->COM("cur_atr_set,attribute=.area_name,text=SELWAV");
			$V->COM("sel_change_atr,mode=add");
			$V->COM("cur_atr_reset");
			$V->COM("display_layer,name=$templayer2,display=no,number=1");
			$V->COM("display_layer,name=$templayer1,display=yes,number=1");
			$V->COM("work_layer,name=$templayer1");
			$V->COM("sel_resize,size=$wallresize");  ################
			$V->COM("display_layer,name=$templayer1,display=no,number=1");			
			$V->COM("display_layer,name=$templayer2,display=yes,number=1");
			$V->COM("work_layer,name=$templayer2");			
	if ($KEEPOUT_FOR_WAVE == 0)
		{
			$V->COM("sel_copy_other,dest=layer_name,target_layer=$templayer1,invert=yes,dx=0,dy=0,size=0");
		}
	else
		{
			$V->COM("sel_copy_other,dest=layer_name,target_layer=$templayer1,invert=no,dx=0,dy=0,size=0");
		}
			$V->COM("display_layer,name=$templayer2,display=no,number=1");			
			$V->COM("display_layer,name=$templayer1,display=yes,number=1");
			$V->COM("work_layer,name=$templayer1");			
			$V->COM("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y");
			$V->COM("cur_atr_set,attribute=.drc_comp_keepout,text=,option=$oposite_keepout_side");
			$V->COM("cur_atr_set,attribute=.drc_assembly_lyrs,text=,option=$oposite_keepout_side");
			$V->COM("sel_change_atr,mode=add");
			$V->COM("cur_atr_reset");
			$V->COM("display_layer,name=$templayer1,display=no,number=1");
				if ($side eq "top")
				{
						$V->COM("affected_layer,name=$templayer1,mode=single,affected=yes");
						$V->COM("sel_move_other,target_layer=flex_temp_11,invert=no,dx=0,dy=0,size=0");
						$V->COM("affected_layer,mode=all,affected=no");
				#$F->PAUSE("Verificar top");			
				}

	}
	clear_and_reset();
}

#####################################################################################
#			SUB-RUTINE to identify the flow solder direction in the JOB				#
#####################################################################################
sub discover_flow_direction
{
#----------------------------------#Set variables according to flow direction------------------------------------------------------------
	my $flowattr_indx = 0;
	my $JOB				=	$ENV{JOB};
	my $STEP			=	$ENV{STEP};
	my $V				=	new Valor;
	$V->DO_INFO("-t step -e $JOB/$STEP -d ATTR");
	foreach my $_attrname(@{$F->{doinfo}{gATTRname}})
	{
		if ($_attrname eq ".fs_direction_bottom")
		{
			if (((${$F->{doinfo}{gATTRval}}[$flowattr_indx]) eq "bottom2top") || ((${$F->{doinfo}{gATTRval}}[$flowattr_indx]) eq 'top2bottom' ))
			{
				$BANDERA_BOT = 1;	#Set bandera bot = 1 for flow direction top2bottom or bottom2top
			} else
			{
				$BANDERA_BOT = 2;	#Set bandera bot = 2 for flow direction left2right or right2left
			}
		}
		if ($_attrname eq ".fs_direction_top")
		{	
		
			if (((${$F->{doinfo}{gATTRval}}[$flowattr_indx]) eq "bottom2top") || ((${$F->{doinfo}{gATTRval}}[$flowattr_indx]) eq 'top2bottom' ))
			{
				$BANDERA_TOP = 3;	#Set bandera bot = 3 for flow direction top2bottom or bottom2top
			} else
			{
				$BANDERA_TOP = 4;	#Set bandera bot = 4 for flow direction left2right or right2left
			}	
		}
		$flowattr_indx++;
	}

}
#####################################################################################
#	SUB-RUTINE to Select the drills that works like a toeprint for PTH components	#
#####################################################################################
sub get_pth_toeprints
{
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $V				=	new Valor;
my $side = $_[0];
my $wrklyr_01 = 'flex_temp_01';
my $wrklyr_02 = 'flex_temp_02';
my $wrklyr_03 = 'flex_temp_03';
my $opositte_side;
	if ($side eq "top")
	{
	$opositte_side= 'bottom';
	}
	if ($side eq "bottom")
	{
	$opositte_side= 'top';
	}
#----Clean content from previous run
	$V->COM("affected_layer,name=$wrklyr_01,mode=single,affected=yes");
	$V->COM("sel_delete");
	$V->COM("affected_layer,mode=all,affected=no");
#-----------
	# $V->COM("display_layer,name=drill,display=yes,number=1");
	# $V->COM("work_layer,name=drill");
	# $V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.drill,option=plated");
	# $V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.plated_type,option=standard");
	# $V->COM("filter_area_strt");
	# $V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
	# $V->COM("filter_reset,filter_name=popup");	
#-----------
	$V->COM("display_layer,name=drill,display=yes,number=1");
	$V->COM("work_layer,name=drill");
	$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.plated_type,option=press_fit");
	$V->COM("filter_area_strt");
	$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
	$V->COM("filter_reset,filter_name=popup");
	$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.drill,option=via");
	$V->COM("filter_area_strt");
	$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
	$V->COM("filter_reset,filter_name=popup");
	$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.drill,option=non_plated");
	$V->COM("filter_area_strt");
	
	$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
	$V->COM("filter_reset,filter_name=popup");
	$V->COM("sel_reverse");
	$V->COM("get_select_count"); 
	my $selection_01 = $V->{COMANS};
	if ( $selection_01 != 0)
		{
	$V->COM("affected_layer,name=$opositte_side,mode=single,affected=yes");
	$V->COM("filter_set,filter_name=popup,update_popup=no,feat_types=pad");
	$V->COM("filter_set,filter_name=popup,update_popup=no,polarity=positive");
	$V->COM("sel_ref_feat,layers=,use=select,mode=touch,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative,include_syms=,exclude_syms=");
	$V->COM("display_layer,name=drill,display=no,number=2");
	$V->COM("sel_copy_other,dest=layer_name,target_layer=$wrklyr_01,invert=no,dx=0,dy=0,size=0");
	$V->COM("affected_layer,mode=all,affected=no");
	$V->COM("affected_filter,filter=\(context=board\&type=components\&side=$side\&hdi_type=\)");
	$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=thmt");
	if ( $SKIP_PTH != 0){$F->COM("filter_comp_set,filter_name=popup,update_popup=no,cpn_names=\*");}
	$V->COM("filter_area_strt");
	$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
	$V->PAUSE("check filter settings");
	$V->COM("filter_reset,filter_name=popup");
		if ($side eq "top")
		{
		$V->COM("comp_draw_to_layer,layer_mode=library,side=$side,layer_name_top=$wrklyr_02,layer_name_bot=,comp_mode=outline,draw_pins=yes,draw_pins_mode=surface,draw_centroids=no,name=no,draw_board_outline=no,fit2box=no,component_outline_mode=Body,draw_font=24,draw_selected=yes,use_placed_comp_only=no");
		}
		
		if ($side eq "bottom")
		{
		$V->COM("comp_draw_to_layer,layer_mode=library,side=$side,layer_name_top=,layer_name_bot=$wrklyr_02,comp_mode=outline,draw_pins=yes,draw_pins_mode=surface,draw_centroids=no,name=no,draw_board_outline=no,fit2box=no,component_outline_mode=Body,draw_font=24,draw_selected=yes,use_placed_comp_only=no");
		}
	$V->COM("affected_layer,mode=all,affected=no");
	$V->COM("display_layer,name=$wrklyr_02,display=yes,number=1");
	$V->COM("work_layer,name=$wrklyr_02");
	$V->COM("affected_layer,mode=all,affected=no");
	$V->COM("sel_reverse");
	$V->COM("get_select_count"); 
	my $selection_01 = $V->{COMANS};
	if ( $selection_01 != 0)
		{
		$V->COM("display_layer,name=$wrklyr_02,display=no,number=1");
		$V->COM("affected_layer,name=$wrklyr_02,mode=single,affected=yes");
		$V->COM("sel_cont2pad,match_tol=1,restriction=,min_size=5,max_size=5000,suffix=+++");
		$V->COM("filter_set,filter_name=popup,update_popup=no,feat_types=line\;surface\;arc\;text");
		$V->COM("filter_area_strt");
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$V->COM("filter_reset,filter_name=popup");
		$V->COM("sel_delete");
		$V->COM("affected_layer,mode=all,affected=no");
		$V->COM("display_layer,name=$wrklyr_02,display=yes,number=1");
		$V->COM("work_layer,name=$wrklyr_02");
		$V->COM("sel_change_sym,symbol=r2");
		$V->COM("sel_reverse");
		$V->COM("affected_layer,name=$wrklyr_01,mode=single,affected=yes");
		$V->COM("sel_ref_feat,layers=,use=select,mode=touch,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative,include_syms=,exclude_syms=");
		$V->COM("display_layer,name=$wrklyr_02,display=no,number=1");
		}
	$V->COM("display_layer,name=$wrklyr_02,display=no,number=1");
	$V->COM("display_layer,name=$wrklyr_01,display=yes,number=1");
	$V->COM("work_layer,name=$wrklyr_01");
	$V->COM("affected_layer,mode=all,affected=no");
	$V->COM("sel_reverse");
	$V->COM("get_select_count"); 
	my $selection_01 = $V->{COMANS};
	if ( $selection_01 != 0)
		{
		$V->COM("sel_delete");		
		}
	$V->COM("display_layer,name=$wrklyr_01,display=no,number=1");
	$V->COM("display_layer,name=$wrklyr_02,display=yes,number=1");
	$V->COM("work_layer,name=$wrklyr_02");
	$V->COM("sel_reverse");
	$V->COM("get_select_count"); 
	my $selection_01 = $V->{COMANS};
	if ( $selection_01 != 0)
		{
		$V->COM("sel_delete");		
		}		
		$V->COM("display_layer,name=$wrklyr_02,display=no,number=1");
	}
}

#####################################################################################
#		SUB-RUTINE TO CREATE A SIMPLE MAP WHEN NO PTH IN DRILL OR COMPONENTS		#
#####################################################################################
sub ceate_simple_map
{
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $V				=	new Valor;
$V->COM("display_layer,name=flex_temp_01,display=yes,number=1");
$V->COM("work_layer,name=flex_temp_01");
$V->COM("sr_fill,polarity=positive,step_margin=0,step_max_dist=100,sr_margin=0,nest_sr=yes,consider_feat=no,feat_margin=0,consider_drill=no,drill_margin=0,dest=affected_layers,layer=flex_temp_01,attributes=no");
$V->COM("cur_atr_set,attribute=.area_name,text=SMT");
$V->COM("sel_change_atr,mode=add,pkg_attr=no");
$V->COM("sel_copy_other,dest=layer_name,target_layer=flex_temp_02,invert=no,dx=0,dy=0,size=0");
$V->COM("open_entity,job=$JOB,type=matrix,name=matrix,iconic=no");
$V->COM("matrix_rename_layer,job=$JOB,matrix=matrix,layer=flex_temp_01,new_name=procmap_top");
$V->COM("matrix_rename_layer,job=$JOB,matrix=matrix,layer=flex_temp_02,new_name=procmap_bot");
$V->COM("matrix_page_close,job=$JOB,matrix=matrix");
}

#####################################################################################
# 			SUBRUTINE TO SET THE DRC LAYERS FOR CUSTOM FLEX ANALYSIS				#
#####################################################################################
sub set_drc_layers
{
my $JOB				=	$ENV{JOB};
my $V				=	new Valor;
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_route_keepin_lyr,value=drc_rout_keepin");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_comp_keepin_lyr,value=keepin_layer");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_tp_keepin_lyr,value=drc_tp_keepin");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_route_keepout_lyr,value=drc_rout_keepout");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_comp_keepout_lyr,value=keepout_layer");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_pad_keepout_lyr,value=drc_pad_keepout");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_via_keepout_lyr,value=drc_via_keepout");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_trace_keepout_lyr,value=drc_trace_keepout");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_plane_keepout_lyr,value=drc_plane_keepout");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_comp_height_lyr,value=drc_comp_height");
$V->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=.drc_tp_keepout_lyr,value=drc_tp_keepout");
}

#####################################################################################
# 			SUBRUTINE TO CREATE THE DRC LAYERS FOR CUSTOM FLEX ANALYSIS				#
#####################################################################################
sub create_drc_layers_if_not_exist
{
	$V = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	
	my @drc_layers = ('drc_rout_keepin','keepin_layer','drc_tp_keepin','drc_rout_keepout','keepout_layer','drc_pad_keepout','drc_via_keepout','drc_trace_keepout','drc_plane_keepout','drc_comp_height','drc_tp_keepout');
	$V->DO_INFO("-t matrix -e $JOB/matrix -d NUM_LAYERS");
	my $num = ($F->{doinfo}{gNUM_LAYERS});
	$num =~ s/\'//g;
	$num ++;

	foreach my $drc_layer (@drc_layers)
			{
				my $comp_layer_flag = 0;
				my $STAT;
				$V->VOF;
					$V->COM("display_layer,name=$drc_layer,display=yes,number=1");
					$STAT = $V->{STATUS};
				$V->VON;
				$V->COM("clear_layers");
				$V->COM("affected_layer,mode=all,affected=no");

				if ($STAT != 0) 
					{
						#CREATE LAYERS
						$V->COM("matrix_insert_row,job=$JOB,matrix=matrix,row=$num");
						$V->COM("matrix_refresh,job=$JOB,matrix=matrix");						
						$V->COM("matrix_add_layer,job=$JOB,matrix=matrix,layer=$drc_layer,row=$num,context=misc,type=document,polarity=positive,sub_type=");
						$num ++;
					}
			}
}

#####################################################################################
#				SUB-RUTINE TO EVALUATE THE PRODUCT CONFIGURATION    #
#####################################################################################
sub evaluate_product_configuration
{
##########################################################################################
#					Discover if board have 1 or 2 component sides	 #
# Check if top and bottom layers exist and save the status in comp_layer_flag variable,  #
# using VOF command to enter failure handling mode and obtain the value on $STATUS       #
# variable. Note that if $STATUS is different of '0', it means than layer does not exist #
##########################################################################################
my $comp_layer_flag = 0;
my $STAT;
$V->VOF;
	$V->COM("display_layer,name=comp_+_top,display=yes,number=1");
	$STAT = $V->{STATUS};
$V->VON;
$V->COM("clear_layers");
$V->COM("affected_layer,mode=all,affected=no");

if ($STAT == 0) 
	{
	$comp_layer_flag = $comp_layer_flag + 1;
	}

$V->VOF;
	$V->COM("display_layer,name=comp_+_bot,display=yes,number=1");
	$STAT = $V->{STATUS};
$V->VON;
$V->COM("clear_layers");
$V->COM("affected_layer,mode=all,affected=no");

if ($STAT == 0)
	{
	$comp_layer_flag = $comp_layer_flag + 2;
	}

# 0 means "no component layer present in the board"
# 1 means "only top component layer present in the board"
# 2 means "only bottom component layer present in the board"
# 3 means "top and bottom component layers present in the board"

#####################################################################################
#				SET VARIABLES ACCORDING EACH PRODUCT CONFIGURATION					#
#####################################################################################
	if ($comp_layer_flag == 0)    # 0 means "no component layer present in the board"
	{
		$EXIST_PTH_ON_TOP = ("No");
		$EXIST_PTH_ON_BOT = ("No");
	}
#----------------------------------------------------------------------------------	
	if ($comp_layer_flag == 1)    # 1 means "only top component layer present in the board"
	{ 
		$V->COM("display_layer,name=comp_+_top,display=yes,number=1");
		$V->COM("work_layer,name=comp_+_top");
		$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=thmt");
		$V->COM("filter_area_strt");
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$V->COM("filter_reset,filter_name=popup");
		$V->COM("get_select_count");
		my $selection_count_01 = $V->{COMANS};
			if ( $selection_count_01 != 0)				#if there are selected features do as follows
					{		
					clear_and_reset ();		
					#---------------------------
					$EXIST_PTH_ON_TOP = ("Yes");
					$EXIST_PTH_ON_BOT = ("No");
					#---------------------------					
					clear_and_reset ();			
					}		
				else
					{
					#--------------------------
					$EXIST_PTH_ON_TOP = ("No");
					$EXIST_PTH_ON_BOT = ("No");
					#--------------------------
					clear_and_reset ();
					}	
					
	}
#----------------------------------------------------------------------------------	
	if ($comp_layer_flag == 2)    # 2 means "only bottom component layer present in the board"
	{ 
		$V->COM("display_layer,name=comp_+_bot,display=yes,number=1");
		$V->COM("work_layer,name=comp_+_bot");
		$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=thmt");
		$V->COM("filter_area_strt");
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$V->COM("filter_reset,filter_name=popup");
		$V->COM("get_select_count");
		my $selection_count_01 = $V->{COMANS};	
			if ( $selection_count_01 != 0)				#if there are selected features do as follows
					{		
					clear_and_reset ();		
					#---------------------------
					$EXIST_PTH_ON_TOP = ("No");
					$EXIST_PTH_ON_BOT = ("Yes");
					#---------------------------					
					clear_and_reset ();			
					}		
				else
					{
					#--------------------------
					$EXIST_PTH_ON_TOP = ("No");
					$EXIST_PTH_ON_BOT = ("No");
					#--------------------------
					clear_and_reset ();
					}	
	}
#----------------------------------------------------------------------------------	
	if ($comp_layer_flag == 3)    # 3 means "top and bottom component layers present in the board"
	{ 
		$V->COM("display_layer,name=comp_+_top,display=yes,number=1");
		$V->COM("work_layer,name=comp_+_top");
		$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=thmt");
		$V->COM("filter_area_strt");
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$V->COM("filter_reset,filter_name=popup");
		$V->COM("get_select_count");
		my $selection_count_01 = $V->{COMANS};	
			if ( $selection_count_01 != 0)				#if there are selected features do as follows
					{		
					clear_and_reset ();		
					#---------------------------
					$EXIST_PTH_ON_TOP = ("Yes");
					#---------------------------					
					clear_and_reset ();			
					}		
				else
					{
					#--------------------------
					$EXIST_PTH_ON_TOP = ("No");
					#--------------------------
					clear_and_reset ();
					}		
	
		$V->COM("display_layer,name=comp_+_bot,display=yes,number=1");
		$V->COM("work_layer,name=comp_+_bot");
		$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.comp_mount_type,option=thmt");
		$V->COM("filter_area_strt");
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$V->COM("filter_reset,filter_name=popup");
		$V->COM("get_select_count");
		my $selection_count_01 = $V->{COMANS};	
			if ( $selection_count_01 != 0)				#if there are selected features do as follows
					{		
					clear_and_reset ();		
					#---------------------------
					$EXIST_PTH_ON_BOT = ("Yes");
					#---------------------------					
					clear_and_reset ();			
					}		
				else
					{
					#--------------------------
					$EXIST_PTH_ON_BOT = ("No");
					#--------------------------
					clear_and_reset ();
					}	

	}
#----------------------------------------------------------------------------------	
$V->VOF;
	$V->COM("display_layer,name=drill,display=yes,number=1");
	$STAT = $V->{STATUS};
$V->VON;
$V->COM("clear_layers");
$V->COM("affected_layer,mode=all,affected=no");

if ($STAT == 0)
	{
		$V->COM("display_layer,name=drill,display=yes,number=1");
		$V->COM("work_layer,name=drill");
		$V->COM("filter_atr_set,filter_name=popup,condition=yes,attribute=.drill,option=plated");
		$V->COM("filter_area_strt");
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");
		$V->COM("filter_reset,filter_name=popup");
		$V->COM("get_select_count");
		my $selection_count_01 = $V->{COMANS};	
			if ( $selection_count_01 != 0)				#if there are selected features do as follows
					{		
					clear_and_reset ();		
					#---------------------------
					$EXIST_PTH_DRILL = ("Yes");
					#---------------------------					
					clear_and_reset ();			
					}		
				else
					{
					#--------------------------
					$EXIST_PTH_DRILL = ("No");
					#--------------------------
					clear_and_reset ();
					}		
	}
	else 
	{
	$EXIST_PTH_DRILL= ("No");
	clear_and_reset ();
	}
#----------------------------------------------------------------------------------	

}

#####################################################################################
#			SUB-RUTINE TO CREATE THE GUI FOR INPUT DIMENSIONS OF APPERTURES			#
#####################################################################################
sub procmap_gui
{

#####################################################################################
#								GUI FORMAT  Variables								#
#####################################################################################
my $gui_title		= ("Flextronics DFM Process Guide");
my $bg_color		= ("black");
my $fg_color		= ("white");
my $shadow_color	= ("grey50");
my $hgt_color		= ("orange");
my $btnbody_color	= ("dark grey");
my $exit_color		= ("red");
my $big_font		= ("Helvetica 18 italic bold");
my $medium_font		= ("Helvetica 12 italic");
my $small_font		= ("Helvetica 10 italic");
#####################################################################################
#							GUI Main construction									#
#####################################################################################
alarm 240;
$SIG{ALRM} = sub { print "ProcMap creation Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
$MW = new MainWindow;
$MW->configure	(-title => $gui_title);
$MW->geometry	("+200+50");
$MW->configure	(-background => $bg_color);
my $image_file_name = 'logo.bmp';
my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
my $icon 			= $MW->Photo(-file => $image);
$MW->idletasks;
$MW->iconimage	($icon);

	my $big_font2 = $MW->fontCreate(-family => 'helvetica', -size  => 12); 

#####################################################################################
#
#		begining of addtion to the script
#		
#		Legacy mode is for keeping the old script just swapping control to the new addtions and methods
#		reason: back up for the old methods and keep them a part of the main script
#
#####################################################################################
#
#		adding the new frams to the main GUI
#
	my $vu_frm_aperture_r = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);


	my $vu_lb_aperture_r = $vu_frm_aperture_r->Label(
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'center', 
								-text		=> 'Aperture Radious:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	$legacy_entry = $vu_frm_aperture_r->Entry(
							-width => 12,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $big_font,
							-background => $bg_color,
							-foreground => $fg_color,
							-textvariable => \$GUI_PROC_RADIUS,
							
							-validate     => 'key',
							-vcmd         => \&validate,
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );

#####################################################################################
#
#		Adding a fram for Legacy support
#
	my $vu_frm_legacy = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

		$checkbtn_mount  = $vu_frm_legacy->Checkbutton( 
										-text		=> 'Use Legacy Mode',
										-onvalue => 1,
										-offvalue => 0,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'left', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $shadow_color,
										-activebackground	=> $hgt_color,
										-variable 		=> \$LEGACY_MODE,
										-command         => \&legacy_mode_switch,
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);

#
#	End of addtion to GUI
#
#####################################################################################


	my $vu_frm1 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);


	my $vu_lb1 = $vu_frm1->Label(
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'center', 
								-text		=> 'Width Aperture:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);
	$legacy_entry_width = $vu_frm1->Entry(
							-width => 12,
                             #-background => 'white',
							 
							 -justify	=> 'center',
							-font		=> $big_font,
							-background => $bg_color,
							-foreground => $fg_color,
							-textvariable => \$GUI_PROC_BASE,
							-validate     => 'key',
							-vcmd         => \&validate,
							-state =>    'disable',
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );

	#$vu_en1->insert('end',"300");

	
	
	my $vu_frm2 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb2 = $vu_frm2->Label(
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'center', 
								-text		=> 'Length Aperture:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	$legacy_entry_length = $vu_frm2->Entry(
							-width => 12,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $big_font,
							-background => $bg_color,
							-foreground => $fg_color,
							-textvariable => \$GUI_PROC_HGHT,
							-validate     => 'key',
							-vcmd         => \&validate,
							-state => 'disable',
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );

	#$vu_en2->insert('end',"500");

	my $vu_frm3 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb3 = $vu_frm3->Label(
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'center', 
								-text		=> 'Chamfer Size:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	$legacy_entry_chamfer = $vu_frm3->Entry(
							-width => 12,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $big_font,
							-background => $bg_color,
							-foreground => $fg_color,
							-textvariable => \$GUI_PROC_CHAMF,
							-validate     => 'key',
							-vcmd         => \&validate,
							-state => 'disable',
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );

	#$vu_en3->insert('end',"125");

	my $vu_frm4 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb4 = $vu_frm4->Label(
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'center', 
								-text		=> 'Wave Pallet Wall Thickness:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	$legacy_entry_thickness= $vu_frm4->Entry(
							-width => 12,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $big_font,
							-background => $bg_color,
							-foreground => $fg_color,
							-textvariable => \$GUI_PROC_WALLTHK,
							-validate     => 'key',
							-vcmd         => \&validate,
							-state => 'disable',
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );

	#$vu_en4->insert('end',"50");

	# start radio
	my $vu_frm6 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb6 = $vu_frm6->Label(
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'center', 
								-text		=> 'TOP Process:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);
	$rdt_wave = $vu_frm6 -> Radiobutton(
										-activebackground		=> $bg_color, 
										-activeforeground		=> $hgt_color, 
										-background  			=> $bg_color,
										-font 					=> $medium_font, 
										-foreground				=> $fg_color,
										-justify  				=> 'left',
										-relief  				=> 'flat', 
										-text 					=> "WAVE SOLDER", 
										-value       			=> "WAVSOL",
										-selectcolor  			=> $bg_color,
										-variable				=>\$TOP_PROC,
										-state => 'disable',									
									   )
										->pack(
												-side => 'right'
												);;	
	

	$rdt_smt = $vu_frm6 -> Radiobutton(
										-activebackground		=> $bg_color, 
										-activeforeground		=> $hgt_color, 
										-background  			=> $bg_color,
										-font 					=> $medium_font, 
										-foreground				=> $fg_color,
										-justify  				=> 'left',
										-relief  				=> 'flat', 
										-text 					=> "SMT", 
										-value       			=> "SMT",
										-selectcolor  			=> $bg_color,
										-variable				=>\$TOP_PROC,
										-state => 'disable',										
									   )
										->pack(
												-side => 'right'
												);;

# $rdt_selwave = $vu_frm6 -> Radiobutton(
										# -text=>"SEL WAVE",
										# -value=>"SELWAV",
										# -variable=>\$TOP_PROC
										# )
											# ->pack(
											# -side => 'left'
											# );;
											
											
	
		
		
	my $vu_frm7 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);
	my $vu_lb7 = $vu_frm7->Label(
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'center', 
								-text		=> 'BOTTOM Process:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);
	$rdb_wave = $vu_frm7 -> Radiobutton(
										-activebackground		=> $bg_color, 
										-activeforeground		=> $hgt_color, 
										-background  			=> $bg_color,
										-font 					=> $medium_font, 
										-foreground				=> $fg_color,
										-justify  				=> 'left',
										-relief  				=> 'flat', 
										-text 					=> "WAVE SOLDER", 
										-value       			=> "WAVSOL",
										-selectcolor  			=> $bg_color,
										-variable				=>\$BOT_PROC,
										-state => 'disable',										
									   )
										->pack(
												-side => 'right'
												);;	
	$rdb_smt = $vu_frm7 -> Radiobutton(
										-activebackground		=> $bg_color, 
										-activeforeground		=> $hgt_color, 
										-background  			=> $bg_color,
										-font 					=> $medium_font, 
										-foreground				=> $fg_color,
										-justify  				=> 'left',
										-relief  				=> 'flat', 
										-text 					=> "SMT", 
										-value       			=> "SMT",
										-selectcolor  			=> $bg_color,
										-variable				=>\$BOT_PROC,	
										-state => 'disable',										
									   )
										->pack(
												-side => 'right'
												);;	

	# $rdb_selwave = $vu_frm7 -> Radiobutton(-text=>"SEL WAVE",
        # -value=>"SELWAV",-variable=>\$bot_process)->pack(-side => 'left');;

	#end radio

#############################################################################################################################
# 						Check button 01			
#############################################################################################################################															
	my $vu_frm43 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top',
									-fill => 'x',									
									#-fill => 'y',
									);
		$checkbtn_mount  = $vu_frm43->Checkbutton( 
										-text		=> 'Include Mounting Pads for keepout Areas',
										-onvalue => 1,
										-offvalue => 0,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'left', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $shadow_color,
										-activebackground	=> $hgt_color,
										-variable 			=> \$INCLUDE_MOUNT,
										-command         => \&activate_field,
										-state=>'disable',
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);

	$mount_entry = $vu_frm43->Entry(
							-width => 12,
                             #-background => 'white',
							-state 			=> 'normal', 
							-justify	=> 'center',
							-font		=> $big_font,
							-background => $bg_color,
							-foreground => $fg_color,
							-textvariable => \$MOUNT_CLEARANCE,
							-validate     => 'key',
							-vcmd         => \&validate,
							-state 	=> 'disable', 
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );
#############################################################################################################################
# 						Check button 02			
#############################################################################################################################															
	my $vu_frm44 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top',
									-fill => 'x',									
									#-fill => 'y',
									);
		$checkbtn_01b  = $vu_frm44->Checkbutton( 
										-text		=> 'Consider wave solder areas as component keepout zone',
										-onvalue => 1,
										-offvalue => 0,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'left', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $shadow_color,
										-activebackground	=> $hgt_color,
										-variable 			=> \$KEEPOUT_FOR_WAVE,
										-state=>'disable',
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);									   
#############################################################################################################################
# 						Check button 03			
#############################################################################################################################															
	my $vu_frm45 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top',
									-fill => 'x',									
									#-fill => 'y',
									);
		$checkbtn_01c  = $vu_frm45->Checkbutton( 
										-text		=> 'Include Shields Areas for Process Map',
										-onvalue => 1,
										-offvalue => 0,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'left', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $shadow_color,
										-activebackground	=> $hgt_color,
										-variable 			=> \$INCLUDE_SHIELDS,
										-state=>'disable',
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);
#############################################################################################################################
# 						Check button 04			
#############################################################################################################################															
	my $vu_frm46 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top',
									-fill => 'x',									
									#-fill => 'y',
									);
		$checkbtn_01d  = $vu_frm46->Checkbutton( 
										-text		=> 'Skip non-populated PTH components for wave solder areas',
										-onvalue => 1,
										-offvalue => 0,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'left', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $shadow_color,
										-activebackground	=> $hgt_color,
										-variable 			=> \$SKIP_PTH,
										-state=>'disable',
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);
#############################################################################################################################															
#############################################################################################################################

	my $vu_frm5 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top',
									-fill => 'x',									
									#-fill => 'y',
									);

	my $vu_but = $vu_frm5->Button(
									-width 				=> 12,
									-pady				=> '1',
									-relief				=> 'raised',
									-padx				=> '1',
									-state				=> 'normal',
									-justify			=> 'center',
									-background			=> $btnbody_color,
									-activebackground	=> $hgt_color,
									-foreground			=> $bg_color,
									-font				=> $small_font,
									-text				=> 'Apply',
									#-command 			=>\&process_gui
								#	-command 			=> [$MW => 'destroy']
									-command 			=> sub { $MW->destroy();alarm 0;},
									)
										->pack(
												-side => 'right',
												-fill => 'y',
												-fill => 'x'
												);

	my $vu_but1 = $vu_frm5->Button(
									-width 				=> 12,
									-pady				=> '1',
									-relief				=> 'raised',
									-padx				=> '1',
									-state				=> 'normal',
									-justify			=> 'center',
									-background			=> $btnbody_color,
									-activebackground	=> $exit_color,
									-foreground			=> $bg_color,
									-font				=> $small_font,
									-text				=> 'Cancel',
									-command			=>sub{exit(0)},
									)
										->pack(
												-side => 'left',
												-fill => 'y',
												-fill => 'x'
											   );				
						
	MainLoop;
	
}



#####################################################################################
#		SUB-RUTINE TO ENABLE OR DISABLE LEGACY MODE				#
#####################################################################################
sub legacy_mode_switch {
		if ($LEGACY_MODE == 1)
		{
			$legacy_entry->configure( -state => 'disable' );
			$legacy_entry_width->configure( -state => 'normal' );
			$legacy_entry_length->configure( -state => 'normal' );
			$legacy_entry_chamfer->configure( -state => 'normal' );
			$legacy_entry_thickness->configure( -state => 'normal' );
			$mount_entry->configure( -state => 'normal' );	

			$rdb_wave->configure( -state => 'normal');
			$rdb_smt->configure( -state => 'normal');
			
			$rdt_wave->configure( -state => 'normal');
			$rdt_smt->configure( -state => 'normal');

			$checkbtn_mount->configure( -state => 'normal');
			$checkbtn_01b->configure( -state => 'normal');
			$checkbtn_01c->configure( -state => 'normal');
			$checkbtn_01d->configure( -state => 'normal');

			$MW -> update;
			#$F->PAUSE("$legacy_entry")
		}
		if ($LEGACY_MODE != 1)
		{

			$legacy_entry->configure( -state => 'normal' );

			$mount_entry->configure( -state => 'disable' );	
			$legacy_entry_width->configure( -state => 'disable' );
			$legacy_entry_length->configure( -state => 'disable' );
			$legacy_entry_chamfer->configure( -state => 'disable' );
			$legacy_entry_thickness->configure( -state => 'disable' );

			$rdb_wave->configure( -state => 'disable');
			$rdb_smt->configure( -state => 'disable');
			
			$rdt_wave->configure( -state => 'disable');
			$rdt_smt->configure( -state => 'disable');

			$checkbtn_mount->configure( -state => 'disable');
			$checkbtn_01b->configure( -state => 'disable');
			$checkbtn_01c->configure( -state => 'disable');
			$checkbtn_01d->configure( -state => 'disable');
			$MW -> update;
		}
}

#####################################################################################
#		SUB-RUTINE TO ENABLE OR DISABLE FIELD FOR KEEPOUT DIMENSIONS				#
#####################################################################################
sub activate_field {
		if ($INCLUDE_MOUNT != 1)
		{
			$mount_entry->configure( -state => 'disable' );	
			$MW -> update;
		}
		if ($INCLUDE_MOUNT == 1)
		{
			$mount_entry->configure( -state => 'normal' );	
			$MW -> update;
		}
}

#####################################################################################
#	SUB-RUTINE TO CHECK IF ENTRY VAUES ARE VALID OR IF THERE IS A BLANK ENTRY		#
#####################################################################################
sub process_gui 
{
	my $calc01      = ($GUI_PROC_HGHT - $GUI_PROC_BASE);
	my $calc02      = (($GUI_PROC_BASE/2) - $GUI_PROC_CHAMF);
	
	if ($GUI_PROC_BASE == 0 || $GUI_PROC_HGHT == 0 || $GUI_PROC_CHAMF == 0 || $GUI_PROC_WALLTHK == 0 || $MOUNT_CLEARANCE == 0)
	{
	error_popup("Some of the fields contain illegal data\n the value \"0\" is not allow, \n please run again the script.");
	}
	if ($calc01 <= 0)
	{
	error_popup("Some of the fields contain illegal data\n the width should be smaller than length, \n please run again the script.");
	}
	if ($calc02 <= 0)
	{
	error_popup("Some of the fields contain illegal data\n the chamfer should be smaller than half of the width, \n please run again the script.");
	}

	#$F->PAUSE(" Length : $GUI_PROC_BASE  Width : $GUI_PROC_HGHT Chamfer : $GUI_PROC_CHAMF  Wall : $GUI_PROC_WALLTHK Top Process :$TOP_PROC Bottom Process :$BOT_PROC");
}

#####################################################################################
#					SUB-RUTINE TO VALIDATE THE GUI ENTRY							#
#####################################################################################
sub validate
{
  my $val = shift;
  $val ||= 0;
  #get alphas and punctuation out
  if( $val !~ /^\d+$/ ){ return 0 }
  if (($val >= 0) and ($val <= 1000)) {return 1}
    else{ return 0 }
}

#####################################################################################
#					SUB-RUTINE TO CREATE ERROR POPUP								#
#####################################################################################
sub error_popup
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
alarm 60;
$SIG{ALRM} = sub { print "ProcMap creation Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
$MW = new MainWindow;
$MW->configure	(-title => 'Error Message');
$MW->geometry	("+300+300");
$MW->configure	(-background => $bg_color);
my $image_file_name = 'logo.bmp';
my $error = 'error.bmp';
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
			#	-command 			=> [$MW => 'destroy']
				-command 			=> sub { $MW->destroy();alarm 0;},
				)
				->pack(
						-side => 'top'
						);
MainLoop;

exit(0);
}

#####################################################################################
#					SUB-RUTINE TO DELETE LAYERS FROM PREVIOUS RUN					#
#####################################################################################
sub delete_layers_from_prev_run
{
my @working_layers = ('procmap_bot','procmap_top','keepout_layer','keepout_layer_top','keepout_layer_bot','flex_temp_01','flex_temp_01+++','flex_temp_02','flex_temp_02+++','flex_temp_03','flex_temp_03+++','flex_temp_04','flex_temp_04+++','flex_temp_05','flex_temp_05+++','flex_temp_06','flex_temp_07','flex_temp_08','flex_temp_09','flex_temp_10','flex_temp_11','flex_temp_12','comp_pins_top','comp_pins_bot','comp_body_top','comp_body_bot','thermal','comp_pins','comp_body');
	foreach my $work_layer (@working_layers)
		{
		$V->VOF;
			$V->COM("delete_layer,layer=$work_layer");
		$V->VON;
		}
}

#####################################################################################
#					SUB-RUTINE TO DELETE LAYER IF EXIST 							#
#####################################################################################
sub delete_layer_if_exists
{
my $layer = $_[0];
$V->VOF;
	$V->COM("delete_layer,layer=$layer");
$V->VON;
}
#####################################################################################
#					SUB-RUTINE TO CREATE WORKING LAYERS								#
#####################################################################################
sub create_temp_layers
{
	$V = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my @working_temp_layers = ('flex_temp_01','flex_temp_02','flex_temp_03','flex_temp_04','flex_temp_05','flex_temp_06','flex_temp_07','flex_temp_08','flex_temp_09','flex_temp_10','flex_temp_11','flex_temp_12','comp_pins_top','comp_pins_bot','comp_body_top','comp_body_bot');
	
	$V->DO_INFO("-t matrix -e $JOB/matrix -d NUM_LAYERS");
	my $num = ($V->{doinfo}{gNUM_LAYERS});
	$num =~ s/\'//g;
	$num ++;
	#$F->PAUSE("Number of layers in the JOB : $num");
		foreach my $work_temp_layer (@working_temp_layers)
			{
			$V->COM("matrix_insert_row,job=$JOB,matrix=matrix,row=$num");
			$V->COM("matrix_refresh,job=$JOB,matrix=matrix");			
			$V->COM("matrix_add_layer,job=$JOB,matrix=matrix,layer=$work_temp_layer,row=$num,context=misc,type=document,polarity=positive,sub_type=");
			$num ++;
			}
}

#####################################################################################
#					SUB-RUTINE TO DELETE TEMPORAL LAYERS							#
#####################################################################################
sub delete_temp_layers
{
my @working_layers = ('flex_temp_01','flex_temp_02','flex_temp_02+++','flex_temp_03','flex_temp_03+++','flex_temp_04','flex_temp_05','flex_temp_06','flex_temp_07','flex_temp_08','flex_temp_09','flex_temp_10','flex_temp_11','flex_temp_12');
	foreach my $work_layer (@working_layers)
		{
		$V->VOF;
			$V->COM("delete_layer,layer=$work_layer");
		$V->VON;
		}
}

#####################################################################################
#								DEFAULT SUBRUTINES									#
#####################################################################################

#####################################################################################
#					SUB-RUTINE TO WRITE IN THE LOG FILE								#
#####################################################################################
sub write_in_log
{
	print("START LOG CREATION...","\n");
	my $V = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my $datestamp = localtime ();
	my $host = hostname;
	my $script_name = $_[0];
	$V->COM("get_job_path,job=$JOB");
	my $JOBPATH = $V->{COMANS};
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
	my $V = new Valor ;
	$JOB = $ENV{JOB};
	$STEP = $ENV{STEP};
	my $datestamp = localtime (); 
	my $host = hostname;
	$V->COM("get_job_path,job=$JOB");
	my $JOBPATH = $V->{COMANS};
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
	$V->COM("get_job_path,job=$JOB");
	my $JOBPATH = $V->{COMANS};
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
	$V->DO_INFO("-t job -e $JOB -d STEPS_LIST");
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
 $V->PAUSE("Hi $user , you are not detected as Flextronics user, you are not authorized to use this solution please abort.");
 exit (0);
 }
  if ($dfmuser ne 'YES' )
 {
 $V->PAUSE("Hi $user , you are not detected as DFM Engineer, you are not authorized to use this solution please abort.");
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
my $fg_color		= ("white");
my $shadow_color	= ("grey50");
my $hgt_color		= ("orange");
my $btnbody_color	= ("dark grey");
my $exit_color		= ("red");
my $big_font		= ("Helvetica 18 italic bold");
my $medium_font		= ("Helvetica 12 italic");
my $small_font		= ("Helvetica 10 italic");
my $sentence		= $_[0];
#my $V				= new Valor;
#----------------------GUI Main construction----------------------------------------
alarm 60;
$SIG{ALRM} = sub { print "ProcMap creation Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
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
				-foreground => $fg_color,
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
	my $fotografia	= $pic_frame->Photo(-file => $picture);
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
			#	-command 			=> [$MW => 'destroy']
				-command 			=> sub { $MW->destroy();alarm 0;},
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
alarm 60;
$SIG{ALRM} = sub { $MW->destroy();print "ProcMap creation Inactivity Timeout!\n";}; # trap an alarm and assign a sub to destroy the window
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
				-foreground => $fg_color,
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
			#	-command 			=> [$MW => 'destroy']
				-command 			=> sub { $MW->destroy();alarm 0;},
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
alarm 0;
#print("-----   $script  -----","\n");
system("perl $script") or print("NOTE: Script $script_file_name does not exist.","\n");
}
#####################################################################################
#					SUB-RUTINE TO CLEAR AND RESET									#
#####################################################################################
sub clear_and_reset
{
	# Clears selects, highlights, layers, and resets filters
	my $V = new Valor;
	
	$V->COM("zoom_home");
	$V->COM("clear_highlight");
	$V->COM("sel_clear_feat");
	$V->COM("filter_reset,filter_name=popup");
	$V->COM("filter_atr_reset");
	$V->COM("cur_atr_reset");
	$V->COM("affected_layer,name=,mode=all,affected=no");
	$V->COM("clear_layers");
	$V->COM("zoom_refresh");
}

sub valor{
	while ($_[0] or $_){
		$V->COM(shift);
	}
}

sub pop_up{
	$V->PAUSE(shift);
}
