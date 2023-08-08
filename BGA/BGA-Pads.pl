#!perl -w

use strict;
use warnings;
use File::Basename;

use vars qw( $top $bot $sides $temp @issue );

use lib (dirname(__FILE__).'\..');
use DFM_Util;

our $REF;
our @sRef;
our @pRef;
our %issue_data;

clear_and_reset();

$sides = check_comp_sides

# removing old layers from past run
recreate_layers("bga_pins_top","bga_pins_bot","bga_comp_top","bga_comp_bot","pads","sm","sur_top","sur_bot","temp","temp_pins","temp_body");

if ($sides == 0){
	pop_up("No components were found on the baord");
	exit(0);
}	elsif ($sides == 1) {
		valor("display_layer,name=comp_+_top,display=yes,number=1",
						"work_layer,name=comp_+_top");
		# this will check for a BGA on board.
		$top = check_for_BGA("top");
		#seperate refs that are on surfaces or just on pads
		check_surface("top") if $top;
		pads_check("top") if $pRef[0];
		check_sm("top") if $sRef[0];
		
}	elsif ($sides == 2) {
		valor("clear_layers",
						"display_layer,name=comp_+_bot,display=yes,number=1",
						"work_layer,name=comp_+_bot");
		
		$bot = check_for_BGA("bot");
		
		#seperate refs that are on surfaces or just on pads
		check_surface("bot") if $bot;
		
		#go'es over the pads that aint on a surface  
		pads_check("bot") if $pRef[0];
		#go'es over the pads that are on a surface
		check_sm("bot") if $sRef[0];
		
}	elsif ($sides == 3) {
		
		# this is the only part that works ATM
		valor("display_layer,name=comp_+_top,display=yes,number=1",
						"work_layer,name=comp_+_top");
		# this will check for a BGA on board.
		$top = check_for_BGA("top");
		
		#seperate refs that are on surfaces or just on pads
		check_surface("top") if $top;

		pads_check("top") if $pRef[0];

		check_sm("top") if $sRef[0];

		clear_and_reset();
		valor("clear_layers",
						"display_layer,name=comp_+_bot,display=yes,number=1",
						"work_layer,name=comp_+_bot");
		
		$bot = check_for_BGA("bot");
		
		#seperate refs that are on surfaces or just on pads
		check_surface("bot") if $bot;
		#go'es over the pads that aint on a surface  
		pads_check("bot") if $pRef[0];
		#go'es over the pads that are on a surface
		check_sm("bot") if $sRef[0];
}

my @result;

if(!($issue[0])){
	pop_up("No issues were found. <br> exiting script");
	exit 0;
};

my %results = get_data_comp(\@issue);
my $filename = 'C:\MentorGraphics\Valor\vNPI_TMP\Failed_BGA.txt';

open(my $fh, '>',$filename) or die "Clound not open file.";
foreach my $i (sort keys %results) {
	print $fh $results{$i}{side} . "\t$i\t$results{$i}{x}\t$results{$i}{y}\tFailed on: $issue_data{$i}{test}\t" . ($issue_data{$i}{'pad'} ? "Pad:$issue_data{$i}{'pad'}\t" : "") . ($issue_data{$i}{'solder area'} ? "Solder area:$issue_data{$i}{'solder area'}" : "" ) ."\n";
}
close($fh);

system(1,"notepad.exe $filename");

sub BGA_lead_selection{
	
	my $side = shift;
	my $ref = shift;
		
	valor(	"filter_reset",
						"display_layer,name=". ($side eq "top" ? "top" : "bottom") .",display=yes,number=4",
						"display_layer,name=comp_+_$side,display=yes,number=1",
						
						"work_layer,name=comp_+_$side",
						"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=".$ref,
						"filter_area_strt",
						"filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0");
						
		# Selection of the leads
		valor("affected_layer,name=bga_pins_$side,mode=single,affected=yes",
						"filter_reset",
						"sel_ref_feat,layers=bga_pins_$side,use=select,mode=touch,f_types=pad,polarity=positive\;negative");
						
}

