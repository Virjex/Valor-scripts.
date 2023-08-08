#perl -w

use warnings;
use strict;
use Valor;
use POSIX;
use Tk;
use vars qw ( $V $JOB $STEP $SCRIPT );

use Win32::API;

use File::Basename;
use lib dirname(__FILE__);
use DFM_Util;

my $local_settings = $DFM_Util::settings;

$V				= 	Valor->new();
$JOB			=	$ENV{JOB};
$STEP			=	$ENV{STEP};

	#find a place to store the scripts
my $GUI_path	= 'C:\MentorGraphics\Scripts\main_GUI.pl';

if ($JOB eq "" || $STEP eq "") {
	$V->PAUSE("Script must start in Graphic Editor Screen!");
	exit 0;
}

#this title is used to reffer back to the grafic station that we use to work on Valor
my $title = "Graphic Station: $ENV{JOB} [Step: $ENV{STEP}]";
#local settings
#my $local_Settings = 'C:\MentorGraphics\Valor\vNPI_TMP\settings.txt';
my $tempJOB; my $tempSTEP; my $test;
#validate Settings file
if (-e $local_settings) {
	#if the settings file exists
	# this will be used to call to a script to run with in Valor but first validate if it's the same $JOB and same $STEP
	open(my $fh, '<', $local_settings);
	while (my $line = <$fh>) {
		if ($line =~ /SCRIPT:(.*)/) {
			$SCRIPT = $1;
		} elsif ($line =~ /JOB:(.*)/) {
			$tempJOB = $1;
		} elsif ($line =~ /STEP:(.*)/){
			$tempSTEP = $1;
		}
	}
	close($fh);
#for the first run
} else {
	#setting up the settinngs 
	create_local_settings_file($local_settings);
	#calling the GUI and showing it
	my $pid = fork();
	if ($pid == 0 ){
		system(1, "perl", $GUI_path);
		exit 1;
	}
}

#check if there is a GUI active
my $findWindow = Win32::API->new('user32.dll', 'FindWindow', ['P', 'P'], 'N');
my $windowHandle = $findWindow->Call(0, 'DFM Support');
if ($windowHandle) {
	#there is an active window check call for the script
	if(($tempJOB eq $JOB && $tempSTEP eq $STEP) && $SCRIPT ne ''){
		#if the its the same job and step as the settings and a script is loaded to the settings.
		system("perl $SCRIPT");
		Win32::API->new('user32.dll', 'SetForegroundWindow', ['N'], 'N')->Call($windowHandle);
		Win32::API->new('user32.dll', 'SetActiveWindow', ['N'], 'N')->Call($windowHandle);
		create_local_settings_file($local_settings);
	} elsif (($tempJOB eq $JOB && $tempSTEP eq $STEP) && $SCRIPT ne '') {
		#same Step and Job but no script at the settings. just a call back to show the GUI
		print "we got to the window $windowHandle","\n";
		Win32::API->new('user32.dll', 'SetForegroundWindow', ['N'], 'N')->Call($windowHandle);
		Win32::API->new('user32.dll', 'SetActiveWindow', ['N'], 'N')->Call($windowHandle);
	} elsif ($tempJOB ne $JOB || $tempSTEP ne $STEP) {
		#here got a diffrent job or step. a need to kill off the old GUI and show a new one. with a new set of settings
		
		
	}
} else {
	#no GUI active yet settings file exists
	if($tempJOB ne $JOB or $tempSTEP ne $STEP) {
		print "String a new GUI with the new Settings","\n";
		create_local_settings_file($local_settings);
		system(1, "perl", $GUI_path);
	} else {
		print "String a new GUI","\n";
		system(1, "perl", $GUI_path);
	}
}


sub create_local_settings_file{
	open(my $fh, '>', shift);
	print $fh "SCRIPT:\n";
	print $fh "JOB:$JOB\n";
	print $fh "STEP:$STEP\n";
	close($fh);
}