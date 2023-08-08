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
use Env qw (VALOR_DATA JOB STEP GENESIS_LIB VALOR_DIR VALOR_EDIR VALOR_VER VALOR_HOME VALOR_TMP);
use lib ("$FindBin::Bin/../lib","${VALOR_EDIR}/all/perl",);
use Valor;
use vars qw( $checklist_name $checklist_type $F $JOB $STEP $TMP_DIR $MW $PROGRESS_FOLDER);
#####################################################################################

#####################################################################################
#									DEFINE VARIABLES								#
#####################################################################################
$JOB				=	$ENV{JOB};
$STEP				=	$ENV{STEP};
$TMP_DIR			=	$ENV{VALOR_TMP};
$F					=	new Valor;
$checklist_name	= ('');
$checklist_type	= ('');
my $prev_page		=	('Clean_up_menu.pl');
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
my $from_library = ("no");
my $selected_checklist;
my @checklist_group;
#########################################################################################
read_checklist_folder();
guiselector ();

	#	ask_source_cleanup_checklist();
	#		if ($from_library eq 'yes')	
	#		{
	#		define_checklist_to_run();
	#		}
	#		if ($from_library eq 'no')
	#		{
			
	#		}


write_in_log ("Create cleanup checklist $checklist_name");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
create_flag_file ("Cleanup $checklist_type");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
create_flag_file ("Run Cleanup Checklist");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
	if ($mode eq 'interactive')
	{
	#	success_run("Script finish successfully!!");	#PLEASE ADD THE ARGUMENTS FOR THE SUBRUTINE
		$F->VOF;
		$F->COM("chklist_close,chklist=$checklist_name");
		$F->VON;
	}

exit (0);
#####################################################################################
#				SUB-RUTINE TO AUTOMATICALLY RUN THE NEXT SCRIPT 					#
#####################################################################################
sub run_next_script
{
my $script_file_name	= 'toeprint_assign.pl';
my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Clean_up_execution/" . $script_file_name);
alarm 0;
my $a = $_[0];
system("perl $script $a") or print("NOTE: Script $script_file_name does not exist.","\n");
}	
#####################################################################################
#					SUB-RUTINE TO RUN NEXT SCRIPT									#
#####################################################################################	
sub run_embeded_script 
{
my $script_file_name	= $_[0];
my $script				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Clean_up_execution/" . $script_file_name);
alarm 0;
my $a = $mode;
my $b = $_[1];
system("perl $script $a $b") or print("NOTE: Script $script can not run.","\n");
}
#####################################################################################
#					SUB-RUTINE TO CREATE THE GUI									#
#####################################################################################
sub guiselector
{
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
	
	

#############################################################################################################################
# 								GUI SCRIPTS  Variables
#############################################################################################################################	
my	$script_01	=	'Cleanup EDA';
my	$script_02	=	'Cleanup GERBER';
my	$script_03	=	'Cleanup HDI';
#############################################################################################################################
# 								FLAG FILES
#############################################################################################################################	
my	$flag_01	= ($PROGRESS_FOLDER . "/" . $script_01 . ".txt");
my	$flag_02	= ($PROGRESS_FOLDER . "/" . $script_02 . ".txt");
my	$flag_03	= ($PROGRESS_FOLDER . "/" . $script_03 . ".txt");
#############################################################################################################################
# 								GUI IMAGE  Variables
#############################################################################################################################	
	my $pending_image_file_name	= 'background.bmp';
	my $pending_image			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $pending_image_file_name);
	my $check_image_file_name	= 'check_mark.bmp';
	my $check_image				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $check_image_file_name);
