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
use vars qw( $F $JOB $STEP $TMP_DIR $MW $PROGRESS_FOLDER);
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
This script create the rout layer via copy the profile shape, if rout 
layer already exist the script delete it and create a new layer.","create_rout.gif"
);
}
#####################################################################################
# 				Clear and Reset Filters or selections								#
#####################################################################################
clear_and_reset ();
#########################################################################################
# Delete layers of possible previous script run
#########################################################################################
$F->VOF;
	$F->COM("delete_layer,layer=rout");
$F->VON;
#########################################################################################
# Change units to inches
#########################################################################################
$F->COM("units,type=inch");
#########################################################################################
# Create Rout Layer
#########################################################################################
$F->COM("create_layer,layer=rout,context=board,type=rout,polarity=positive,sub_type=,ins_layer=drill");
$F->COM("profile_to_rout,layer=rout,width=1");
#####################################################################################
# 				Clear and Reset Filters or selections								#
#####################################################################################
clear_and_reset ();

write_in_log ("Create Rout");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
create_flag_file ("Create Rout");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
if (($mode eq "silence") or ($mode eq "designers"))
{
	run_next_script ("$mode");
	exit (0);
}
if ($mode eq "interactive")
{
success_run("Script finish successfully!!");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
back_to_menu ("$prev_page");
}
exit (0);

#####################################################################################
#				SUB-RUTINE TO AUTOMATICALLY RUN THE NEXT SCRIPT 					#
#####################################################################################
sub run_next_script
{

if ($mode eq "designers"){
my $script_file_name	= 'netlist.pl';
#$F->PAUSE ("Antes del netlist. Estamos en $mode");
my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Validate_Netlist/" . $script_file_name);
alarm 0;
my $a = $_[0];
system("perl $script $a") or print("NOTE: Script $script_file_name does not exist.","\n");
}

if ($mode eq "silence"){
my $script_file_name	= 'set_cu_weight.pl';
my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Matrix_review/" . $script_file_name);
alarm 0;
my $a = $_[0];
system("perl $script $a") or print("NOTE: Script $script_file_name does not exist.","\n");
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
$MW = new MainWindow;

alarm 60;
$SIG{ALRM} = sub { print "Create rout Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window

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
$MW = new MainWindow;
alarm 60;
$SIG{ALRM} = sub { $MW->destroy();print "Create rout Timeout!\n";}; # trap an alarm and assign a sub to destroy the windo
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

