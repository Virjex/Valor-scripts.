#!perl -w

use strict;
use warnings;
use File::Basename;
use lib dirname(__FILE__).'\..' ;
use vars qw( $top $bot $temp @id @refs $JOB $STEP %issue %pads %leads %comps %spokes_results );
use DFM_Util;
use List::Util qw( max min );
use List::MoreUtils qw( uniq );

valor("units,type=inch");

# Basic reset
$JOB = $ENV{JOB};
$STEP = $ENV{STEP};
my $file = "C:\\MentorGraphics\\Valor\\vNPI_TMP\\thermal.txt";
recreate_layers();
# check if a themral layer exists
my $layer_flag = check_for_layer('thermal','comp_pins','comp_body');
pop_up("$layer_flag layer was not found.") if $layer_flag;
exit 0 if $layer_flag;

clear_and_reset;
# getting the names of the layers
# my @drill_layer = get_layer_names_by_type("drill");

# Now starting the main testing
# first clean the leads up
recreate_layers("testing");
valor("display_layer,name=comp_pins,display=yes,number=3",
	"work_layer,name=comp_pins",
	"sel_ref_feat,layers=thermal,use=filter,mode=cover,f_types=pad\;surface,polarity=positive\;negative");
valor("sel_reverse") if get_select_count;
valor("sel_delete") if get_select_count;

# buildiong the data base of the compes leads
%leads = data_pads("comp_pins");

foreach my $i(keys %leads){
	my $key = ($leads{$i}{attrs} =~ /\.artwork=(.*?)(?:,|$)/g)[0];
	$comps{$key}->{$i} = 1;
	$leads{$i}->{refdes} = $key;
}

# starting from thermal relief
# run down the layers and from TOP to BOT
for (my $i = get_row_number("top"); $i <= get_row_number("bottom"); $i++){
	my $layer = get_layer_names_by_row($i);
	my $key;
	# $i is the layer index. 
	valor(
	# set up a filter
		"display_layer,name=comp_pins,display=yes,number=3",
		"work_layer,name=comp_pins",
		"filter_set,filter_name=popup,update_popup=no,feat_types=surface",
		"display_layer,display=yes,number=4,name=$layer",
		"work_layer,name=$layer",
		"sel_copy_other,dest=layer_name,target_layer=testing,invert=no,dx=0,dy=0,size=0",
		"display_layer,display=yes,number=4,name=testing",
		"work_layer,name=testing",
		"filter_set,filter_name=popup,update_popup=no,feat_types=surface",
		"filter_atr_set,filter_name=popup,attribute=.tear_drop,entity=feature,condition=yes",
		"filter_area_strt",
		"filter_area_end,layer=,filter_name=popup,operation=select"
	);
	
	valor("sel_delete") if get_select_count;

	# tear drop has been handled.	
	clear_and_reset;
	recreate_layers("trace");
	valor(

		"display_layer,name=testing,number=4,display=yes",
		"work_layer,name=testing",
		"filter_reset",
		"filter_set,filter_name=popup,update_popup=no,feat_types=surface",
		"filter_area_strt",
		"filter_area_end,layer=,filter_name=popup,operation=select",
		"affected_layer,name=$layer,mode=single,affected=yes",
		"filter_set,filter_name=popup,update_popup=no,feat_types=line",
		"sel_ref_feat,layers=$layer,use=select,mode=touch,polarity=positive\;negative",
		"sel_copy_other,dest=layer_name,target_layer=trace,invert=no,dx=0,dy=0,size=0"
		
	);


	# now we got the testing layer for testing for thermal with tear drops cleared.
	# trace later for calculation
	
	clear_and_reset;

	valor(
		"filter_set,filter_name=popup,update_popup=no,feat_types=surface",
		"display_layer,display=yes,number=4,name=testing",
		"work_layer,name=testing",
		"sel_ref_feat,layers=comp_pins,use=filter,mode=touch,f_types=pad\;surface,polarity=positive\;negative"
	);
	if (get_select_count){
		
		valor(
			"affected_layer,name=testing,mode=single,affected=yes",
			"display_layer,display=yes,number=4,name=comp_pins",
			"work_layer,name=comp_pins",
			"filter_reset",
			"sel_ref_feat,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative"
		);
		
		%pads = data_pads('comp_pins','s');
		# failed on thermal relief
		@id = ( keys %pads ); # this holds all the pins that failed.
		foreach my $j (@id) {
			$key = ($pads{$j}->{attrs} =~ /\.artwork=(.*?)(?:,|$)/g)[0];
			push @{$issue{$key}->{layer}}, $layer;
			# to easy up on the test we going to remove leads. if they failed. they should be in the leads hash
	#		delete ($leads{$key});
		}
	}
	
	valor("affected_layer,name=testing,mode=single,affected=no");
	
	# spoke calculationing
	# first select the spokes
	# refence selection to the PAD
	valor("sel_clear_feat");
	
	my $layer_oz = get_cu_weight_value($layer,"mil");
	foreach my $pin(keys %leads){
		# prep work for the loop 
		# we going need to climb up from the lead to the spoke.
		# lead -> Pad -> Spoke
		valor(
			"display_layer,display=yes,name=comp_pins,number=3",
			"work_layer,name=comp_pins"
		);
		
		# selects the lead under test
		select_pad($pin, 'comp_pins');
		
		valor(
			"affected_layer,name=testing,mode=single,affected=yes",
			"filter_set,filter_name=popup,update_popup=no,feat_types=pad",
			"sel_ref_feat,use=select,mode=touch,f_types=pad,polarity=positive\;negative"
		);
		
		# here we got the pad from the testing layer selected.
		my %temp_spoke_data = data_pads('testing', 's');
		# possible eage case not a round PAD
		$temp_spoke_data{(keys %temp_spoke_data)[0]}->{symbol} =~ /(\d+(?:\.\d+)?)/;
		my $pad_size = max($1,$2); #this will hold the largest value 
		# Pad size will be used to test if the spoke exists the pad $pad_size / 2 > sqrt((XE - XS)**2 + (YE - YS)**2);
		
		# now we need to select the spokes
		
		valor(
			"display_layer,display=no,name=comp_pins,number=3",
			"display_layer,display=yes,name=trace,number=4",
			"work_layer,name=trace",
			"filter_set,filter_name=popup,update_popup=no,feat_types=line",
			"sel_ref_feat,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative",
		);


# use a valid REFDES to get its leads
#pop_up(join (", ", keys %{$comps{'J27'}}));

# use a valid leasd ID to get it's refdes
#pop_up($leads{20}->{refdes});
	
		# if a spoke is selcted we can preform it's calculation
		next unless get_select_count;
		my %spoke = data_pads("trace","s");
		
		$spokes_results{$pin}->{total_count} +=  get_select_count;
		$spokes_results{$pin}->{$layer}->{spokes_count} = get_select_count;
		
		my ($res) = (scalar (keys %spoke) * (($spoke{(keys %spoke)[0]}->{symbol} =~ /([+-]?\d+(?:\.\d+)?)/)[0]) * $layer_oz) * 0.000625 ; # converting mil 
		
		$spokes_results{$pin}->{$layer}->{layer} = $res;
		$spokes_results{$pin}->{total_result} += $res;
		$spokes_results{$pin}->{x} = $leads{$pin}->{x};
		$spokes_results{$pin}->{y} = $leads{$pin}->{y};
		$spokes_results{$pin}->{refdes} = $leads{$pin}->{refdes};
		push( @{$spokes_results{$pin}->{layers}}, $layer);
		
	}
	
	
	recreate_layers("testing");
}



