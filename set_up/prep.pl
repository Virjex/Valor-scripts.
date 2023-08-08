#!perl -w

use strict;
use warnings;
use File::Basename;
#
#	if a script will be located in a folder. having the .'\..' will go up a lvl in the Dir
#	adding a lib to @INC just to be able to use the DFM_Util.pm
#

use lib (dirname(__FILE__).'\..');
use DFM_Util;

# this scrip if for the prep work.
# i.e. rename layers,chnage the layers to mix. crate folders, set up the job setting.ini file 
# 1. set up the folders
system('perl',dirname(__FILE__) .'\create_working_folders.pl');
# 2. set up the settings file. 

# 3. rename the layers and duplicate them and chenge the iner layers to mix and have a making of rout.
system('perl',dirname(__FILE__) .'\Flex_RenameLayers.pl');
system('perl',dirname(__FILE__) .'\dup_layers.pl');

# 4. crate the layer stack up and job parameters
#this is a bit of a problomatic option. as i need this one to be free.. 
#system('perl',dirname(__FILE__) .'\fab.pl');

#getting the list of layers and saving them to a file.


# 5. call the clean up script from the global
system('perl',dirname(__FILE__) .'\Clean_up_chk_menu.pl');

# 6. check for negatives
#layers and features
##ystem('perl',dirname(__FILE__) .'\Clean_up_chk_menu.pl');
#system('perl',dirname(__FILE__) .'\Clean_up_chk_menu.pl');

# . call the net-list 
#system('perl',dirname(__FILE__) .'\dup_layers.pl');


