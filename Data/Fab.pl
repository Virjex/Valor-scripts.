#!perl -w
=begine
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
#	AUTHOR: WW DFx Support Team, AME												#
#			Armando Alberto Garza Lara & Edgar Alfonso Ruiz Arellano				#
#			Samuel Flores															#
#			samuel.flores@flex.com													#			
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

chnage to support the Fab script to help with the perp work of the CAD.

=cut
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
use Sys::Hostname;
use strict;
use Env qw (VALOR_DATA JOB STEP GENESIS_LIB VALOR_DIR VALOR_EDIR VALOR_VER VALOR_HOME VALOR_TMP);
use FileHandle;
use lib ("$FindBin::Bin/../lib","${VALOR_EDIR}/all/perl",dirname(__FILE__).'\..');

use Valor;
use DFM_Util;
use vars qw( $F $JOB $STEP $TMP_DIR $MW $PROGRESS_FOLDER @assytechclassgroup @fabtechclassgroup);
#####################################################################################
=begine

this will be a GUI to have things set-up for the perp work.
using Valor's is a bit impossible but getting the data from a diffrent script could be useful

=cut
#####################################################################################
#									DEFINE VARIABLES								#
#####################################################################################
$JOB				=	$ENV{JOB};
$STEP				=	$ENV{STEP};
$TMP_DIR			=	$ENV{VALOR_TMP};

my $prev_page		=	('Main_Switch_Board_Flex.pl');
my $mode            =   ('interactive');
my $input1	        =   shift;
if ($input1 ne ''){$mode = $input1;}
#----------------- Variables to define the attributes -------------------
my $customer;
my $pcbname;
my $pcbrev;
my $pcbaname;
my $pcbarev;
my @typelist           = ("set_an_option","full","fabrication","designer","pin2pad","placement","compare","panel_array","other");
my $type;
my $reqid;
my @dfmgroups          = ("set_an_option","austin","chennai","dongguan","guadalajara","migdal_haemek","milpitas","multek","penang","ronneby","shanghai","suzhou","timisoara","wuzhong","zala","zhuhai");
my $dfmcenter;
my @engineers          = ("set_an_option","ala a","alagusridhar thangathirupathi","akhil raj","alon shachar","balachandhar s","barak benzvi","barak shmuel","brain ye","celine he","chin siang chin","cora zhang","daniel cinnamond","danny huang","david aguirre","diego gomez","dezhong Han","dragoslav seculici","fing liu","frank perez","gabor nagy","gaode sun","glenn hopper","hakan andersson","harain al sivapragasam","henry wei","henry xie","hua mi","huijun zhang","igor berman","ivan polozov","ivan pelayo","javier medina","jesus tan","kailash madesvaran","kenia rodriguez","kertana ap","kyle ding","lm song","long hu","magical yang","marzafirah marzuki","mauricio mora","michelle stringer","mike he","minhazur rahman","miguel sierra","ml xia","pooi fong kong","ravi singh","rock ji","rohan patil","ryan gibson","sailesh rao","samuel flores","sam wen","samuvel none","sandera bin md","sanoop k","santhosh natarajan","saravanan n","shahar gur ari","sherry cui","sivabalan sukumaran","steve li","sumedh yeshi","ulrick rodin","vaisak v","velmurugan m","venkat m","victor de anda","weijiang huang","xiang cao","xinjian zhang","yair oiberman","yangqiao hu","yarden gal","ye tao","yossi iskov","other");
my $dfmengineer;  
my $assytechclass;
my $fabtechclass;
my @surfinishgroup     = ("set_an_option","enig","hasl","osp","immersion_silver","immersion_tin","other");
my $surfacefinish;
my @bolleanoptions     = ("set_an_option","yes","no");
my $rohs;
my @depmethods         = ("set_an_option","mousebites","v-cut","router","laser","mix-depanelling","no-required","other");
my $depanel;
my $conformal;
my $pasteinhole;
my $underfill;
my $rfmicrou;
my $microvia;
my $s2sjob;
my $attr_value;