sub pads_check{	
	clear_and_reset();
	my $side = shift eq "top" ? "top" : "bot";
	
	# the main control going to be the size of @pRef
	
	# now do this for all the componenets
	for(my $i = 0; $i <= scalar @pRef -1; $i++ ){
		BGA_lead_selection($side, $pRef[$i]);	
		
		my $pin_count = get_select_count();
		
		#selection of the pads and getting the SM 
		valor("filter_set,filter_name=popup,update_popup=no,feat_types=pad",
						"display_layer,name=comp_+_$side,display=no,number=1",
						"affected_layer,name=" . ($side eq "top" ? "top" : "bottom") . ",mode=single,affected=yes",
						"filter_atr_set,filter_name=popup,attribute=.smd,entity=feature,condition=yes",
						"filter_atr_set,filter_name=popup,attribute=.pad_usage,entity=feature,condition=yes,option=toeprint",
						"sel_ref_feat,layers=bga_pins_top,use=select,mode=touch,f_types=pad,polarity=positive\;negative",
						"sel_copy_other,dest=layer_name,target_layer=pads,invert=no,dx=0,dy=0,size=0",
						
						"clear_layers",
						"affected_layer,name=,mode=all,affected=no",
						"filter_reset",
						
						"display_layer,name=sm$side,display=yes,number=1",
						"work_layer,name=sm$side",
						"sel_ref_feat,layers=pads,use=filter,mode=touch,f_types=pad,polarity=positive\;negative",
						"sel_copy_other,dest=layer_name,target_layer=sm,invert=no,dx=0,dy=0,size=0",
						
						"display_layer,name=pads,display=yes,number=1",
						"work_layer,name=pads",
						);
		
		#SM check to find the smallest
		my @sm_symbols = extract_unique_symbols(data_pads("sm"));
		my $smalles_SM = $sm_symbols[0];

		foreach my $j (1 .. $#sm_symbols) {
			my ($current_value) = ($sm_symbols[$j] =~ /([+-]?\d+(?:\.\d+)?)/);
			my ($smallest_value) = ($smalles_SM =~ /([+-]?\d+(?:\.\d+)?)/);

			if (defined($current_value) && defined($smallest_value) && $current_value < $smallest_value) {
				$smalles_SM = $sm_symbols[$j];
			}
		}
		
		my %data = data_pads("pads");
		my @id = (keys %data);
		# ive chnagee the data_pads to use the serial of the pad
		valor("sel_multi_feat,operation=select,feat_types=pad,resize_by=0,include_syms=" . $data{$id[0]}{'symbol'});

		if(get_select_count() != $pin_count){
			# reselect the BGA and get the REFDES
			
			# show the comp layer as 1
			# show the SM as 2
			# show the copper as 3
			# high light the issue

			# add the SM check. smallets vs pad size


			valor("sel_clear_feat",
			
							"display_layer,name=comp_+_$side,display=yes,number=1",
							"display_layer,name=sm$side,display=yes,number=2",
							"display_layer,name=" . ($side eq "top" ? "top" : "bottom") . ",display=yes,number=3",
							"display_layer,name=pads,display=yes,number=4",
							"work_layer,name=pads",
							"filter_set,filter_name=popup,update_popup=no,include_syms=".$data{$id[0]}{'symbol'},
							"clear_highlight",
							"filter_highlight,layer=",
							"display_layer,name=pads,display=no,number=4",
							"work_layer,name=comp_+_$side",
							"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$pRef[$i]",
							"sel_ref_feat,layers=pads,use=filter,mode=touch,f_types=pad,polarity=positive\;negative",
							"pan_selected","zoom_selected","sel_clear_feat");
						
			# get the uni symbols and set them to the $issue_data{$pRef[$i]}{'pad'}			
			
			my @unique_pads = extract_unique_symbols(data_pads("pads"));
			
			push(@issue,$pRef[$i]);
			$issue_data{$pRef[$i]}{'pad'} = join(", ",@unique_pads);
			$issue_data{$pRef[$i]}{'test'} = "Has non-uniform soldering pads";	
			
			pop_up("Refdes: ". $pRef[$i] .". Has non-uniform soldering pads <br>
							Pad sizes: " . join(", ",@unique_pads));
			clear_and_reset();
		} else {

			valor("sel_clear_feat");
			if (($smalles_SM =~ /([+-]?\d+(?:\.\d+)?)/)[0] < ($data{$id[0]}{'symbol'} =~ /([+-]?\d+(?:\.\d+)?)/)[0] && scalar @sm_symbols > 1){
				valor("display_layer,name=comp_+_$side,display=yes,number=1",
								"display_layer,name=sm$side,display=yes,number=2",
								"display_layer,name=" . ($side eq "top" ? "top" : "bottom") . ",display=yes,number=3",
								
								"work_layer,name=sm$side",
								"filter_set,filter_name=popup,update_popup=no,include_syms=$smalles_SM",
								"filter_highlight,layer=",
				
								"filter_reset",
								
								#select and show compoent
								"work_layer,name=comp_+_$side",
								"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$pRef[$i]",
								"filter_area_strt",
								"filter_area_end,layer=,filter_name=popup,operation=select",
								"pan_selected","zoom_selected","sel_clear_feat","filter_reset"
								);
				
				# get the uni symbols and set them to the $issue_data{$pRef[$i]}{'pad'}		
				
				push(@issue,$pRef[$i]);
				$issue_data{$pRef[$i]}{'pad'} = $data{$id[0]}{'symbol'};
				$issue_data{$pRef[$i]}{'solder area'} = $smalles_SM;
				$issue_data{$pRef[$i]}{'test'} = "Smallest SM";
				pop_up("BGA: ". $pRef[$i] .". failed on smallest SM check");
			}
		}
		
		recreate_layers("pads","sm");
	}
}

sub check_sm{
# FINAL NOTES
# check if the SM that are used for the surface is eq.
# if not then its a fail. if they are the same use the SM as a solder area.
# check the pads.
# get all the sizes of the pads. 
# first remove all the pads that are on a surface
# as soon as a solder area aint the same its a fail.

# clear the slayers
clear_and_reset();

valor("affected_layer,name=sm,mode=single,affected=yes",
				"affected_layer,name=pads,mode=single,affected=yes", 
				"affected_layer,name=temp,mode=single,affected=yes",
				"sel_delete");

	my $side = shift eq "top" ? "top" : "bot";	
	#working by refdes
	for(my $i = 0; $i < scalar @sRef; $i++ ){

		clear_and_reset();

		#get the pads and copy them
		BGA_lead_selection($side, $sRef[$i]);	
		valor("filter_set,filter_name=popup,update_popup=no,feat_types=pad",
					"display_layer,name=comp_+_$side,display=no,number=1",
					"affected_layer,name=" . ($side eq "top" ? "top" : "bottom") . ",mode=single,affected=yes",
					"filter_atr_set,filter_name=popup,attribute=.smd,entity=feature,condition=yes",
					"filter_atr_set,filter_name=popup,attribute=.pad_usage,entity=feature,condition=yes,option=toeprint",
					"sel_ref_feat,layers=bga_pins_$side,use=select,mode=touch,f_types=pad,polarity=positive\;negative",
					"sel_copy_other,dest=layer_name,target_layer=pads,invert=no,dx=0,dy=0,size=0",
					
					"filter_reset",
					"clear_layers",
					"affected_layer,name=,mode=all,affected=no",
					
					# remove the pads that are on surface but first get the SM.
					"display_layer,name=pads,display=yes,number=1",
					"work_layer,name=pads",
					
					# this will select the pads that are on a surface.
					"sel_ref_feat,layers=sur_$side,use=filter,mode=touch,f_types=surface,polarity=positive\;negative,include_syms=,exclude_syms="
					);
		
		# this count is for what pad are located on a surface.
		my $pad_count = get_select_count();
		valor(
					"affected_layer,name=sm$side,mode=single,affected=yes",
					"sel_ref_feat,layers=sur_$side,use=select,mode=touch,f_types=surface,polarity=positive\;negative",
					
					"sel_copy_other,dest=layer_name,target_layer=sm,invert=no,dx=0,dy=0,size=0",
					
					"affected_layer,name=sm$side,mode=single,affected=no",
					"display_layer,name=sm,display=yes,number=4",
					"work_layer,name=sm"
					);

		# get the size of the SM
		my %data = data_pads("sm");
		my @id = (keys %data);
		# select all SM using single size (selecting just the sm that is on a surface)
		valor("sel_multi_feat,operation=select,feat_types=pad,resize_by=0,include_syms=" . $data{$id[0]}{'symbol'});
		
		# this checks if the amount of pads on a surface = SM of one size.
		# if this test fails we will move to the next refdes.
		if(get_select_count() != $pad_count){

			valor("display_layer,name=comp_+_$side,display=yes,number=1",
							"display_layer,name=sm$side,display=yes,number=2",
							"display_layer,name=" . ($side eq "top" ? "top" : "bottom") . ",display=yes,number=3",
							"display_layer,name=sm,display=yes,number=4",
							"work_layer,name=sm",
							
							"filter_set,filter_name=popup,update_popup=no,include_syms=".$data{$id[1]}{'symbol'},
							"clear_highlight",
							"filter_highlight,layer=",
							
							"display_layer,name=sm,display=no,number=4",
							#select and show compoent
							"work_layer,name=comp_+_$side",
							"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$sRef[$i]",
							"filter_area_strt",
							"filter_area_end,layer=,filter_name=popup,operation=select",
							"pan_selected","zoom_selected","sel_clear_feat","filter_reset"
							);
			
			push(@issue,$sRef[$i]);
			$issue_data{$sRef[$i]}{'test'} = "Diffrent solder masks on a surface.";
			
			pop_up("Refdes ". $sRef[$i] .". <br> Failed on Surface check due to diffrent solder masks on a surface.");
			
			recreate_layers("sm","pads","temp");
			
			next;
		}
		
		
		
		# if we reached here the sm cleareness of the pad on a surface will be used as the main solder area.
		my $solder_area = $data{$id[0]}{'symbol'}; 
		# now we got the pads of the surface on a the sm layer. we going to need to move it to temp layers.
		valor("sel_move_other,target_layer=temp");
		#get the SM and copy it to the layer. and removing what ever is on a surface.
		valor(
					"clear_layers",
					
					"display_layer,name=sm$side,display=yes,number=4",
					"work_layer,name=sm$side",
					
					"sel_ref_feat,layers=pads,use=filter,mode=touch,f_types=pad,polarity=positive\;negative",
					"sel_copy_other,dest=layer_name,target_layer=sm,invert=no,dx=0,dy=0,size=0",
					
					"display_layer,name=pads,display=yes,number=4",
					"work_layer,name=pads",
					"sel_ref_feat,layers=temp,use=filter,mode=touch,f_types=pad\;surface,polarity=positive\;negative",
					"sel_delete",
					
					"clear_layers",
					"affected_layer,name=,mode=all,affected=no",
					
					"display_layer,name=sm,display=yes,number=4",
					"work_layer,name=sm",
					
					"sel_ref_feat,layers=temp,use=filter,mode=touch,f_types=pad\;surface,polarity=positive\;negative",
					"sel_delete",
					
					
					);
		# here ill need to get the size of the SM and pads.
		# $solder_area is the area of solder on a surface
		
	#	my @unique_sm = extract_unique_symbols(data_pads("sm"));
		my @unique_pads = extract_unique_symbols(data_pads("pads"));
		recreate_layers("temp");
		
		for(my $o = 0; $o < scalar @unique_pads ; $o++){
			
			valor("clear_layers",
							"filter_reset",
							"affected_layer,name=pads,mode=single,affected=yes",
							"filter_set,filter_name=popup,update_popup=no,include_syms=$unique_pads[$o]",
							"filter_area_strt",
							"filter_area_end,layer=,filter_name=popup,operation=select",
							"display_layer,name=sm,display=yes,number=4",
							"work_layer,name=sm",
							"filter_reset",
							"sel_ref_feat,layers=temp,use=select,mode=touch,f_types=pad\;surface,polarity=positive\;negative",
							"sel_move_other,target_layer=temp,invert=no,dx=0,dy=0,size=0");
							
			my @unique_sm = extract_unique_symbols(data_pads("temp"));
			
			for (my $j = 0; $j < scalar @unique_sm; $j++){
				my $sm_size = ($unique_sm[$j] =~ /([+-]?\d+(?:\.\d+)?)/)[0];
				my $pad_size = ($unique_pads[$o] =~ /([+-]?\d+(?:\.\d+)?)/)[0];				
				
				# true = the SM is larger then the pad. and the pad is the solder area.
				# false = the SM is smaller then the pad. so the sm is the solder area.
				if ($sm_size - $pad_size <= 0){
					if ($unique_sm[$j] eq $solder_area){
						next;
					} else {
						# we going to need to show compoent + zoom
						
						# high light failed size of the SM
						# show the copper side
						valor(
										"display_layer,name=comp_+_$side,display=yes,number=1",
										"display_layer,name=sm$side,display=yes,number=2",
										"display_layer,name=". ($side eq "top" ? "top" : "bottom") .",display=yes,number=3",
										
										"affected_layer,name=pads,mode=single,affected=no",
										"work_layer,name=comp_+_$side",
										"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$sRef[$i]",
										"sel_ref_feat,layers=pads,use=filter,mode=touch,f_types=pad,polarity=positive\;negative",
										"pan_selected",
										"zoom_selected",
										"filter_reset",
										
										"work_layer,name=sm". ($side eq "top" ? "top" : "bot"),
										"filter_set,filter_name=popup,update_popup=no,include_syms=".$unique_sm[$j],
										"filter_set,filter_name=popup,update_popup=no,feat_types=pad",
										"filter_highlight,layer=",
										
										"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$pRef[$i]",
										"filter_area_strt",
										"filter_area_end,layer=,filter_name=popup,operation=select",
										"pan_selected","zoom_selected","sel_clear_feat","filter_reset"
										
										);
						push(@issue,$sRef[$i]);
						next;
						pop_up("	Refdes: $pRef[$i] <br>
											The SM clearce is smaller then the SM release on the surface <br>
											Solder area on a surface: $solder_area <br>
											Solder area on a pad: $unique_pads[$o] <br>
											");
											
						$issue_data{$sRef[$i]}{'pad'} = $unique_pads[$o];
						$issue_data{$sRef[$i]}{'solder area'} = $solder_area;
						$issue_data{$sRef[$i]}{'test'} = "SM is smaller then the SM release on the surface.";
					}
					
					
				} else{
					if ($unique_pads[$o] eq $solder_area) {
						
						next; 
					} else {
						# im going to need to get all the SM on the surface 
						valor(
										"display_layer,name=comp_+_$side,display=yes,number=1",
										"display_layer,name=sm". ($side eq "top" ? "top" : "bot") .",display=yes,number=2",
										"display_layer,name=". ($side eq "top" ? "top" : "bottom") .",display=yes,number=3",
										"display_layer,name=sm,display=yes,number=4",
										
										"affected_layer,name=pads,mode=single,affected=no",
										"work_layer,name=comp_+_$side",
										"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$sRef[$i]", # "option=bga",
										"sel_ref_feat,layers=pads,use=filter,mode=touch,f_types=pad,polarity=positive\;negative",
										"pan_selected",
										"zoom_selected",
										"filter_reset",
						
										"affected_layer,name=sm$side,mode=single,affected=yes",
										"sel_ref_feat,layers=,use=select,mode=touch,f_types=pad,polarity=positive\;negative,include_syms=,exclude_syms=",
										"sel_copy_other,dest=layer_name,target_layer=sm,invert=no,dx=0,dy=0,size=0",
										"affected_layer,name=sm$side,mode=single,affected=no",
										
										"work_layer,name=sm",
										"sel_ref_feat,layers=sur_$side,use=filter,mode=touch,f_types=pad\;surface,polarity=positive\;negative,include_syms=,exclude_syms=",
										"sel_reverse",
										"sel_delete",
										
										"filter_set,filter_name=popup,update_popup=no,include_syms=".$unique_sm[$j],
										"filter_set,filter_name=popup,update_popup=no,feat_types=pad",
										"filter_highlight,layer=",
										"display_layer,name=sm,display=no,number=4",
										);
										
										
						pop_up("
											Refdes: $sRef[$i] <br>
											The pad is smaller then the SM clearce on the surface <br>
											Solder area on a surface: $solder_area <br>
											Solder area on a pad: $unique_pads[$o]");
											
						push(@issue,$sRef[$i]);
						
						$issue_data{$sRef[$i]}{'pad'} = $unique_pads[$o];
						$issue_data{$sRef[$i]}{'solder area'} = $solder_area;
						$issue_data{$sRef[$i]}{'test'} = "The pad is smaller then the SM release on the surface";
						next;
					}
				}
				
			}
		
		}
		
		recreate_layers("sm","pads","temp");
	
	}
}

sub extract_unique_symbols {
    my (%data) = @_;
    my %unique_symbols;

    foreach my $line_number (keys %data) {
        my $entry = $data{$line_number};
        my $symbol = $entry->{symbol};
        $unique_symbols{$symbol} = 1;
    }

    my @unique_symbols = keys %unique_symbols;
    return @unique_symbols;
}

#should return an array of what's on a surface and what's on the bottom.
sub check_surface{
	my $side = shift;

	undef @pRef;
	undef @sRef;
	
	for(my $i = 0 ; $i <= $#$REF; $i++){
		
		# first select the component
		# select it's leads
		# check if there is a surface
		
		# ill need to select a spesific component and use it's lead.
		BGA_lead_selection($side,${$REF}[$i]);
		
		# use the leads to check for SM on surface?
		# or use a sized surface? to avoid small surfaces + tear drops 300 sq mil as 
		
		valor(
			"display_layer,name=comp_+_". ($side eq "top" ? "top" : "bot") .",display=no,number=1",
			"filter_set,filter_name=popup,update_popup=no,feat_types=surface",
			"sel_ref_feat,layers=bga_pins_$side,use=select,mode=touch,f_types=pad,polarity=positive\;negative",
			"filter_reset"
		);
						
						
		if(get_select_count() != 0){
			
			# the leads located on a surface
			# this list will go to the sm checks
			# copying the surface to a temp layer
			
			valor("sel_copy_other,dest=layer_name,target_layer=sur_$side,invert=no,dx=0,dy=0,size=0",
				"display_layer,name=sur_$side,display=yes,number=5",
				"work_layer,name=sur_$side","filter_atr_set,filter_name=popup,attribute=.tear_drop,entity=feature,condition=yes",
				"filter_area_strt",
				"filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0"
			);
			valor("sel_delete") if get_select_count;
			BGA_lead_selection($side,${$REF}[$i]);
				valor("work_layer,name=sur_$side",
					"sel_ref_feat,layers=bga_pins_top,use=select,mode=touch,f_types=pad,polarity=positive\;negative");
			push(@sRef,${$REF}[$i]) if get_select_count != 0;
			clear_and_reset;
		} else {
			# the leads aint locacted on a surface
			# this list will go to the pad checks
			
			push(@pRef,${$REF}[$i]);
			
		}
	}
	scalar @sRef > 0 ? return 1 : return 0;
}

# get the leads of the BGA
# using the leads i can get a better hold of the PADS
sub check_for_BGA{
	
	@sRef = undef;
	@pRef = undef;
	
	my $side = shift eq "top" ? "top" : "bot";
	valor(
		"filter_atr_set,filter_name=popup,attribute=_comp_type_component,entity=component,condition=yes,option=bga",
		"filter_area_strt",
		"filter_area_end,layer=,filter_name=popup,operation=select"
	);
					
	pop_up("Check that what is selected are BGA's. Manually select more components if neccessary.");
					
	$REF = selected_refdes_full;
	
	# task is to check if copnent was drawn. if not get it's CAD form.
	
	if (get_select_count() != 0 ) {
					
				drawing($side,"library");
				
				# now we going to check if all what we draw is the same amount of components we needed.
				valor(
					"display_layer,name=bga_comp_$side,display=yes,number=4",
					"work_layer,name=bga_comp_$side",
					"filter_reset",
					"sel_all_feat"
				);
				
				if(get_select_count != (scalar @{$REF})){
					my %used = map {$_ => 1} @{$REF};
					my %pads = data_pads("bga_comp_$side");
					my @id = ( keys %pads );
					foreach my $j (@id) {
						my $test = ($pads{$j}->{attrs} =~ /\.artwork=(.*?)(?:,|$)/g)[0];
						delete($used{$test});
					}
				
					valor(
						"sel_clear_feat",
						#filter to select
						"display_layer,name=bga_comp_$side,display=no",
						"filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=" . join(";",keys %used),
						"filter_area_strt",
						"filter_area_end,layer=,filter_name=popup,operation=select"
					);
					
					drawing($side,"cad");
					clear_and_reset;
					valor(
						"display_layer,name=temp_pins,display=yes,number=4",
						"work_layer,name=temp_pins",
						"sel_move_other,target_layer=bga_pins_$side,invert=no,dx=0,dy=0,size=0",
						"display_layer,name=temp_body,display=yes,number=4",
						"work_layer,name=temp_body",
						"sel_move_other,target_layer=bga_body_$side,invert=no,dx=0,dy=0,size=0"
					);
				}
				
				# removing lines from the package 
				valor(
					"display_layer,name=bga_pins_$side,display=yes,number=1",
					"work_layer,name=bga_pins_$side",
					"filter_reset",
					
					"filter_set,filter_name=popup,update_popup=yes,feat_types=line",
					"filter_area_strt",			"filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0",
					"sel_delete",
					"filter_reset",
					
					
					# dealing with first lead sq 
					"sel_cont2pad,match_tol=1,restriction=,min_size=5,max_size=9999,suffix=+++",
					
					"filter_set,filter_name=popup,update_popup=no,include_syms=s*",
					"filter_area_strt",	"filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0",
					
					"sel_delete"
					);
		return 1;
	}
	return 0;
}

sub drawing{
	
	my $side = shift;
	my $mode = shift;
			pop_up("WARNING some components are without a VPL. <br>
					this wasnt tested yet.") if $mode eq "cad";
	
	valor(
		# drawing pins of the BGA
		"comp_draw_to_layer,
		layer_mode=$mode,
		side=" . ($side eq "top" ? "top" : "bottom") .",
		layer_name_top=". ( $mode eq "cad" ? "temp_pins" : $side eq "top" ? "bga_pins_top" : "") .",
		layer_name_bot=". ( $mode eq "cad" ? "temp_pins" : $side eq "top" ? "" : "bga_pins_bot") .",
		draw_pins=yes,
		draw_pins_mode=surface,
		draw_centroids=no,
		name=no,
		draw_board_outline=no,
		fit2box=no,
		draw_font=24,
		draw_selected=yes,
		use_placed_comp_only=no",
		
		# drawing package of the  BGA
		"comp_draw_to_layer,
		layer_mode=$mode,
		side=" . ($side eq "top" ? "top" : "bottom") .",
		layer_name_top=". ( $mode eq "cad" ? "temp_body" : $side eq "top" ? "bga_comp_top" : "") .",
		layer_name_bot=". ( $mode eq "cad" ? "temp_body" : $side eq "top" ? "" : "bga_comp_bot") .",
		comp_mode=surface,
		draw_pins=no,
		draw_pins_mode=surface,
		draw_centroids=no,
		name=no,
		draw_board_outline=no,
		fit2box=no,
		component_outline_mode=Body,
		draw_font=24,
		draw_selected=yes,
		use_placed_comp_only=no");
}