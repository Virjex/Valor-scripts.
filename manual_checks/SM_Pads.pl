#!perl -w

#!perl -w

use strict;
use warnings;
use File::Basename;
use vars qw( $top $bot $temp @issue @refs @sides );

use lib dirname(__FILE__).'\..';
use DFM_Util;

clear_and_reset;



=begine
	If working with components this is kinda a must.
	0 - no comps
	1 - top only
	2 - bottom only
	3 - top and bottom
=cut

if (check_comp_sides() == 0){
	pop_up("No components were found on the baord");
	exit(0);
}	elsif (check_comp_sides() == 1) {
		@sides = ('top');
		
}	elsif (check_comp_sides() == 2) {
		@sides = ('bot');
		
}	elsif (check_comp_sides() == 3) {
		@sides = ('top','bot');
		
}

# normaly here will be the results proccesing

sub main_test{
	
	valor("filter_set,filter_name=popup,update_popup=no,feat_types=pad");
	foreach my $side(@sides){

		my %sm_openings = data_pads("sm$side");
		# setting up the alayers to be worked on.
		valor(
			"affected_layer,name=" . ($side eq "top" ? "top" : "bottom") .  ",mode=single,affected=yes",
			"affected_layer,name=sm$side,mode=single,affected=yes"
		);
		foreach my $sm(keys %sm_openings){
			select_pad($sm,"sm$side");
			valor("sel_clear_feat");
		}
	}
}