my $host = hostname; #dont ask me. this is an artifact from the Global.
 if ($host =~/SUZ/)
 {
 @assytechclassgroup = ("set_an_option","min","std","lff","pwr_mod","sip");
 @fabtechclassgroup  = ("set_an_option","standard","advanced","sip_hvm","sip_lvm","sip_htcc","sip_ltcc");
 }
 else
 {
 @assytechclassgroup = ("set_an_option","min","std","lff","pwr_mod");
 @fabtechclassgroup  = ("set_an_option","standard","advanced");
 }

#######################################################################
	$F->COM("get_job_path,job=$JOB");
	my $JOBPATH = $F->{COMANS};
	my $prefillflag = ($JOBPATH . "/stepS/" .$STEP . "/progress/Set Entity Attribute from inport.txt");
	if (-e $prefillflag )
		{
			if ($mode eq 'silence')
			{
			write_in_log ("Set Entity Attribute");
			create_flag_file ("Set Entity Attribute");
			run_next_script ("$mode");
			exit 0;
			}

		}
		
#####################################################################################
#								DEFINE PROGRESS FOLDER								#
#####################################################################################
DFM_Util::validation();
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
DFM Engineer should fill the information to identify the JOB 
this information will be used to create checklist and excell report.
and set up the Fab settings for this JOB.","entity_attributes.gif"
);
}
#####################################################################################
# 				Clear and Reset Filters or selections								#
#####################################################################################
clear_and_reset ();
# ----------- check for attributes previously set in the job --------
my @attrtobesetlist   = ("_customer","_pcb_fab_number","_pcb_fab_ver","_pcb_assembly_num","_pcb_assembly_ver","_dfm_type","_requisition_id","_dfm_center","_dfm_engineer","_assy_tech_class","_fab_tech_class","_finish","_rohs","_depanelling","_conf_coat","_p_in_hole","_underfill","_rf","_u_via_in_job","_s2s_job");
foreach my $attr2beset (@attrtobesetlist)
	{
		check_attributes ($attr2beset);
	}
######################################################################################
if ($mode eq "silence")
{
	identify_dfmengineer ();
	input_gui ();
	write_in_log ("Set Entity Attribute");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
	create_flag_file ("Set Entity Attribute");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE	
	run_next_script ("$mode");
	exit (0);
}

if ($mode eq "interactive")
{
input_gui ();
write_in_log ("Set Entity Attribute");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
create_flag_file ("Set Entity Attribute");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
success_run("Script finish successfully!!");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
back_to_menu ("$prev_page");
}
exit (0);

