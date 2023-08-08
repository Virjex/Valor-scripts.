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
#			Edgar Alfonso Ruiz Arellano												#
#			edgar.arellano@flextronics.com	+52 (33) 38183200 x6153					#
#			Flextronics, Guadalajara												#
#			Carretera Base Aerea #5850-4, La Mora									#
#			Zapopan, Jalisco, México 45136											#
#####################################################################################
#	Revision History: Fri Dec 22 10:53:00 2017	-Initial release					#
#																					# 
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
use lib ("$FindBin::Bin/../lib","${VALOR_EDIR}/all/perl",);
use Valor;
use vars qw( @LAYERS_TYPE @WEIGHT_VALUES @COPPER_LAYERS $F $JOB $STEP $TMP_DIR $MW $PROGRESS_FOLDER);
#####################################################################################

#####################################################################################
#									DEFINE VARIABLES								#
#####################################################################################
$JOB			=	$ENV{JOB};
$STEP			=	$ENV{STEP};
$TMP_DIR		=	$ENV{VALOR_TMP};
$F				=	new Valor;
my $prev_page	= 	('Matrix_Review.pl');
my $mode        =   ('interactive');
my $input1	    =   shift;
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
#							DEFINE ADDITIONAL VARIABLES								#
#####################################################################################
#----- Variables to be used for copper layer list -----
    @COPPER_LAYERS  =  ();
#----- Variables to be used to get copper weight value -----	
    @WEIGHT_VALUES  =  ();
#------------------------------------
	@LAYERS_TYPE    =  ();
###########################################################################
#Change units to Inches
###########################################################################
	$F->COM("units,type=inch");
#####################################################################################
# 						Welcome informative Pause									#
#####################################################################################
if ($mode eq "interactive")
{
welcome_message(
"This script will bring a user interface to define 
the copper weight for each copper layer in the board.","cu_weight.gif"
);
}#####################################################################################
#								SCRIPT START HERE									#
#####################################################################################
#$F->PAUSE ("Hola Mundo!!!" );
#####################################################################################
# 				Clear and Reset Filters or selections								#
#####################################################################################
clear_and_reset ();
get_copper_layer_list ();
input_gui ();
#--- Save the JOB ---#
$F->COM("save_job,job=$JOB,override=no");
#--------------------#
write_in_log     ("Set Copper Weight");
create_flag_file ("Set Copper Weight");
    if ($mode eq "interactive")
    {
    success_run("Script finish successfully!!");
    back_to_menu ("$prev_page");
    }
    if ($mode eq "silence")
    {
		my $path = ($VALOR_DIR . "/sys/scripts/FlexScripts/Drill_Validation/Drill_Validation.pl");
		run_next_script ("$mode","$path");
    }
exit (0);
#[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]