#############################################################################################################################
# 								GUI Main construction
#############################################################################################################################	
	alarm 60;
	$SIG{ALRM} = sub { print "CleanUp chk menu Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
	$MW = new MainWindow;
	$MW->configure	(-title => $gui_title);
	$MW->geometry	("+200+50");
	$MW->configure	(-background => $bg_color);
	my $image_file_name = 'logo.bmp';
	my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
	my $icon 			= $MW->Photo(-file => $image);
	$MW->idletasks;        # this line is crucial
	$MW->iconimage	($icon);
	my $balloon = $MW->Balloon();	
#############################################################################################################################
# 								GUI Header content
#############################################################################################################################						
	my $vu_frm0		= $MW->Frame(
									-relief => 'flat',
									-background => $bg_color,
									#-borderwidth => 6
								)
										->pack(
												-side => 'top', 
												-fill => 'x'
												);
												
												
	my $vu_lb000		= $vu_frm0->Label(
									-pady => '1', 
									-padx => '1', 
									-relief => 'flat', 
									-state => 'normal', 
									-justify => 'center', 
									-text => '          Working Job :          ',
									-background => $bg_color,
									-foreground => $fg_color,
									-font => $big_font,
								)
										->pack(
												-side => 'top'
												);

	my $vu_lb00			= $vu_frm0->Label(
									-pady => '1', 
									-padx => '1', 
									-relief => 'flat', 
									-state => 'normal', 
									-justify => 'center', 
									-text => $JOB,
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
	my $central_frame		= $MW->Frame(
									-relief		=> 'flat',
									-background	=> $bg_color,
									-borderwidth => 1
								)
										->pack(
												-side => 'top', 
												-fill => 'x',
												-padx => 4,
												-pady => 4
												);
	my $vu_lb0		= $central_frame->Label(
									-pady		=> '1', 
									-relief		=> 'flat', 
									-padx		=> '1', 
									-state		=> 'normal', 
									-justify	=> 'center', 
									-text		=> 'CLEANUP MANAGMENT MENU',
									-font		=> $medium_font,
									-background	=> $bg_color,
									-foreground	=> $shadow_color,
									)
										->pack(
												-side => 'top',
												-pady => 3
												);

#############################################################################################################################
# 								GUI Center Panel content
#############################################################################################################################
	my $main_frame		= $central_frame->Frame(
									-relief		=> 'flat',
									-background	=> $fg_color,
									-borderwidth => 1
								)
										->pack(
												-side => 'top', 
												-fill => 'x',
												-padx => 2,
												-pady => 2
												);
#############################################################################################################################
# 								SCRIPT 01
#############################################################################################################################

	my $vu_frm01		= $main_frame->Frame(
											#-relief => 'flat',
											-background => $bg_color,
											#-borderwidth => 2
											)
												->pack(
														-side => 'top', 
														-fill => 'x',
														#-padx => 4,
														#-pady => 4
														);


if (-e $flag_01)	{
					
																		
					my $mark_01		= $vu_frm01->Photo(-file => $check_image);
					my $chk_btn01	= $vu_frm01->Label(
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
														-image		=> $mark_01	,
														
														)
															->pack(
																	-side => 'left',
																	-padx => 1,
																	-pady => 1
																	);	
					$balloon->attach($chk_btn01, 	-balloonmsg => "Completion status is set \n automatically when script finish.",
													-initwait => 5,
													-balloonposition => 'widget');
					}
			else 	{
					
					
					my $mark_01		= $vu_frm01->Photo(-file => $pending_image);
					my $chk_btn01	= $vu_frm01->Label(
														-pady 				=> '1', 
														-relief 			=> 'flat', 
														-padx 				=> '1', 
														#-state 				=> 'normal', 
														-justify 			=> 'left', 
														#-text 				=> $stage_01,
														#-font 				=> $medium_font,
														-background 		=> $bg_color,
														#-foreground 		=> $fg_color,
														#-activebackground	=> $hgt_color,
														#-activeforeground	=> $hgt_color,
														-image		=> $mark_01	,
														
														)
															->pack(
																	-side => 'left',
																	-padx => 1,
																	-pady => 1
																	);		
					$balloon->attach($chk_btn01, 	-balloonmsg => "Completion status is set \n automatically when script finish.",
													-initwait => 5,
													-balloonposition => 'widget');
					}
														
												
	my $lbl_btn01	= $vu_frm01->Button( 
											-pady 				=> '1', 
											-relief 			=> 'flat', 
											-padx 				=> '1', 
											-state 				=> 'normal', 
											-justify 			=> 'left', 
											-text 				=> $script_01,
											-font 				=> $medium_font,
											-background 		=> $bg_color,
											-foreground 		=> $fg_color,
											-activebackground	=> $bg_color,
											-activeforeground	=> $hgt_color,
											-command			=> sub	{main('cleanup_eda','EDA')}
											)
													->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);

#############################################################################################################################
# 								SCRIPT 02
#############################################################################################################################

	my $vu_frm02		= $main_frame->Frame(
											#-relief => 'flat',
											-background => $bg_color,
											#-borderwidth => 2
											)
												->pack(
														-side => 'top', 
														-fill => 'x',
														#-padx => 4,
														#-pady => 4
														);

if (-e $flag_02)	{
					
																		
					my $mark_02		= $vu_frm02->Photo(-file => $check_image);
					my $chk_btn02	= $vu_frm02->Label(
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
														-image		=> $mark_02	,
														
														)
															->pack(
																	-side => 'left',
																	-padx => 1,
																	-pady => 1
																	);	
					$balloon->attach($chk_btn02, 	-balloonmsg => "Completion status is set \n automatically when script finish.",
													-initwait => 5,
													-balloonposition => 'widget');
					}
			else 	{
					
					
					my $mark_02		= $vu_frm02->Photo(-file => $pending_image);
					my $chk_btn02	= $vu_frm02->Label(
														-pady 				=> '1', 
														-relief 			=> 'flat', 
														-padx 				=> '1', 
														#-state 				=> 'normal', 
														-justify 			=> 'left', 
														#-text 				=> $stage_01,
														#-font 				=> $medium_font,
														-background 		=> $bg_color,
														#-foreground 		=> $fg_color,
														#-activebackground	=> $hgt_color,
														#-activeforeground	=> $hgt_color,
														-image		=> $mark_02	,
														
														)
															->pack(
																	-side => 'left',
																	-padx => 1,
																	-pady => 1
																	);		
					$balloon->attach($chk_btn02, 	-balloonmsg => "Completion status is set \n automatically when script finish.",
													-initwait => 5,
													-balloonposition => 'widget');
					}
					
	my $lbl_btn02	= $vu_frm02->Button( 
											-pady 				=> '1', 
											-relief 			=> 'flat', 
											-padx 				=> '1', 
											-state 				=> 'normal', 
											-justify 			=> 'left', 
											-text 				=> $script_02,
											-font 				=> $medium_font,
											-background 		=> $bg_color,
											-foreground 		=> $fg_color,
											-activebackground	=> $bg_color,
											-activeforeground	=> $hgt_color,
											-command			=> sub	{main('cleanup_gerber','GERBER')}
											)
													->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);
															
