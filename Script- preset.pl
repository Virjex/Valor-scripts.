#!perl -w

use strict;
use warnings;
use File::Basename;
use vars qw( $top $bot $temp @issue @refs );

#
#	if a script will be located in a folder. having the .'\..' will go up a lvl in the Dir
#	adding a lib to @INC just to be able to use the DFM_Util.pm
#

use lib dirname(__FILE__);
use DFM_Util;

DFM_Util::clear_and_reset();

=begine
	If working with components this is kinda a must.
	0 - no comps
	1 - top only
	2 - bottom only
	3 - top and bottom
=cut

if (DFM_Util::check_comp_sides() == 0){
	DFM_Util::pop_up("No components were found on the baord");
	exit(0);
}	elsif (DFM_Util::check_comp_sides() == 1) {
		# TOP only
		
}	elsif (DFM_Util::check_comp_sides() == 2) {
		# BOT only
		
}	elsif (DFM_Util::check_comp_sides() == 3) {
		# TOP + BOT
		
}

# normaly here will be the results proccesing