#####################################################################################
#				SUB-RUTINE TO AUTOMATICALLY RUN THE NEXT SCRIPT 					#
#####################################################################################
sub run_next_script
{
my $a      = $_[0];
my $script = $_[1];
alarm 0;
system("perl $script $a") or print("NOTE: Script does not exist.","\n");
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
$SIG{ALRM} = sub { print "Set Cu weight Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
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
$SIG{ALRM} = sub { $MW->destroy();print "Set Cu weight Inactivity Timeout!\n";}; # trap an alarm and assign a sub to destroy the window
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
#print("-----   $script  -----","\n");
system("perl $script") or print("NOTE: Script $script_file_name does not exist.","\n");
}
#####################################################################################
#					SUB-RUTINE TO CLEAR AND RESET									#
#####################################################################################
sub clear_and_reset
{
	# Clears selects, highlights, layers, and resets filters
	$F    = new Valor ;
	$JOB  = $ENV{JOB};
	$STEP = $ENV{STEP};
	
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
#				SUB-RUTINE TO CHECK ATTRIBUTE VALUES IN THE JOB						#
#####################################################################################
sub check_attributes
{
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $TMP_DIR			=	$ENV{VALOR_TMP};
my $F				=	new Valor;
my $datestamp 		=	localtime ();
my $username		=	$ENV{USERNAME};
my $sidearry_indx 	= 	0;
my $sidearry_indx2 	= 	0;
my $evaluated_value;
my $complex;
#---------------------------------------------------------------------------------------------------#

	#----------------------------------------------------------#

		$F->DO_INFO("-t job -e $JOB -m script -d ATTR -u no");
		foreach my $attr2(@{$F->{doinfo}{gATTRname}})
	{
		if ( $attr2 eq "_dfm_type")
		{  
			$evaluated_value = $F->{doinfo}{gATTRval}[$sidearry_indx2];
			$analysis_type = $evaluated_value;
		}	
		$sidearry_indx2 = $sidearry_indx2 + 1;
	}
	
}		

#####################################################################################
#				SUB-RUTINE TO CHECK ATTRIBUTE VALUES IN THE JOB						#
#####################################################################################
sub get_copper_layer_list
{
#--------------Variables --------------------
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $TMP_DIR			=	$ENV{VALOR_TMP};
my $F				=	new Valor;
my $layer           =  ('');
#------------Search across the job layers and FIX outer layers type ----------
	$F->DO_INFO("-t matrix -e $JOB/matrix");
	foreach my $_row(@{$F->{doinfo}{gROWrow}})
	{
		my $row = ($_row - 1);
        #skip empty name layers
		next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWlayer_type}}[$row] eq "dielectric");
			#---------------- Validate the outer layers are not mixed or powerground -----------------------------------------------------------------------------------------------------------------------------------
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "power_ground"  && (${$F->{doinfo}{gROWside}}[$row] eq "top") && (${$F->{doinfo}{gROWcontext}}[$row] eq "board"))
			{
				$layer = ${$F->{doinfo}{gROWname}}[$row];
                $F->COM("matrix_layer_type,job=$JOB,matrix=matrix,layer=$layer,type=signal");
			}
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "power_ground"  && (${$F->{doinfo}{gROWside}}[$row] eq "bottom") && (${$F->{doinfo}{gROWcontext}}[$row] eq "board"))
			{
				$layer = ${$F->{doinfo}{gROWname}}[$row];
				$F->COM("matrix_layer_type,job=$JOB,matrix=matrix,layer=$layer,type=signal");
			}
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "mixed"  && (${$F->{doinfo}{gROWside}}[$row] eq "top") && (${$F->{doinfo}{gROWcontext}}[$row] eq "board"))
			{
				$layer = ${$F->{doinfo}{gROWname}}[$row];
				$F->COM("matrix_layer_type,job=$JOB,matrix=matrix,layer=$layer,type=signal");
			}
			if (${$F->{doinfo}{gROWlayer_type}}[$row] eq "mixed"  && (${$F->{doinfo}{gROWside}}[$row] eq "bottom") && (${$F->{doinfo}{gROWcontext}}[$row] eq "board"))
			{
				$layer = ${$F->{doinfo}{gROWname}}[$row];
				$F->COM("matrix_layer_type,job=$JOB,matrix=matrix,layer=$layer,type=signal");
			}		          
            #-----------------------------------------------------------------
	}