#####################################################################################
#				SUB-RUTINE TO CHECK ATTRIBUTE VALUES IN THE JOB						#
#####################################################################################
# get's the art's from the Valor. and set it to the GUI.
sub check_attributes{
my $JOB			=	$ENV{JOB};
my $STEP		=	$ENV{STEP};
my $TMP_DIR		=	$ENV{VALOR_TMP};
my $F			=	new Valor;
my $counter 	= 	0;
my $attr_name   = $_[0];
	#----------------------------------------------------------#
		$F->DO_INFO("-t job -e $JOB -m script -d ATTR -u no");
		foreach my $attr(@{$F->{doinfo}{gATTRname}})
	{
		if ( $attr eq "$attr_name")
		{  
			$attr_value = $F->{doinfo}{gATTRval}[$counter];
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
#####################################################################################
#				SUB-RUTINE TO CREATE THE GUI TO SETTHE INPUT DATA 					#
#####################################################################################
sub input_gui
{
#####
#	
#	the GUI the main this i was here for.
#
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
my $path_color		= ("yellow"); 
my $dfmtype_color	= ("yellow");
my $db_color		= ("yellow");  
my $customer_color	= ("yellow"); 
my $pcba_data_color	= ("DeepSkyBlue2");
my $pcb_data_color	= ("SpringGreen4"); 
my $mode_color      = ("dim grey");
#####################################################################################
#							GUI Main construction									#
#####################################################################################
alarm 300;
$SIG{ALRM} = sub { print "Entity attribute Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
$MW = new MainWindow;
$MW->configure	(-title => $gui_title);
$MW->geometry	("700x800+200+10");
$MW->configure	(-background => $bg_color);
my $image_file_name = 'logo.bmp';

my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
my $icon 			= $MW->Photo(-file => $image);
$MW->idletasks;
$MW->iconimage	($icon);
#############################################################################################################################
# 								GUI Header content
#############################################################################################################################						
	my $first_frame		= $MW->Frame(
									-relief => 'flat',
									-background => $bg_color,
									#-borderwidth => 6
								)
										->pack(
												-side => 'top', 
												-fill => 'x'
												);
	my $lbltitle		= $first_frame->Label(
									-pady => '1', 
									-padx => '1', 
									-relief => 'flat', 
									-state => 'normal', 
									-justify => 'center', 
									-text => 'Please set the JOB Attributes',
									-background => $bg_color,
									-foreground => $fg_color,
									-font => $big_font,
								)
										->pack(
												-side => 'top'
												);
#############################################################################################################################
# 								GUI TOP Center Panel content
#############################################################################################################################
	my $central_frame		= $MW->Scrolled("Frame", -scrollbars => "osoe",	
									-relief		=> 'flat',
									-background	=> $bg_color,
									-borderwidth => 1
									#-height 	=> 30
								)
										->pack(
												-side => 'top', 
												-fill => 'both',
												-padx => 4,
												-pady => 4,
												-expand => 1,
												);
################################################################################################################	
	my $vu_frm01 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb01 = $vu_frm01->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Customer:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	my $vu_en01 = $vu_frm01->Entry(
							-width => 40,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $medium_font,
							-background => $bg_color,
							-foreground => $pcba_data_color,
							-textvariable => \$customer,
							#-validate     => 'key',
							#-vcmd         => \&validate_name,
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );
################################################################################################################	
	my $vu_frm02 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb02 = $vu_frm02->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'DFM Type:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_02  = $vu_frm02->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $dfmtype_color,
										-choices 			=> \@typelist,
										-variable 			=> \$type
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);
################################################################################################################	
	my $vu_frm05 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb05 = $vu_frm05->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Assembly:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	my $vu_en05 = $vu_frm05->Entry(
							-width => 40,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $medium_font,
							-background => $bg_color,
							-foreground => $pcba_data_color,
							-textvariable => \$pcbaname,
							-validate     => 'key',
							-vcmd         => \&validate_name,
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );
################################################################################################################
	my $vu_frm06 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb06 = $vu_frm06->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Assy Rev:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	my $vu_en06 = $vu_frm06->Entry(
							-width => 40,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $medium_font,
							-background => $bg_color,
							-foreground => $pcba_data_color,
							-textvariable => \$pcbarev,
							-validate     => 'key',
							-vcmd         => \&validate_rev,							
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );
################################################################################################################
	my $vu_frm07 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb07 = $vu_frm07->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'PCB #:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

	my $vu_en07 = $vu_frm07->Entry(
							-width => 40,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $medium_font,
							-background => $bg_color,
							-foreground => $pcb_data_color,
							-textvariable => \$pcbname,
							-validate     => 'key',
							-vcmd         => \&validate_name,
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );
################################################################################################################
	my $vu_frm08 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb08 = $vu_frm08->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'PCB Rev:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);
	my $vu_en08 = $vu_frm08->Entry(
							-width => 40,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $medium_font,
							-background => $bg_color,
							-foreground => $pcb_data_color,
							-textvariable => \$pcbrev,
							-validate     => 'key',
							-vcmd         => \&validate_rev,
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );
################################################################################################################
	my $vu_frm09 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb09 = $vu_frm09->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Req ID #:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);
	my $vu_en09 = $vu_frm09->Entry(
							-width => 40,
                             #-background => 'white',
							 -justify	=> 'center',
							-font		=> $medium_font,
							-background => $bg_color,
							-foreground => $fg_color,
							-textvariable => \$reqid,
							#-validate     => 'key',
							#-vcmd         => \&validate_rev,
							   )
								->pack(
										-side => 'right', 
										-pady => 3
									   );
################################################################################################################	
	my $vu_frm10 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb10 = $vu_frm10->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'DFM Center:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_10  = $vu_frm10->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@dfmgroups,
										-variable 			=> \$dfmcenter
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm11 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb11 = $vu_frm11->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'DFM Engineer:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_11  = $vu_frm11->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@engineers,
										-variable 			=> \$dfmengineer
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);
################################################################################################################	
	my $vu_frm12 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb12 = $vu_frm12->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Assy Tech Class:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_12  = $vu_frm12->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@assytechclassgroup,
										-variable 			=> \$assytechclass
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);
################################################################################################################	
	my $vu_frm13 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb13 = $vu_frm13->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Fab Tech Class:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_13  = $vu_frm13->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@fabtechclassgroup,
										-variable 			=> \$fabtechclass
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm14 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb14 = $vu_frm14->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Surface Finish:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_14  = $vu_frm14->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@surfinishgroup,
										-variable 			=> \$surfacefinish
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm15 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb15 = $vu_frm15->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Is ROHS ? :',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_15  = $vu_frm15->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@bolleanoptions ,
										-variable 			=> \$rohs
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
###############################################################################################################################	
	my $vu_frm16 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb16 = $vu_frm16->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Depaneling Method:',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_16  = $vu_frm16->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@depmethods,
										-variable 			=> \$depanel
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm17 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb17 = $vu_frm17->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Conformal Coating ? :',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_17  = $vu_frm17->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@bolleanoptions ,
										-variable 			=> \$conformal
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm18 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb18 = $vu_frm18->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Paste in Hole ? :',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_18  = $vu_frm18->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@bolleanoptions ,
										-variable 			=> \$pasteinhole
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm19 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb19 = $vu_frm19->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Underfill ? :',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_19  = $vu_frm19->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@bolleanoptions ,
										-variable 			=> \$underfill
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm20 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb20 = $vu_frm20->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'RF Microwave ? :',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_20  = $vu_frm20->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@bolleanoptions ,
										-variable 			=> \$rfmicrou
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm21 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb21 = $vu_frm21->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Micro vias ? :',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_21  = $vu_frm21->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@bolleanoptions ,
										-variable 			=> \$microvia
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################	
	my $vu_frm22 = $central_frame->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top', 
									-fill => 'x'
									);

	my $vu_lb22 = $vu_frm22->Label(
								-width      => 18,
								-pady		=> '1',
								-relief		=> 'flat', 
								-padx		=> '1', 
								-state		=> 'normal', 
								-justify	=> 'right', 
								-text		=> 'Sketch to Scale JOB? :',
								-font		=> $medium_font,
								-background	=> $bg_color,
								-foreground	=> $fg_color,
								)
									->pack(
											-side => 'left'
											);

#############################################################################################################################
# 						Drop down list			
#############################################################################################################################															

		my $list_22  = $vu_frm22->BrowseEntry( 
										-width              => 40,
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $medium_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices 			=> \@bolleanoptions ,
										-variable 			=> \$s2sjob
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);	
################################################################################################################

################################################################################################################
	my $vu_frm99 = $MW->Frame(
							-relief => 'groove',
							-background => $bg_color,
							)
							->pack(
									-side => 'top',
									-fill => 'x',									
									#-fill => 'y',
									);

	my $vu_butnext99 = $vu_frm99->Button(
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
									#-command			=> [$MW => 'destroy']
									-command			=>sub{
																set_job_attributes();
																$MW->destroy();
																},

									)
										->pack(
												-side => 'right',
												-fill => 'y',
												-fill => 'x'
												);

	my $vu_butcancel99 = $vu_frm99->Button(
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
#					SUB-RUTINE TO CREATE ERROR POPUP								#
#####################################################################################
# will be useful to have on the other script to set the attributes to the job.
#gonnna need 1 to set up att's into the job and one to pull data from the JOB. 
sub set_job_attributes
{
	
	# btw all this re-declation are useless due to those var's are global with in the script. no issue of scopping
$JOB			=	$ENV{JOB};
$STEP			=	$ENV{STEP};
$F				=	new Valor;
#assign attributes--------
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_customer,value=$customer");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_pcb_fab_number,value=$pcbname");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_pcb_fab_ver,value=$pcbrev");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_pcb_assembly_num,value=$pcbaname");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_pcb_assembly_ver,value=$pcbarev");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_dfm_type,value=$type");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_job_complexity,value=low");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_requisition_id,value=$reqid");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_dfm_center,value=$dfmcenter");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_dfm_engineer,value=$dfmengineer");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_assy_tech_class,value=$assytechclass");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_fab_tech_class,value=$fabtechclass");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_finish,value=$surfacefinish");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_rohs,value=$rohs");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_depanelling,value=$depanel");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_conf_coat,value=$conformal");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_p_in_hole,value=$pasteinhole");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_underfill,value=$underfill");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_rf,value=$rfmicrou");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_u_via_in_job,value=$microvia");
$F->COM("set_attribute,type=job,job=$JOB,name1=,name2=,name3=,attribute=_s2s_job,value=$s2sjob");
}
#####################################################################################
#				SUB-RUTINE TO IDENTIFY USERS 										#
#####################################################################################
sub identify_dfmengineer
# what da hell???
# this will get cut out
{
my $userid     = $ENV{USERNAME};

if ($userid =~ /(aurghopp)/ ) { $dfmengineer         = ("glenn hopper");             $dfmcenter =("austin"); }
if ($userid =~ /(aurmmuel)/ ) { $dfmengineer         = ("michelle stringer");        $dfmcenter =("austin"); }
if ($userid =~ /(aurfpere)/ ) { $dfmengineer         = ("frank perez");  		     $dfmcenter =("austin"); }
if ($userid =~ /(aurdcinn)/ ) { $dfmengineer         = ("daniel cinnamond");  		 $dfmcenter =("austin"); }
if ($userid =~ /(aurrygib)/ ) { $dfmengineer         = ("ryan gibson");  		 $dfmcenter =("austin"); }

if ($userid =~ /(gdlarmga)/ ) { $dfmengineer         = ("armando garza");            $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdjjmedi)/ ) { $dfmengineer         = ("javier medina");            $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdldigom)/ ) { $dfmengineer         = ("diego gomez");              $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdlkenro)/ ) { $dfmengineer         = ("kenia rodriguez");          $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdlmaumo)/ ) { $dfmengineer         = ("mauricio mora");            $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdlvdea)/ )  { $dfmengineer         = ("victor de anda");           $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdlsamfl)/ ) { $dfmengineer         = ("samuel flores");            $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdlaglui)/ ) { $dfmengineer         = ("david aguirre");            $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdlmsier)/ ) { $dfmengineer         = ("miguel sierra");            $dfmcenter =("guadalajara"); }
if ($userid =~ /(gdjipela)/ ) { $dfmengineer         = ("ivan pelayo");              $dfmcenter =("guadalajara"); }

