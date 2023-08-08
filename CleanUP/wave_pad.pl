#perl -w

use strict;
use warnings;
use File::Basename;
use lib dirname(__FILE__).'\..';
use DFM_Util;

###############
#the idea is to have a selected pad and assign to it just the wave required att.
#
	if (DFM_Util::get_select_count){
		DFM_Util::valor("cur_atr_reset"
			,"cur_atr_set,attribute=.pad_usage,option=toeprint"
			,"sel_change_atr,mode=replace"
			,"cur_atr_reset"
			);
	} else {
		DFM_Util::pop_up("No pad was selected");
	}