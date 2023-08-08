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