if ($userid =~ /(migalsha)/ ) { $dfmengineer         = ("alon shachar");             $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migyoibe)/ ) { $dfmengineer         = ("yair oiberman");            $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migiberm)/ ) { $dfmengineer         = ("igor berman");              $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migbshmu)/ ) { $dfmengineer         = ("barak shmuel");             $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migbbenz)/ ) { $dfmengineer         = ("barak benzvi");             $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migyagal)/ ) { $dfmengineer         = ("yarden gal");               $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migsgura)/ ) { $dfmengineer         = ("shahar gur ari");           $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migyisko)/ ) { $dfmengineer         = ("yossi iskov");              $dfmcenter =("migdal_haemek"); }
if ($userid =~ /(migipolo)/ ) { $dfmengineer         = ("ivan polozov");             $dfmcenter =("migdal_haemek"); }


if ($userid =~ /(mlgmrahm)/ ) { $dfmengineer         = ("minhazur rahman");          $dfmcenter =("milpitas"); }


if ($userid =~ /(knaurodi)/ ) { $dfmengineer         = ("ulrick rodin");             $dfmcenter =("ronneby"); }
if ($userid =~ /(knahande)/ ) { $dfmengineer         = ("hakan andersson");          $dfmcenter =("ronneby"); }

if ($userid =~ /(timdsecu)/ ) { $dfmengineer         = ("dragoslav seculici");       $dfmcenter =("timisoara"); }