# thermal here ends so we can delete all the key sub key

# starting with low thermal isolation
# first we going to need to tie all the elecments on thermal
clear_and_reset;
valor("display_layer,name=comp_pins,number=1,display=yes",
		"work_layer,name=comp_pins");
#surface_to_pad;

%pads = data_pads("comp_pins");
	# the main key is the REFDES
	# It will be data REF X1 (Max) X2 (Min) Y1 (Max) Y2 (Min)
	# to find the we will run on the ID.
	
	# check if the of $pads{$_}{x} + 0.001 (10 mil) + $pads{$_}{symbol} =~ /\r(*.)/[0] < $data{$key}{x1}
valor("affected_layer,name=comp_pins,mode=single,affected=yes",
	"display_layer,name=comp_pins,number=1,display=no",
	"display_layer,name=thermal,number=4,display=yes",
	"work_layer,name=thermal");
	
# Method 1
# Calaculate the Area of the leads
# get the extrem sides of the pins of a ref des and get the X max Y max X Min Y Min
# and treat it as a rectengal.
# and run over the results from Thermal to see if a result is in the rectengal area. assing it to a + REFDES 
# i dont think re create the all the results to pads and layers will be a smart and valid (Computing power)
# calculate it outside Valor will be a faster way.

my %data;
@id = (keys %pads);
foreach my $index(@id){
	my $key = ($pads{$index}->{attrs} =~ /\.artwork=(.*?)(?:,|$)/g)[0]; # refdes
	select_pad($index,"comp_pins");
	valor("sel_ref_feat,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative");
	next if (get_select_count == 0);
	
	my %pad = data_pads("thermal",'s');
	my $pad_key = (keys %pad)[0];
	
	$pad{(keys %pad)[0]}->{symbol} =~ /(\d+(?:\.\d+)?)/;
	my $size = (max($1,$2,$3) / 1000);
	
	# now the cords of the rectengal
	$data{$key}->{x_max} = $pad{(keys %pad)[0]}->{x} + 0.002 + $size if $pad{(keys %pad)[0]}->{x} + 0.002 + $size > $data{$key}->{x_max};
	$data{$key}->{x_min} = $pad{(keys %pad)[0]}->{x} - 0.002 - $size if $pad{(keys %pad)[0]}->{x} - 0.002 - $size < $data{$key}->{x_min} || !($data{$key}->{x_min});
	$data{$key}->{y_max} = $pad{(keys %pad)[0]}->{y} + 0.002 + $size if $pad{(keys %pad)[0]}->{y} + 0.002 + $size > $data{$key}->{y_max};
	$data{$key}->{y_min} = $pad{(keys %pad)[0]}->{y} - 0.002 - $size if $pad{(keys %pad)[0]}->{y} - 0.002 - $size < $data{$key}->{y_min} || !($data{$key}->{y_min});
	
	valor("sel_clear_feat");
}