#############################################################################################################################
# 								SCRIPT 03
#############################################################################################################################

	my $vu_frm03		= $main_frame->Frame(
											#-relief => 'flat',
											-background => $bg_color,
											#-borderwidth => 2
											)
												->pack(
														-side => 'top', 
														-fill => 'x',
														#-padx => 4,
														#-pady => 4
														);

if (-e $flag_03)	{
					
																		
					my $mark_03		= $vu_frm03->Photo(-file => $check_image);
					my $chk_btn03	= $vu_frm03->Label(
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
														-image		=> $mark_03	,
														
														)
															->pack(
																	-side => 'left',
																	-padx => 1,
																	-pady => 1
																	);	
					$balloon->attach($chk_btn03, 	-balloonmsg => "Completion status is set \n automatically when script finish.",
													-initwait => 5,
													-balloonposition => 'widget');
					}
			else 	{
					
					
					my $mark_03		= $vu_frm03->Photo(-file => $pending_image);
					my $chk_btn03	= $vu_frm03->Label(
														-pady 				=> '1', 
														-relief 			=> 'flat', 
														-padx 				=> '1', 
														#-state 				=> 'normal', 
														-justify 			=> 'left', 
														#-text 				=> $stage_01,
														#-font 				=> $medium_font,
														-background 		=> $bg_color,
														#-foreground 		=> $fg_color,
														#-activebackground	=> $hgt_color,
														#-activeforeground	=> $hgt_color,
														-image		=> $mark_03	,
														
														)
															->pack(
																	-side => 'left',
																	-padx => 1,
																	-pady => 1
																	);		
					$balloon->attach($chk_btn03, 	-balloonmsg => "Completion status is set \n automatically when script finish.",
													-initwait => 5,
													-balloonposition => 'widget');
					}
					
	my $lbl_btn03	= $vu_frm03->Button( 
											-pady 				=> '1', 
											-relief 			=> 'flat', 
											-padx 				=> '1', 
											-state 				=> 'normal', 
											-justify 			=> 'left', 
											-text 				=> $script_03,
											-font 				=> $medium_font,
											-background 		=> $bg_color,
											-foreground 		=> $fg_color,
											-activebackground	=> $bg_color,
											-activeforeground	=> $hgt_color,
											-command			=> sub	{main('cleanup_hdi','HDI')}
											)
													->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);															