if ($userid =~ /(zaljfulo)/ ) { $dfmengineer         = ("jozsef fulop");             $dfmcenter =("zala"); }

if ($userid =~ /(pnakapka)/ ) { $dfmengineer         = ("kertana ap");               $dfmcenter =("penang"); }
if ($userid =~ /(pnamamar)/ ) { $dfmengineer         = ("marzafirah marzuki");       $dfmcenter =("penang"); }
if ($userid =~ /(pnapkong)/ ) { $dfmengineer         = ("pooi fong kong");           $dfmcenter =("penang"); }
if ($userid =~ /(pnasanmd)/ ) { $dfmengineer         = ("sandera bin md");           $dfmcenter =("penang"); }
if ($userid =~ /(pnachins)/ ) { $dfmengineer         = ("chin siang chin");          $dfmcenter =("penang"); }
if ($userid =~ /(pnahsiva)/ ) { $dfmengineer         = ("harain al sivapragasam");   $dfmcenter =("penang"); }
if ($userid =~ /(pnassuku)/ ) { $dfmengineer         = ("sivabalan sukumaran");      $dfmcenter =("penang"); }

if ($userid =~ /(suzcorzh)/ ) { $dfmengineer         = ("cora zhang");               $dfmcenter =("suzhou"); }
if ($userid =~ /(suzhewei)/ ) { $dfmengineer         = ("henry wei");                $dfmcenter =("suzhou"); }
if ($userid =~ /(suzscui)/ )  { $dfmengineer         = ("sherry cui");               $dfmcenter =("suzhou"); }
if ($userid =~ /(suzyetao)/ ) { $dfmengineer         = ("ye tao");                   $dfmcenter =("suzhou"); }
if ($userid =~ /(suzhexie)/ ) { $dfmengineer         = ("henry xie");                $dfmcenter =("suzhou"); }
if ($userid =~ /(suzrocji)/ ) { $dfmengineer         = ("rock ji");                  $dfmcenter =("suzhou"); }
if ($userid =~ /(suzdehan)/ ) { $dfmengineer         = ("dezhong Han");              $dfmcenter =("suzhou"); }
if ($userid =~ /(suzsawen)/ ) { $dfmengineer         = ("sam wen");                  $dfmcenter =("suzhou"); }