clear_and_reset;

# calling the checklist.
	create_checklist("thermal");
# adding the custom module to the checklist

valor(
	"chklist_cadd,chklist=thermal,action=valor_analysis_signal,row=0",
	"chklist_reread_erfs,chklist=thermal,nact=1,path=C:/MentorGraphics/ERFS/Slivers/signal.erf",
	"chklist_erf,chklist=thermal,nact=1,erf=Thermal Isolation",
	"chklist_run,chklist=thermal,nact=a,area=Profile",
	
	# pulling the results from the checklist
	"info,args=-t check -e $JOB/$STEP/thermal -m script -d MEAS -u no -o action=1+severity=R ,out_file=$file,write_mode=replace,units=inch");

# Alert + Layer + Measurment unit SG? X1 Y1 X2 Y2 ID Type target
# sliver 06_gnd 3.9396 mil SG 1.832521 4.212624 1.8353067 4.2154097 199 R 8

# open the file
open(my $fh, '<', $file) or die "Cannot open file: $!";
while (my $line = <$fh>) {
	#chomp $line;
	my @results = split(" ",$line);
	my $x = ($results[5] + $results[7]) / 2;
	my $y = ($results[6] + $results[8]) / 2;
	# now the maiun check if the cord is located with in the rectengal of the refdes.
	my @id = (keys %data);
	
	foreach my $i(@id){
	#	pop_up("SW2 is getting tested") if $i eq "SW2";
		if(	$x >= $data{$i}->{x_min} && 
			$x <= $data{$i}->{x_max} && 
			$y >= $data{$i}->{y_min} &&
			$y <= $data{$i}->{y_max} ){
			# <- End of the if -> #
			# if (!defined $data{$i}->{mes} || ($results[2] < $data{$i}->{mes}))
			$data{$i}->{mes} = $results[2];
			if(${$data{$i}{layer}}[0]){
				push @{$data{$i}->{layer}}, $results[1];
			} else {
				$data{$i}->{layer} = [$results[1]];
			}
		}
	}
}

valor("chk_delete,chklist=thermal");

close($fh);
@id = (keys %issue);

$file = "C:\\MentorGraphics\\Valor\\vNPI_TMP\\thermal_results.txt";
open(my $fl, '>', $file) or die "Cannot open file: $!";
# %issue holds the probelms from thermal relief
# %data holds the problems from thermal isolation
print $fl "Missing Thermal Relief Alerts:\n";

@id = (keys %issue);
my %comps = get_data_comp(\@id);
foreach my $i(@id){
	next if $i eq "";
	print $fl "$i\t$comps{$i}{x}\t$comps{$i}{y}\t" . join(", ",uniq(@{$issue{$i}->{layer}})). "\n";
}
print $fl "Low Isolation Width Alerts:\n";
@id = (keys %data);
%comps = get_data_comp(\@id);
foreach my $i(@id){
	print $fl "$i\t$comps{$i}{x}\t$comps{$i}{y}\t$data{$i}->{mes}\t" . join(", ",uniq(@{$data{$i}{layer}})) . "\n" if $data{$i}->{mes};
}

# this will set what kind of board is being used
my $board_thickness = ((get_board_thickness) * 25.4);
$board_thickness  < 2.36 ? $temp  = 0.35 : $temp = 1;

print $fl "Heat Transfer Area:\n";
@id = (keys %spokes_results);
%leads = data_pads("comp_pins");
foreach my $i(keys %leads){
	my $key = ($leads{$i}{attrs} =~ /\.artwork=(.*?)(?:,|$)/g)[0];
	$comps{$key}->{$i} = 1;
	$leads{$i}->{refdes} = $key;
}
foreach my $i(@id){
	my $res = $spokes_results{$i}->{total_result};
	if($res > $temp){
		valor(
			"affected_layer,name=comp_pins,mode=single,affected=yes",
			"display_layer,name=drill,number=4,display=yes",
			"work_layer,name=drill"
		);
		select_pad($i,'comp_pins');
		valor(
			"sel_ref_feat,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative"
		);
		
		my %temp = data_pads("drill",'s');
		my $key = (keys %temp)[0];
		print $fl "$leads{$i}->{refdes}\t$temp{$key}->{x}\t$temp{$key}->{y}\t$res\t" . join (", ", @{$spokes_results{$i}->{layers}}). "\n"
	}
}


close($fl); 
valor("chklist_delete,chklist=thermal");
system(1,"notepad.exe $file");