#------------Search across the job layers for copper layers ----------
	$F->DO_INFO("-t matrix -e $JOB/matrix");
	foreach my $_row2(@{$F->{doinfo}{gROWrow}})
	{
		my $row = ($_row2 - 1);
        #skip empty name layers
		next if(${$F->{doinfo}{gROWtype}}[$row] eq "empty");
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWcontext}}[$row] eq "misc");
		#skip non-Board layers
		next if(${$F->{doinfo}{gROWlayer_type}}[$row] eq "dielectric");
        	#----- Group the copper layers in an array --------
			if ((${$F->{doinfo}{gROWlayer_type}}[$row] eq "signal")  && (${$F->{doinfo}{gROWcontext}}[$row] eq "board"))
			{
				$layer = ${$F->{doinfo}{gROWname}}[$row];
                get_cu_weight_value ("$layer");
				push @COPPER_LAYERS, ("$layer");
				push @LAYERS_TYPE, ("signal");
			}
 			if ((${$F->{doinfo}{gROWlayer_type}}[$row] eq "mixed")  && (${$F->{doinfo}{gROWcontext}}[$row] eq "board"))
			{
				$layer = ${$F->{doinfo}{gROWname}}[$row];
                get_cu_weight_value ("$layer");
				push @COPPER_LAYERS, ("$layer");
				push @LAYERS_TYPE, ("mixed");
			}   
 			if ((${$F->{doinfo}{gROWlayer_type}}[$row] eq "power_ground")  && (${$F->{doinfo}{gROWcontext}}[$row] eq "board"))
			{
				$layer = ${$F->{doinfo}{gROWname}}[$row];
                get_cu_weight_value ("$layer");
				push @COPPER_LAYERS, ("$layer");
				push @LAYERS_TYPE, ("power_ground");
			}                   
            #-----------------------------------------------------------------
	}
}
#####################################################################################
#				SUB-RUTINE TO GET COPPER WEIGHT FROM COPPER LAYER					#
#####################################################################################
sub get_cu_weight_value
{
#--------------Variables --------------------
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $TMP_DIR			=	$ENV{VALOR_TMP};
my $F				=	new Valor;
my $layer           =   $_[0];
my $weigth;
my $counter         =   0;
#----------------- Loop in the attributes of the layer -------
	$F->DO_INFO("-t layer -e $JOB/$STEP/$layer -m script -d ATTR");
		foreach my $_attr(@{$F->{doinfo}{gATTRname}})
			{
			if ( $_attr eq ".copper_weight")
				{
					my @fields_per_line = ('');
					$weigth = $F->{doinfo}{gATTRval}[$counter];
					print ("Value found for layer $layer on attribute $_attr is :$weigth  \n");
                    ($weigth, my $other_string) = split(" ", $weigth);
                    if (($weigth eq '') || ($weigth eq '0'))
                        {
                        $weigth='0.5';
                        $F->COM("set_attribute,type=layer,job=$JOB,name1=$STEP,name2=$layer,name3=,attribute=.copper_weight,value=$weigth");
                        }
                    my $value_string = $weigth;
                    my $thickness_factor = 0.0014;
					my $cu_thickness = $thickness_factor*$value_string;
					$F->COM("set_attribute,type=layer,job=$JOB,name1=$STEP,name2=$layer,name3=,attribute=.copper_thickness,value=$cu_thickness");
					push @WEIGHT_VALUES, ("$value_string");
				}
			$counter = $counter + 1;
			}
}
#####################################################################################
#				SUB-RUTINE TO CREATE THE GUI TO LIST ALL LAYERS     				#
#####################################################################################
sub input_gui
{
#--------------Variables --------------------
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $TMP_DIR			=	$ENV{VALOR_TMP};
my $F				=	new Valor;
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
my $mix_color		= ("khaki1");
#my $mix_color		= ("gold1");
my $signal_color    = ("DarkGoldenrod1");
my $pwr_color		= ("goldenrod4");
my @options         = ('0.5','1','2','3');
#############################################################################################################################
# 								GUI IMAGE  Variables
#############################################################################################################################	
	my $auto_image_file_name	= 'auto.gif';
	my $auto_image			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $auto_image_file_name);
	my $standard_image_file_name	= 'standard.gif';
	my $standard_image			= ($VALOR_DIR . "/sys/scripts/FlexScripts/Menus/images/" . $standard_image_file_name);
#####################################################################################
#							GUI Main construction									#
#####################################################################################
$MW = new MainWindow;
alarm 600;
$SIG{ALRM} = sub { print "Set Cu weight Inactivity Timeout!\n";$MW->exit();}; # trap an alarm and assign a sub to destroy the window
$MW->configure	(-title => $gui_title);
$MW->geometry	("600x500+200+10");
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
									-text => 'Please set the Copper Weight',
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
	my $second_frame		= $central_frame->Frame(
									-relief => 'flat',
									-background => $bg_color,
									#-borderwidth => 6
								)
										->pack(
												-side => 'top', 
												-fill => 'x'
												); 
	my $typelist		= $second_frame->Label(
                                    -width      => 14,
									-pady       => '1', 
									-padx       => '1', 
									-relief     => 'flat', 
									-state      => 'normal', 
									-justify    => 'center', 
									-text       => "Type",
									-background => $bg_color,
									-foreground => $shadow_color,
									-font       => $small_font,
								)
										->pack(
												-side => 'left'
												);
	my $lbllist		= $second_frame->Label(
                                    -width      => 14,
									-pady       => '1', 
									-padx       => '1', 
									-relief     => 'flat', 
									-state      => 'normal', 
									-justify    => 'center', 
									-text       => "Name",
									-background => $bg_color,
									-foreground => $shadow_color,
									-font       => $small_font,
								)
										->pack(
												-side => 'left'
												);												
 	my $lblweight		= $second_frame->Label(
                                    -width      => 18,
									-pady       => '1', 
									-padx       => '1', 
									-relief     => 'flat', 
									-state      => 'normal', 
									-justify    => 'center', 
									-text       => "Copper Weight \nOz / ft^2",
									-background => $bg_color,
									-foreground => $shadow_color,
									-font       => $small_font,
								)
										->pack(
												-side => 'left'
												); 	