if ($userid =~ /(wuzkydin)/ ) { $dfmengineer         = ("kyle ding");                $dfmcenter =("wuzhong"); }
if ($userid =~ /(wuzmxia)/ )  { $dfmengineer         = ("ml xia");                   $dfmcenter =("wuzhong"); }
if ($userid =~ /(wuzmyang)/ )  { $dfmengineer        = ("magical yang");             $dfmcenter =("wuzhong"); }
if ($userid =~ /(wuzxiaca)/ )  { $dfmengineer        = ("xiang cao");                $dfmcenter =("wuzhong"); }
if ($userid =~ /(wuzbraye)/ )  { $dfmengineer        = ("brain ye");                 $dfmcenter =("wuzhong"); }
if ($userid =~ /(wuzlongh)/ )  { $dfmengineer        = ("long hu");                  $dfmcenter =("wuzhong"); }
if ($userid =~ /(wuzhmi)/ )   { $dfmengineer         = ("hua mi");                   $dfmcenter =("wuzhong"); }

if ($userid =~ /(dmnqiahe)/ ) { $dfmengineer         = ("celine he");                $dfmcenter =("zhuhai"); }
if ($userid =~ /(dmndahua)/ ) { $dfmengineer         = ("danny huang");       	     $dfmcenter =("zhuhai"); }
if ($userid =~ /(dmnfinli)/ ) { $dfmengineer         = ("fing liu");                 $dfmcenter =("zhuhai"); }
if ($userid =~ /(dmnujjni)/ ) { $dfmengineer         = ("jianfeng zhu");             $dfmcenter =("zhuhai"); }
if ($userid =~ /(dmnraara)/ ) { $dfmengineer         = ("ranilo aranda");            $dfmcenter =("zhuhai"); }
if ($userid =~ /(dmnsteli)/ ) { $dfmengineer         = ("steve li");         	     $dfmcenter =("zhuhai"); }
if ($userid =~ /(dmnwjhua)/ ) { $dfmengineer         = ("weijiang huang");           $dfmcenter =("zhuhai"); }
if ($userid =~ /(dmnxjzha)/ ) { $dfmengineer         = ("xinjian zhang");            $dfmcenter =("zhuhai"); }

