#perl -w

use warnings;
use strict;
use Tk;
use Win32::API;
use vars qw ( $JOB $STEP $SCRIPT );
use File::Basename;
use lib dirname(__FILE__);
use DFM_Util;

my $local_settings = $DFM_Util::settings;
our $mw = MainWindow->new;
our $time_tick = 1;

if (-e $local_settings) {
	open(my $fh, '<', $local_settings);
	while (my $line = <$fh>) {
		if ($line =~ /SCRIPT:(.*)/) {
			$SCRIPT = $1;
		} elsif ($line =~ /JOB:(.*)/) {
			$JOB = $1;
		} elsif ($line =~ /STEP:(.*)/){
			$STEP = $1;
		}
	}
	close($fh);
}
if ($JOB eq "" or $STEP eq ""){
	print "No STEP or JOB was found in the local settings file","/n";
	exit 0;
}
our $title = "Graphic Station: $JOB [Step: $STEP]";

GUI();

sub GUI {
	my $title;
	# Create the main window
	$mw->title("DFM Support");

	# Create the top frame
	my $top_frame = $mw->Frame(
		-relief      => 'groove',
		-borderwidth => 2,
	)->pack(-side => 'top', -fill => 'x');

	# Create a label widget inside the top frame

	$title = "DFM support for Job : $JOB" unless $title;

	$top_frame->Label(-text => $title )->pack(-side => 'left');

	# Create the left frame
	my $left_frame = $mw->Frame(
		-relief      => 'groove',
		-borderwidth => 2,
	)->pack(-side => 'left', -fill => 'y');

	# Create a stack of buttons inside the left frame
	
	my @button_labels = ("Prep - in dev",	#0
						"X Y from File - Nvidia", #1
						
						"SMT pad - testing", #2
						"Wave pad- testing",
						
						"Add smd_miss to Fab checklist - DEV",
						
						"Thermal relief checks - testing",
						"Wave openings - testing",
						"BGA - testing",
						
						"Multiple SMD under SM",
						"Backdrill checks",

						"Get the refdes from XY - testing",
						"Get the XY of refdes - testing",

						"Baord snapshoot",
						"FAB Data - in dev",

						"update - in testing",
						"Exit");
	
	my @button_functions = (
		sub { call_script("set_up\\prep"); },
		sub { call_script("set_up\\tp_x_y"); },
		
		sub { call_script("CleanUP\\SMT_pad"); },
		sub { call_script("CleanUP\\wave_pad"); },

		sub { call_script("ChckList\\Checklist-injection"); },
		
		sub { call_script("Wave\\Thermal"); },
		sub { call_script("Wave\\procmap_creation"); },
		sub { call_script("BGA\\BGA-Pads"); },

		sub { call_script("manual_checks\\SM_Pads"); },
		sub { call_script("manual_checks\\backdrill_checks"); },

		sub { call_script("For_reports\\get_refdes"); },
		sub { call_script("For_reports\\get_loc"); },
		
		sub { call_script("misc\\Snaps"); },
		sub { call_script("Data\\Fab"); },
		sub { system(1, "perl" , 'C:\MentorGraphics\Scripts\update.pl'); },
		
		sub { exit },
	);
	
	my @disabled_buttons = (0,13);  # Specify the indxes of buttons to disable

    foreach my $i (0..$#button_labels) {
        my $button = $left_frame->Button(
            -text    => $button_labels[$i],
            -command => $button_functions[$i],
        )->pack(-side => 'top', -fill => 'x');

        $button->configure(-state => 'disabled') if grep { $_ == $i } @disabled_buttons;
    }

	# Create the right frame
	my $right_frame = $mw->Frame(
		-relief      => 'groove',
		-borderwidth => 2,
	)->pack(-side => 'right', -fill => 'y');

	# Define the labels and values to display
	my %labels = (
		"Layer count" 		=> "16/16",
		"Rout type"   		=> "Mousebites",
		"Board thinkness" 			=> "2.8 inch",
		"Finish"  		=> "Enig",
	);

	# Add the labels and values to the right frame using the grid geometry manager
	my $row = 0;
	foreach my $label (sort keys %labels) {
#		$right_frame->Label(-text => $label)->grid(-row => $row, -column => 0, -sticky => 'w');
#		$right_frame->Label(-text => $labels{$label})->grid(-row => $row, -column => 1, -sticky => 'w');
		$row++;
	}

	# Main update loop
	my $communication_file = 'C:\MentorGraphics\Valor\vNPI_TMP\pipe.txt';
	# Continuously check the file for new content
	$mw->repeat(1000, sub {
		if (-e $communication_file) {
			open(my $fh, "<", $communication_file) or die "Could not open file: $!";
			my $new_title = <$fh>;
			close $fh;

			if (defined $new_title) {
				chomp $new_title;
				$mw->title($new_title);  # Update the window title
			}

			# Remove the file after reading
			unlink $communication_file;
		}
	});
	MainLoop;
}
