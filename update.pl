#!perl -w

use strict;
use warnings;
use Win32::Clipboard;
use Win32::API;

use File::Basename;
use lib dirname(__FILE__);
use DFM_Util;

my $clipboard = Win32::Clipboard->new();

$clipboard->Set('C:\MentorGraphics\Scripts\Update.bat');

# Define the necessary Windows API functions
our $keybd_event = Win32::API->new('user32', 'keybd_event', ['N', 'N', 'N', 'N'], 'V');

# Key codes for Win key and R key
my $VK_LWIN = 0x5B;
my $VK_R = 0x52;
my $VK_ENTER = 0x0D;
my $VK_CONTROL = 0x11;
my $VK_V = 0x56;

# Send the Win+R keystrokes
$keybd_event->Call($VK_LWIN, 0, 0, 0);  
$keybd_event->Call($VK_R, 0, 0, 0);     

$keybd_event->Call($VK_R, 0, 2, 0);     
$keybd_event->Call($VK_LWIN, 0, 2, 0);  

# Define the FindWindow function from the user32.dll library
my $findWindow = Win32::API->new('user32.dll', 'FindWindow', ['P', 'P'], 'N');

my $windowHandle = 0;

# Wait for the "Run" window to appear
while (1) {
    # Call the FindWindow function to get the window handle
    $windowHandle = $findWindow->Call(0, "Run");

    # Check if the window handle was found
    if ($windowHandle) {
        # Break the loop if the window handle was found
        last;
    }

    # Optional short sleep to prevent maxing out CPU usage
    sleep 1;
}

# Bring the "Run" window to the front
Win32::API->new('user32.dll', 'SetForegroundWindow', ['N'], 'N')->Call($windowHandle);
Win32::API->new('user32.dll', 'SetActiveWindow', ['N'], 'N')->Call($windowHandle);

# Simulate pressing Ctrl+V and Enter to start the Update.bat
$keybd_event->Call($VK_CONTROL, 0, 0, 0);   
$keybd_event->Call($VK_V, 0, 0, 0);         
$keybd_event->Call($VK_V, 0, 2, 0);         
$keybd_event->Call($VK_CONTROL, 0, 2, 0);   
$keybd_event->Call($VK_ENTER, 0, 2, 0);     
$keybd_event->Call($VK_ENTER, 0, 0, 0); 

# Wait for the "DFM Support" window to appear
while (1) {
    # Call the FindWindow function to get the window handle
    $windowHandle = $findWindow->Call(0, "DFM Support");

    # Check if the window handle was found
    if ($windowHandle) {
        # Break the loop if the window handle was found
        last;
    }

    # Optional short sleep to prevent maxing out CPU usage
    sleep 1;
}

# Bring the "DFM Support" window to the front
Win32::API->new('user32.dll', 'SetForegroundWindow', ['N'], 'N')->Call($windowHandle);
Win32::API->new('user32.dll', 'SetActiveWindow', ['N'], 'N')->Call($windowHandle);

my $sendMessage = Win32::API->new('user32.dll', 'SendMessage', ['N', 'N', 'N', 'N'], 'N');
$sendMessage->Call($windowHandle, 0x0010, 0, 0);

while (1) {
    # Call the FindWindow function to get the window handle
    my $windowHandle = $findWindow->Call(0, "Sam's Valor Scripts Update");

    # Check if the window handle was found
    if ($windowHandle) {
        # Bring the window to the front
        Win32::API->new('user32.dll', 'SetForegroundWindow', ['N'], 'N')->Call($windowHandle);
        Win32::API->new('user32.dll', 'SetActiveWindow', ['N'], 'N')->Call($windowHandle);
	#	sleep 60;
        # Press Enter
        $keybd_event->Call($VK_ENTER, 0, 0, 0); 
        $keybd_event->Call($VK_ENTER, 0, 2, 0);

        # Break the loop as the batch file has started
        last;
    }

    # Optional short sleep to prevent maxing out CPU usage
    sleep 1;
}

# system(1,"perl", 'C:\MentorGraphics\Scripts\main_GUI.pl');