if ($userid =~ /(jidmheaa)/ ) { $dfmengineer         = ("mike he");              	 $dfmcenter =("shanghai");}
if ($userid =~ /(jidgasun)/ ) { $dfmengineer         = ("gaode sun");              	 $dfmcenter =("shanghai");}
if ($userid =~ /(jidyanhu)/ ) { $dfmengineer         = ("yangqiao hu");            	 $dfmcenter =("shanghai");}

if ($userid =~ /(gssvelmm)/ ) { $dfmengineer         = ("velmurugan m");          	 $dfmcenter =("chennai");}
if ($userid =~ /(gsssaira)/ ) { $dfmengineer         = ("sailesh rao");            	 $dfmcenter =("chennai");}
if ($userid =~ /(gssakraj)/ ) { $dfmengineer         = ("akhil raj");            	 $dfmcenter =("chennai");}
if ($userid =~ /(gsssanok)/ ) { $dfmengineer         = ("sanoop k");            	 $dfmcenter =("chennai");}
if ($userid =~ /(gssvenka)/ ) { $dfmengineer         = ("venkat m");            	 $dfmcenter =("chennai");}
if ($userid =~ /(gsssnone)/ ) { $dfmengineer         = ("samuvel none");           	 $dfmcenter =("chennai");}
if ($userid =~ /(gsskmade)/ ) { $dfmengineer         = ("kailash madesvaran");     	 $dfmcenter =("chennai");}
if ($userid =~ /(gsssknat)/ ) { $dfmengineer         = ("santhosh natarajan");     	 $dfmcenter =("chennai");}
if ($userid =~ /(gssalava)/ ) { $dfmengineer         = ("ala a");   			  	 $dfmcenter =("chennai");}
if ($userid =~ /(gssaabha)/ ) { $dfmengineer         = ("balachandhar s");			 $dfmcenter =("chennai");}
if ($userid =~ /(punrasin)/ ) { $dfmengineer         = ("ravi singh");           	 $dfmcenter =("chennai");}
if ($userid =~ /(gssvaisv)/ ) { $dfmengineer         = ("vaisak v");          	 	 $dfmcenter =("chennai");}
if ($userid =~ /(gssaltha)/ ) { $dfmengineer         = ("alagusridhar thangathirupathi"); $dfmcenter =("chennai");}
if ($userid =~ /(punsyesh)/ ) { $dfmengineer         = ("sumedh yeshi");           	 $dfmcenter =("chennai");}
if ($userid =~ /(punrocha)/ ) { $dfmengineer         = ("rohan chandrakant");      	 $dfmcenter =("chennai");}
if ($userid =~ /(gssnsara)/ ) { $dfmengineer         = ("saravanan n");            	 $dfmcenter =("chennai");}