################################################################################################################	
    my $cnt = 0;
    foreach my $item (@COPPER_LAYERS)
    {
    #--------------------------- FRAME ------------------------------
        my $fame = $central_frame->Frame(
                                -relief => 'groove',
                                -background => $bg_color,
                                )
                                ->pack(
                                        -side => 'top', 
                                        -fill => 'x'
                                        );
    #-------------------- LAYER TYPE LABEL --------------------------
	my $ltype =shift @LAYERS_TYPE;
        my $label = $fame->Label(
                                    -width      => 14,
                                    -pady		=> '1',
                                    -relief		=> 'flat', 
                                    -padx		=> '1', 
                                    -state		=> 'normal', 
                                    -justify	=> 'right', 
                                    -text		=> $ltype,
                                    -font		=> $small_font,
									-background	=> $bg_color,
									-foreground	=> $shadow_color,
                                    )
                                        ->pack(
                                                -side => 'left'
                                                );
    #-------------------- LAYER NAME LABEL --------------------------
        my $label = $fame->Label(
                                    -width      => 14,
                                    -pady		=> '1',
                                    -relief		=> 'flat', 
                                    -padx		=> '1', 
                                    -state		=> 'normal', 
                                    -justify	=> 'right', 
                                    -text		=> $item,
                                    -font		=> $medium_font,
									-background	=> $signal_color,
									-foreground	=> $bg_color,
                                    )
                                        ->pack(
                                                -side => 'left'
                                                );												
    #-------------------- CONFIGURE COLORS BASED IN LAYER TYPE --------------------------												
	#my $ltype =shift @LAYERS_TYPE;	
	if ($ltype   eq "power_ground")
	{
		$label->configure( -background => $pwr_color );
		$MW -> update;	
	}
	if ($ltype   eq "mixed")
	{
		$label->configure( -background => $mix_color );
		$MW -> update;	
	}												
    #-------------------- DROP DOWN OPTIONS --------------------------
    my $value =shift @WEIGHT_VALUES;
            my $drop  = $fame->BrowseEntry( 
                                            -width              => 14,
                                            -relief 			=> 'flat', 
                                            -state 				=> 'normal', 
                                            -justify 			=> 'center', 
                                            -font 				=> $medium_font,
                                            -background 		=> $bg_color,
                                            -foreground 		=> $pcba_data_color,
                                            -choices 			=> \@options ,
                                            -variable 			=> \$value,
                                            -browsecmd          => sub	{ set_attribute("$item","$value"); }
                                            )
                                                ->pack(
                                                                -side => 'left',
                                                                -padx => 1,
                                                                -pady => 1
                                                                );	
    #--------------------------------------------------------------------
    $cnt = $cnt + 1;
    }
################################################################################################################	
#                                   BOTTOM FRAME IN THE GUI
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

	$vu_butnext99 = $vu_frm99->Button(
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
									-text				=> 'Next ->>',
									-command			=> [$MW => 'destroy']
									#-command			=>sub{exit(0)},

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
#####################################################################################################################################################
sub set_attribute 
{
#--------------Variables --------------------
my $JOB				=	$ENV{JOB};
my $STEP			=	$ENV{STEP};
my $TMP_DIR			=	$ENV{VALOR_TMP};
my $F				=	new Valor;
my $layer  = $_[0];
my $weigth = $_[1];
#$F->PAUSE("Modify $layer -- $arg1 ");
#------- Set Copper weigth attribute to layer -----
$F->COM("set_attribute,type=layer,job=$JOB,name1=$STEP,name2=$layer,name3=,attribute=.copper_weight,value=$weigth");
 #------- Set Copper thickness attribute to layer -----                   
 my $value_string = $arg1;
 my $thickness_factor = 0.0014;
 my $cu_thickness = $thickness_factor*$value_string;
$F->COM("set_attribute,type=layer,job=$JOB,name1=$STEP,name2=$layer,name3=,attribute=.copper_thickness,value=$cu_thickness");
}