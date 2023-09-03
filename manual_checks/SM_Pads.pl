#!perl -w

use strict;
use warnings;
use File::Basename;
use vars qw( $top $bot $temp %issue @refs @sides %comps);

use lib dirname(__FILE__).'\..';
use DFM_Util;
use List::MoreUtils qw( uniq );

remove_layers("sm_top_test","sm_bot_test");
clear_and_reset;

valor("filter_atr_set,filter_name=popup,attribute=.comp_mount_type,entity=component,condition=yes,option=smt");

$temp = check_comp_sides;
if ($temp == 0){
	pop_up("No components were found on the baord");
	exit(0);
}	elsif ($temp == 1) {
		@sides = ('top');
		
}	elsif ($temp == 2) {
		@sides = ('bot');
		
}	elsif ($temp == 3) {
		@sides = ('top','bot');
}

foreach my $side(@sides){
	dupe_layer("sm$side");
	my $layer = "sm_" . $side .  "_test";
	my $copper_layer = ($side eq "top" ? "top" : "bottom");
	rename_layer(get_layer_names_by_row(get_layer_row_number_by_name("sm$side") + 1),$layer);
	valor(
		"affected_layer,name=$layer,mode=single,affected=yes",
		"sel_resize,size=0.05",
		"affected_layer,name=$layer,mode=single,affected=no",
		"filter_reset",
		"filter_atr_set,filter_name=popup,attribute=.smd,entity=feature,condition=yes",
		"affected_layer,name=$copper_layer,mode=single,affected=yes",
		"filter_area_strt",
		"filter_area_end,layer=,filter_name=popup,operation=select",
		"sel_copy_other,dest=layer_name,target_layer=$layer,invert=yes,dx=0,dy=0,size=0",
		"affected_layer,name=,mode=all,affected=no",
		"affected_layer,name=$layer,mode=single,affected=yes",
		"sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y"
	);

	my %data = data_pads($layer);
	
	foreach my $id(keys %data){
		if($data{$id}->{holes} > 1){
			my %temp;
			my $orignal_hole_count;
			print "Working on understanding $id from $layer","\n";
			valor(
				"filter_reset",
				"affected_layer,name=$layer,mode=single,affected=yes",
				"affected_layer,name=sm$side,mode=single,affected=yes"
			);
			select_pad($id,$layer);
			valor("sel_ref_feat,layers=,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative");
			if(get_select_count){
				%temp = data_pads("sm$side",'s');
				foreach my $orignal_sm(keys %temp){
					$orignal_hole_count += $temp{$orignal_sm}->{holes};
				}
			}
			if($orignal_hole_count < $data{$id}->{holes}){
				$issue{$id}->{side} = "sm$side";

				if($data{$id}->{type} eq 'surface'){
					$issue{$id}->{x} = $data{$id}->{xc};
					$issue{$id}->{y} = $data{$id}->{yc};
				} else {
					$issue{$id}->{x} = $data{$id}->{x};
					$issue{$id}->{x} = $data{$id}->{y};
				}
				$issue{$id}->{qnt} = $data{$id}->{holes} - $orignal_hole_count;
#				pop_up
#				("
#				\$issue{$id}->{side} = sm$side; <br>
#				\$issue{$id}->{x} = $data{$id}->{xc}; <br>
#				\$issue{$id}->{y} = $data{$id}->{yc}; <br>
#				\$issue{$id}->{qnt} = $data{$id}->{holes} - $orignal_hole_count; <br>
#				");
				valor("sel_clear_feat");
				select_pad($id,$layer);
				valor(
					"filter_reset",
					"affected_layer,name=sm$side,mode=single,affected=yes",
					"sel_ref_feat,layers=,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative",
					"affected_layer,name=comp_+_$side,mode=single,affected=yes",
					"affected_layer,name=$layer,mode=single,affected=no",
					"sel_ref_feat,layers=,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative",
				);
				%comps = (%comps,get_data_comp(selected_refdes_full)) if get_select_count;
			}
			valor("affected_layer,name=,mode=all,affected=no");
		}	
	}
}
remove_layers("sm_top_test","sm_bot_test");
if (scalar(keys %comps) == 0 && scalar(keys %issue) == 0){
	pop_up("No issue was found");
	clear_and_reset;
	exit 0;
}
my $file = 'C:\MentorGraphics\Valor\vNPI_TMP\smd_pads_sm_check.txt';
open(my $fl, '>', $file) or die "Cannot open file: $!";
print $fl "Multiple SMD under one SM:\n";
my @id = (keys %comps);
foreach my $i(@id){
	print $fl "$comps{$i}->{side}\t$i\t$comps{$i}->{x}\t$comps{$i}->{y}\n";
}
print $fl "\nDebug info:\n";
@id = (keys %issue);
foreach my $i(@id){
	print $fl "$issue{$i}->{side}\t$issue{$i}->{x}\t$issue{$i}->{y}\t$issue{$i}->{qnt}\n";
}

close $fl;
clear_and_reset;
system(1,"notepad.exe $file");