if ($userid =~ /(donlmson)/ ) { $dfmengineer         = ("lm song");      	     	 $dfmcenter =("dongguan");}
if ($userid =~ /(donfhuzh)/ ) { $dfmengineer         = ("huijun zhang");           	 $dfmcenter =("dongguan");}

if ($userid =~ /(david arivett)/ ) { $dfmengineer    = ("aurdariv");                 $dfmcenter =("multek"); }
if ($userid =~ /(allen zhao)/ ) { $dfmengineer       = ("mcnalzha");                 $dfmcenter =("multek"); }
if ($userid =~ /(Kitkid Yang)/ ) { $dfmengineer      = ("mcnkikiy");                 $dfmcenter =("multek"); }
if ($userid =~ /(russell schirmer)/ ) { $dfmengineer = ("sjcrschi");                 $dfmcenter =("multek"); }
if ($userid =~ /(todd robinson)/ ) { $dfmengineer    = ("sjctrobi");                 $dfmcenter =("multek"); }

if ($userid =~ /(kanbflan)/ ) { $dfmengineer         = ("brian flanagan");           $dfmcenter =("kanata");}
if ($userid =~ /(kaneharp)/ ) { $dfmengineer         = ("eric harper");              $dfmcenter =("kanata");}

}

#####################################################################################
#				SUB-RUTINE TO VALIDATE THE GUI ENTRY  PCB OR PCBA NAME 				#
#####################################################################################
sub validate_name
{
  my $val = shift;
  my $list1 =('+.,!@\#$%^&*():?;\/|=`~\[\]\<>"\'{}');
  if( $val =~ /([A-Z])/ ){ return 0 }
  if( $val =~ /([' '])/ ){ return 0 }
  if( $val =~ /(['\\'])/ ){ return 0 }
  if( $val =~ /(["$list1"])/ ){ return 0 }
  if( $val =~ /^[a-z0-9-_]{20,100}$/ ){ return 0 }
  else{ return 1 }
  
}

#####################################################################################
#				SUB-RUTINE TO VALIDATE THE GUI ENTRY  PCB REV or PCBA REV			#
#####################################################################################
sub validate_rev
{
  my $val = shift;
  my $list1 =('+.,!@\#$%^&*():?;\/|=`~\[\]\<>"\'{}');
  if( $val =~ /([A-Z])/ ){ return 0 }
  if( $val =~ /([' '])/ ){ return 0 }
  if( $val =~ /(['\\'])/ ){ return 0 }
  if( $val =~ /(["$list1"])/ ){ return 0 }
  if( $val =~ /^[a-z0-9-_]{10,100}$/ ){ return 0 }
  else{ return 1 }
}

#####################################################################################
#				SUB-RUTINE TO AUTOMATICALLY RUN THE NEXT SCRIPT 					#
#####################################################################################
sub run_next_script
{
	my $script_file_name	= 'netlist.pl';
	my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Validate_Netlist/" . $script_file_name);
	alarm 0;
	my $a = $_[0];
	system("perl $script $a") or print("NOTE: Script $script_file_name does not exist.","\n");
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
#my $F				= new Valor;
#----------------------GUI Main construction----------------------------------------
alarm 60;
$SIG{ALRM} = sub { print "Entity Attribute Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
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
$SIG{ALRM} = sub { $MW->destroy();print "Entity Attribute Inactivity Timeout!\n";}; # trap an alarm and assign a sub to destroy the window
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
alarm 0;
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