#############################################################################################################################
# 								GUI BOTTOM Panel content
#############################################################################################################################

	my $vu_lastfrm		= $MW->Frame(
										-background => $bg_color,
									)
										->pack(
												-side => 'bottom', 
												-fill => 'x',
												);	
				
	my $rtn_btn01		=$vu_lastfrm->Button( 
												-pady				=> '1',										
												-relief				=> 'raised', 
												-padx				=> '1', 
												-state				=> 'normal', 
												-justify			=> 'center', 
												-background			=> $btnbody_color,
												-activebackground	=> $hgt_color,
												-foreground			=> $bg_color,
												-font				=> $small_font,
												-text				=> 'RETURN',
												-command			=> \&return_to_main
											)
													->pack(
															-side => 'left', 
															-fill => 'y', 
															-fill => 'x'
															);
						
	my $quit_btn01		=$vu_lastfrm->Button(
												-pady				=> '1', 
												-relief				=> 'raised', 
												-padx				=> '1', 
												-state				=> 'normal', 
												-justify			=> 'center', 
												-background			=> $btnbody_color,
												-activebackground	=> $exit_color,
												-foreground			=> $bg_color,
												-font				=> $small_font,
												-text				=> 'EXIT',
												-command			=>sub{exit(0)},
											)
													->pack(
															-side => 'right', 
															-fill => 'y', 
															-fill => 'x'
															);
						
	MainLoop;
}		
#####################################################################################
#					SUB-RUTINE TO CREATE THE CHECKLIST								#
#####################################################################################	
sub main 
{
$MW->destroy();
alarm 0;
$checklist_name	= $_[0];
$checklist_type	= $_[1];

	$F->VOF;
	$F->COM("chklist_open, chklist=$checklist_name");
	my $STAT = $F->{STATUS};
	$F->VON;


	if ($STAT != 0) 
		{
		 $F->COM("chklist_from_lib,chklist=$checklist_name");
		 $F->COM("chklist_open, chklist=$checklist_name");
		 #$F->PAUSE("Make any changes necessary to the checklist and press CONTINUE SCRIPT when finished.");
		 $F->COM("chklist_run,chklist=$checklist_name,nact=s,area=profile");
		 #$F->PAUSE("$checklist_name has finished processing.");

		}
	else
		{
		   $F->PAUSE("WARNING: $checklist_name already has results. CONTINUE SCRIPT will delete results.");
		   $F->COM("chklist_delete,chklist=$checklist_name");
		   $F->COM("chklist_from_lib,chklist=$checklist_name");
		   $F->COM("chklist_open,chklist=$checklist_name");
		   $F->COM("chklist_show,chklist=$checklist_name");
		   #$F->PAUSE("Make any changes necessary to the checklist and press CONTINUE SCRIPT when finished.");
		   $F->COM("chklist_run,chklist=$checklist_name,nact=s,area=profile");
		   #$F->PAUSE("$checklist_name has finished processing.");
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
alarm 60;
$SIG{ALRM} = sub { print "CleanUp chk menua Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
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
$SIG{ALRM} = sub { $MW->destroy();print "CleanUp chk menu Inactivity Timeout!\n";}; # trap an alarm and assign a sub to destroy the window
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
# 				SUBRUTINE TO ASK IF USER NEEDS TO IMPORT A BOM						#
#####################################################################################
sub ask_source_cleanup_checklist
{

	#############################################################################################################################
	# 								GUI FORMAT  Variables
	#############################################################################################################################
		my $gui_title		= ("Flex Global DFM Tools Development");	
		my $bg_color		= ("black");
		my $fg_color		= ("white");
		my $shadow_color	= ("grey50");
		my $hgt_color		= ("orange");
		my $btnbody_color	= ("dark grey");
		my $exit_color		= ("red");
		my $big_font		= ("Helvetica 18 italic bold");
		my $medium_font		= ("Helvetica 12 italic");
		my $small_font		= ("Helvetica 10 italic");
	#############################################################################################################################
	# 								GUI Main construction
	#############################################################################################################################	
		alarm 60;
		$SIG{ALRM} = sub { print "CleanUp chk menu Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
		$MW = new MainWindow;
		$MW->configure	(	-title => $gui_title);
		$MW->geometry	("+200+50");
		$MW->configure	(-background => $bg_color);
		my $image_file_name = 'logo.bmp';
		my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
		my $icon 			= $MW->Photo(-file => $image);
		$MW->idletasks;        # this line is crucial
		$MW->iconimage	($icon);
		my $balloon = $MW->Balloon();
	#############################################################################################################################
	# 								GUI Header content
	#############################################################################################################################						
		my $vu_frm0		= $MW->Frame(
										-relief => 'flat',
										-background => $bg_color,
										#-borderwidth => 6
									)
											->pack(
													-side => 'top', 
													-fill => 'x'
													);
													
		my $vu_lb000		= $vu_frm0->Label(
										-pady => '1', 
										-padx => '1', 
										-relief => 'flat', 
										-state => 'normal', 
										-justify => 'center', 
										-text => "What Checklist you want to create ??",
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
		my $central_frame		= $MW->Frame(
										-relief		=> 'flat',
										-background	=> $bg_color,
										-borderwidth => 1
									)
											->pack(
													-side => 'top', 
													-fill => 'x',
													-padx => 4,
													-pady => 4
													);
												
	#############################################################################################################################
	# 								GUI Center Panel content
	#############################################################################################################################
		#my $main_frame		= $central_frame->Frame(
		my $main_frame		= $MW->Frame(
										-relief		=> 'flat',
										-background	=> $fg_color,
										-borderwidth => 1
									)
											->pack(
													-side => 'top', 
													-fill => 'x',
													-padx => 2,
													-pady => 2
													);

	#############################################################################################################################
	# 						Option Button 01			
	#############################################################################################################################															

						my $chk_btn01	= $main_frame->Button(
															-width 				=> 20,
															-pady 				=> '1', 
															-relief 			=> 'raised', 
															-padx 				=> '1', 
															-state 				=> 'normal', 
															-justify 			=> 'center', 
															-text 				=> 'FROM LIBRARY',
															-font 				=> $big_font,
															-background 		=> $bg_color,
															-foreground 		=> $fg_color,
															-activebackground	=> $hgt_color,
															#-activeforeground	=> $hgt_color,
															#-image		=> $mark_01	,
															#-variable 			=> \$response,
															-command	=> sub {set_properly_source ('yes');$MW->destroy();alarm 0;},
															)
																->pack(
																		-side => 'left',
																		-padx => 1,
																		-pady => 1
																		);
	#############################################################################################################################
	# 						Option Button 02			
	#############################################################################################################################															
						my $chk_btn02	= $main_frame->Button(
															-width 				=> 20,
															-pady 				=> '1', 
															-relief 			=> 'raised', 
															-padx 				=> '1', 
															-state 				=> 'normal', 
															-justify 			=> 'center', 
															-text 				=> 'NEW',
															-font 				=> $big_font,
															-background 		=> $bg_color,
															-foreground 		=> $fg_color,
															-activebackground	=> $hgt_color,
															#-activeforeground	=> $hgt_color,
															#-image		=> $mark_01	,
															-command	=> sub {set_properly_source ('no');$MW->destroy();},
																				
															)
																->pack(
																		-side => 'right',
																		-padx => 1,
																		-pady => 1
																		);
	#############################################################################################################################
	# 								GUI BOTTOM Panel content
	#############################################################################################################################

		my $vu_lastfrm		= $MW->Frame(
											-background => $bg_color,
										)
											->pack(
													-side => 'bottom', 
													#-fill => 'y',
													-fill => 'x',
													);	
							
		my $quit_btn01		=$vu_lastfrm->Button(
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
#sub set_properly_source {$from_library = $_[0];$MW->destroy();}
sub set_properly_source {$from_library = $_[0];}
#####################################################################################

#############################################################################################################################
# 								GUI FORMAT  Variables
#############################################################################################################################
sub define_checklist_to_run 
{
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
#############################################################################################################################
# 								GUI IMAGE  Variables
#############################################################################################################################	
	my $pending_image_file_name	= 'background.bmp';
	my $pending_image			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $pending_image_file_name);
	my $check_image_file_name	= 'check_mark.bmp';
	my $check_image				= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $check_image_file_name);

#############################################################################################################################
# 								GUI Main construction
#############################################################################################################################	
	alarm 60;
	$SIG{ALRM} = sub { print "CleanUp chk menu Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
	$MW = new MainWindow;
	$MW->configure	(	-title => $gui_title);
	$MW->geometry	("+200+50");
	$MW->configure	(-background => $bg_color);
	my $image_file_name = 'logo.bmp';
	my $image 			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $image_file_name);
	my $icon 			= $MW->Photo(-file => $image);
	$MW->idletasks;        # this line is crucial
	$MW->iconimage	($icon);
	my $balloon = $MW->Balloon();

#############################################################################################################################
# 								GUI Header content
#############################################################################################################################						
	my $vu_frm0		= $MW->Frame(
									-relief => 'flat',
									-background => $bg_color,
									#-borderwidth => 6
								)
										->pack(
												-side => 'top', 
												-fill => 'x'
												);
												
												
	my $vu_lb000		= $vu_frm0->Label(
									-pady => '1', 
									-padx => '1', 
									-relief => 'flat', 
									-state => 'normal', 
									-justify => 'center', 
									-text => '          Working Job :          ',
									-background => $bg_color,
									-foreground => $fg_color,
									-font => $big_font,
								)
										->pack(
												-side => 'top'
												);

	my $vu_lb00			= $vu_frm0->Label(
									-pady => '1', 
									-padx => '1', 
									-relief => 'flat', 
									-state => 'normal', 
									-justify => 'center', 
									-text => $JOB,
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
	my $central_frame		= $MW->Frame(
									-relief		=> 'flat',
									-background	=> $bg_color,
									-borderwidth => 1
								)
										->pack(
												-side => 'top', 
												-fill => 'x',
												-padx => 4,
												-pady => 4
												);

#############################################################################################################################
# 								GUI Center Panel content
#############################################################################################################################
	my $main_frame		= $central_frame->Frame(
									-relief		=> 'flat',
									-background	=> $fg_color,
									-borderwidth => 1
								)
										->pack(
												-side => 'top', 
												-fill => 'x',
												-padx => 2,
												-pady => 2
												);
#############################

	my $vu_lb1 = $main_frame->Label(
								-pady		=> '1', 
								-padx		=> '1',
								-relief		=> 'flat', 
								-state		=> 'normal',
								-text		=> 'Select the Checklist to Run',
								-justify	=> 'center',
								-font		=> $big_font,
								-background => $bg_color,
								-foreground => $fg_color,
								)
									->pack(
											-side => 'left'
											);												
#############################################################################################################################
# 						Drop down list	01			
#############################################################################################################################															

		my $list_01  = $main_frame->BrowseEntry( 
										-relief 			=> 'flat', 
										-state 				=> 'normal', 
										-justify 			=> 'center', 
										-font 				=> $big_font,
										-background 		=> $bg_color,
										-foreground 		=> $fg_color,
										-choices => \@checklist_group,
										-variable => \$selected_checklist
										)
											->pack(
															-side => 'left',
															-padx => 1,
															-pady => 1
															);												
#############################################################################################################################
# 								GUI BOTTOM Panel content
#############################################################################################################################

	my $vu_lastfrm		= $MW->Frame(
										-background => $bg_color,
									)
										->pack(
												-side => 'bottom', 
												#-fill => 'y',
												-fill => 'x',
												);	

	my $vu_but = $vu_lastfrm->Button(
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
									-command			=> sub	{main("$selected_checklist","FROM_LIBARY")}								
								)
									->pack(
											-side => 'right', 
											-pady => 3
											);
						
	my $quit_btn01		=$vu_lastfrm->Button(
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
															-pady => 3
															);												
												
												
	MainLoop;												
}
#########################################################################
# 					SUB Rutine to read folder content					#
#########################################################################
sub read_checklist_folder
{
my $dh = ($VALOR_DIR . "/fw/lib/steps/checklib/chk/");
opendir DIR, $dh;
my @temp_content = readdir(DIR);
foreach my $carpeta (@temp_content)
	{
	next if($carpeta eq ".");
	next if($carpeta eq "..");
	push @checklist_group, ("$carpeta");
	}
closedir DIR;
@checklist_group = sort @checklist_group;
#$F->PAUSE("@checklist_group");
}