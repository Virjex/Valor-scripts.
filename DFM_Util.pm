#perl -w

package DFM_Util;
=begine

	Welcom to the DFM_Util module this is the manifest of this module.								
	Arthor: Sam V. Miles																			
	Purpose: a Utilty module to store common used function at one place. for best practice			

	side-note:																				
	caller.pl*:
				This is a main script that controls. what is called and when.						
				there is a swtich with it. based on a few arguments.
				First the caller set's up setting.ini file at the following path:
				It calls the script if its has been set with-in the local setting file				
				the local setting located at the temp folder
				Path to the local settings file:
				C:\MentorGraphics\Valor\vNPI_TMP\settings.ini
				this folder is getting cleared every time Valor is being opened.
				if there a miss-matching JOB or STEP arguments with in the ENV Hash
				the local setting keeping a track of those arguments for "Safe keeping"
				as the detching may-lose those arguments. due to the way that the System call is being
				used to be able to detach from "Valor" and realse the graphic station.
				As the caller always having the current JOB and STEP arguments it can check agesnt the
				settings.ini. and act accordenly.
				the check are as followed				
				
				1. if there isn't a GUI active. it will call it and detaching it from Valor
					and freeing the Graphic station. for use and giving us access to the GUI.
				
				2. if there is a GUI active it will check if the JOB and STEP is the same.
					the check is between the $ENV{JOB} and $ENV{STEP} to the JOB and STEP within the 'local' setting.ini*	
					as caller.pl is always called from Valor it holds the %ENV from Valor.
					with the current $JOB and $STEP
				
					if a macth is found then it will call he script using the same method of system just with out ditaching it from valor.
					if there isnt a match it will reset the the 'local' settings.ini with the new JOB and STEP and no SCRIPT.
					and will kill off the old GUI.
				
				think of the caller.pl as a controller. its job is just to call to currect script or GUI.
	
	'local 'setting.ini:
				the 'local' settings.ini is a settings file to help the scrip of caller to control what being called and what to look for
				and what to call.
	
																									
	Public functions	- made to be used at other scripts (support sub's)							
																									
	valor				- a multi-lined valor com calls support		|commonly used|
						Arguments input:
						String - command OR string array - commands				
------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	surface_to_pad		- chaching anything to a pad from the selected.
						
						Arguments input:
						- None -
------------------------------------------------------------------------------------------------------------------------------------------------------------
	create_layers		- crates layers with the name/s that are getting passed into it
	
						Arguments input:
						String - names OR string array
------------------------------------------------------------------------------------------------------------------------------------------------------------
	remove_layers		- deletes layers with the names that are getting passed into it
	
						Arguments input:
						String - names OR string array
------------------------------------------------------------------------------------------------------------------------------------------------------------
	recreate_layers		- deletes and creates the layers back using thier names
	
						Arguments input:
						String - names OR string array
------------------------------------------------------------------------------------------------------------------------------------------------------------
	pop_up				- a PAUSE call. to display a pop up to alert user's or-						
						used to get user input			
						
						Arguments input:
						String - massage
						
------------------------------------------------------------------------------------------------------------------------------------------------------------

	clean_all_att		- clearing all attributes from selected pad_usage
						
						Arguments input:
						- Void -
------------------------------------------------------------------------------------------------------------------------------------------------------------

	clear_and_reset		- clearing all filters and layers. returning to a defult state.	
	
						Arguments input:
						- Void -
						
------------------------------------------------------------------------------------------------------------------------------------------------------------

	call_script			- calling the script of caller.pl* the main method to be able re-attched	
						back to Valor

						Arguments input:
						1. String : name of the script. + pathing from the orgin folder of this file (DFM_Util)
						
------------------------------------------------------------------------------------------------------------------------------------------------------------

	validation			- Validate if the user is a DFm Engineer working for Flextronics			
						*copied from the global scripts. validtion if the user is a DFM-Engineer
						
						Arguments input:
						- Void -
------------------------------------------------------------------------------------------------------------------------------------------------------------				
	select_pad			- to be able to select a feature from a spesific layer (i.e. pad)*
						as the ID of the features are layer based. a spesification of layer name and ID is reqired.
						getting the ID of the feature is already using the layer name. it should work together.
						deleting features wont shift the stack. nor creating a new feature after deletion.
						
						Arguments input:
						1. interger : padID
						2. string : layer
------------------------------------------------------------------------------------------------------------------------------------------------------------
	check_comp_sides	- checks and returns what kind of comps are localted with in the job
	
						Arguments input:
						- none -
						
						0 - no comps
						1 - top only
						2 - bottom only
						3 - top and bottom
------------------------------------------------------------------------------------------------------------------------------------------------------------	
	pads_data			-returns a hash that holds all the data from pad type feature is based on numaric keys a with sub keys as the following list.
						it has a requiremt to have spesific layers to be pulled.
						
						Arguments input:
						1. String: layer name.
						
						hash sub keys:
						
							x => $x,
							y => $y,
							symbol => $symbol,
							polarity => $polarity,
							dcode => $dcode,
							angle => $angle,
							mirror => $mirror,
							serial => $serial, #ID
							net => $net,
							attrs => $attrs,

						accessing after returning:
						

private function	- used with in the module and should NEVER be used at other scripts			
																									
	build_title			- used to rebuild the title of the of the Valor graphic display 			
						used to be able to switch back to valor to call a script of caller.pl*	
						
						Arguments input:
						- none -

=cut
use strict;
use warnings;
use Valor;
use vars qw ( $V $JOB $STEP $SCRIPT $temp );
use subs qw ( valor );
use Symbol qw(gensym qualify_to_ref);
use Win32::API;
use File::Basename;

our @EXPORT_OK;


our $pathing = dirname(__FILE__);
our $settings = 'C:\MentorGraphics\Valor\vNPI_TMP\settings.ini';

#rcom experements
#$V = new Valor('rcom' => 1);

$V					= 	Valor->new();
our $JOB			=	$ENV{JOB};
our $STEP			=	$ENV{STEP};

#####################################################################################
#				SUB-RUTINE TO HANDLE MULTI-LINE VALOR COM CALLS						#
#####################################################################################
sub valor{
	while ($_[0] or $_){
		$V->COM(shift);
	}
}

sub info{
	$V->DO_INFO(shift);
}

sub get_row_number{
	info("-t layer -e $JOB/$STEP/" . shift . " -d ROW");
	$V->{doinfo}{gROW} =~ /([0-9]+)/;
	return $1;
}
#####################################################################################
#							SUB-RUTINE TO CLEAR ALL ATT								#
#####################################################################################
sub clean_all_att{
	#yea im lazy 
	#all of this is just a copy from the triloogy
	$V->COM("sel_delete_atr,attributes=.add_pilot_mode;.added_connection;.aoi_cpbm;.aoi_cpcu;.aoi_drbm;.aoi_drcu;.aoi_value;.ar_pad_drill_bottom_max;.ar_pad_drill_bottom_min;.ar_pad_drill_inner_max;.ar_pad_drill_inner_min;.ar_pad_drill_top_max;.ar_pad_drill_top_min;.ar_sm_drill_bottom_max;.ar_sm_drill_bottom_min;.ar_sm_drill_top_max;.ar_sm_drill_top_min;.ar_sm_pad_bottom_max;.ar_sm_pad_bottom_min;.ar_sm_pad_top_max;.ar_sm_pad_top_min;.area;.area_name;.artwork;.avoid_pattern_fill;.avoid_shave;.ball_pad;.bga;.bit;.board_mark;.bond_name;.bonding_pad_comp;.bonding_profile;.break_away;.brk_point;.bump_pad;.canned_text;.cdr14_stages;.cdr14_zone_type;.cdr_val;.clear_dont_opt;.color;.combined_size;.comp;.comp_height_area;.comp_name;.connection_id;.copper_defined;.covered;.critical_net;.critical_tp;.cut_line;.deferred;.depth;.detch_comp;.detch_orig_type;.detch_smooth;.detch_tapering;.dfm_added_shave;.dont_repair;.drawing_magnify;.drawing_outline;.drawing_profile;.drawing_template;.drc_assembly_lyrs;.drc_bend_keepout;.drc_board;.drc_comp_height;.drc_comp_keepin;.drc_comp_keepout;.drc_etch_lyrs;.drc_etch_lyrs_all;.drc_etch_lyrs_bit;.drc_max_height;.drc_mech;.drc_min_height;.drc_pad_keepout;.drc_plane_keepout;.drc_ref_des;.drc_route_keepin;.drc_route_keepout;.drc_tp_keepin;.drc_tp_keepout;.drc_trace_keepout;.drc_via_keepout;.drill;.drill_first_last;.drill_flag;.drill_noopt;.drill_sr_zero;.drill_stage;.dummy_pin;.dxf_dimension;.ecmp_max_value;.ecmp_min_value;.ecmp_name;.ecmp_type;.ecmp_value;.eda_define_imp_line;.eda_dimension_id;.embedded;.enlarged_clearance_size;.et_align;.et_stamp;.etch_comp_addition;.etm_constant_drill_usage;.etm_pin_name;.extended;.feature_fill_margin;.feature_ignore;.feed;.fiducial_name;.fiducial_rdlist;.foot_down;.force_galv_etch;.full_plane;.generated_net_point;.geometry;.gold_plating;.hatch;.hatch_border;.hatch_serrated_border;.hp3070_probe_access;.ignore_action;.imp_constraint_id;.imp_info;.imp_line;.imp_line_candidate;.imp_orig_lw;.imp_polyline_id;.imp_type;.infeed_speed;.inp_net_name;.is_capped;.jtag_component_id;.laser_via_pad;.lpol_surf;.lyr_prf_ref;.moat;.mount_hole;.n_electric;.net_name;.net_physical_type;.net_point;.net_spacing_type;.netpt_pt_ind;.nfl;.nfp;.nomenclature;.non_tp;.notest_req;.npth_pad;.orbotech_barcode_string;.orbotech_plot_stamp;.orig_features;.orig_size_inch;.orig_size_mm;.orig_surf;.orig_tooling_holes_set;.osp_pad;.out_break;.out_drill_optional;.out_flag;.out_nc_ignore;.out_nc_verif;.out_orig;.out_rout_optional;.out_scale;.output_dcode;.pad_usage;.padstack_id;.partially_covered;.partially_embedded;.patch;.pattern_fill;.pf_optimized;.pilot_hole;.pilot_hole_offset_along;.pilot_hole_offset_perpend;.pin_name;.pitch;.plated_type;.plating_bar;.pnl_place;.pressure_foot;.pth_pad;.retract_speed;.rf;.rout_chain;.rout_cutoff_feed;.rout_flag;.rout_grid_x_offset;.rout_grid_y_offset;.rout_message;.rout_plated;.rout_plunge_feed;.rout_plunge_mode;.rout_plunge_val_a;.rout_plunge_val_b;.rout_plunge_val_c;.rout_plunge_val_d;.rout_plunge_val_e;.rout_plunge_val_f;.rout_plunge_val_v1;.rout_plunge_val_v2;.rout_pocket_direction;.rout_pocket_feed;.rout_pocket_mode;.rout_pocket_overlap;.rout_repeat;.rout_snake_direction;.rout_tool;.rout_tool2;.rout_type;.shave;.sip;.sliver_fill;.slr_shave_reason_ind;.smd;.smooth;.solder_defined;.soldermask_define_no_edits;.source_llayer;.spacing_req;.speed;.split_clear;.spo_h_fact;.spo_h_mode;.spo_h_val;.spo_move_center;.spo_p_fact;.spo_p_mode;.spo_p_val;.spo_s_fact;.spo_s_mode;.spo_s_val;.spo_shape;.spo_shape_rotate;.spo_shape_stretch;.spo_w_fact;.spo_w_mode;.spo_w_val;.step_numbering;.string;.string_angle;.string_font;.string_justification;.string_mirrored;.surface_outline_widths;.tapering_feature;.tear_drop;.test_point;.test_potential;.test_req;.testpoint_name;.testprobe_diameter;.tie;.tie_plane;.tiedown;.tooling_hole;.tooling_holes_set;.vcut;.via_pad;.via_type;.via_type_pad;_label;,pkg_attr=no");
	
}

sub recreate_layers{
	while ($_[0] or $_){
		$temp = shift;
		remove_layers($temp);
		create_layers($temp);
	}
}

sub create_layers{
	$V->DO_INFO("-t matrix -e $JOB/matrix -d NUM_LAYERS");
	my $num = ($V->{doinfo}{gNUM_LAYERS});
	$num =~ s/\'//g;
	$num ++;
		while ($_[0] or $_){
			valor("matrix_insert_row,job=$JOB,matrix=matrix,row=$num",
			"matrix_refresh,job=$JOB,matrix=matrix",	
			"matrix_add_layer,job=$JOB,matrix=matrix,layer=".shift.",row=$num,context=misc,type=document,polarity=positive,sub_type=");
			$num ++;
	}
}

sub remove_layers{
	while ($_[0] or $_){
		$V->VOF();
		$V->COM("delete_layer,layer=".shift);
		$V->VON();
	}
}

sub get_select_count{
	valor "get_select_count"; 
	return $V->{COMANS};
}
#####################################################################################
#				SUB-RUTINE TO SELECT FEATURE BY ID(AND LAYER)						#
#####################################################################################
sub select_pad{
	my $id = shift;
	my $layer = shift;
	$V->COM("sel_layer_feat,operation=select,layer=$layer,index=$id");
}

#####################################################################################
#							SUB-RUTINE TO CALL SCRIPTS								#
#####################################################################################
sub call_script{
	my $name = shift;
	open(my $fh, '+<', $settings);
	my @lines = <$fh>;
	$lines[0]="SCRIPT:$pathing\\$name.pl\n";
	seek $fh ,0,0;
	print $fh @lines;
	close $fh;
	swtich_widnows();
}

#####################################################################################
#			SUB-RUTINE TO CREATE LOCAL SETTINGS FOR SCRIPT CALLING					#
#####################################################################################
sub create_local_settings_file{
	
	open(my $fh, '>', $settings);
	print $fh "SCRIPT:\n";
	print $fh "JOB:$JOB\n";
	print $fh "STEP:$STEP\n";
	close($fh);
	
}

#####################################################################################
#			SUB-RUTINE TO BUILD THE TITE OF VALOR'S GRAPHIC DISPLAY					#
#####################################################################################
sub _build_title{
	
	if (-e $settings) {
	#if the settings file exists
	# this will be used to call to a script to run with in Valor but first validate if it's the same $JOB and same $STEP
	open(my $fh, '<', $settings);
	while (my $line = <$fh>) {
		if ($line =~ /JOB:(.*)/) {
			$JOB = $1;
		} elsif ($line =~ /STEP:(.*)/){
			$STEP = $1;
		}
	}
	close($fh);
	#for the first run
	}
	return "Graphic Station: $JOB [Step: $STEP]";
}

#####################################################################################
#			SUB-RUTINE TO SWITCHING WINDOWS TO BE ABLE RUN SCRIPTS					#
#####################################################################################
sub swtich_widnows{
	
	my $title = _build_title();
	
	# Define the FindWindow function from the user32.dll library
	my $findWindow = Win32::API->new('user32.dll', 'FindWindow', ['P', 'P'], 'N');
	my $keybdEvent = Win32::API->new('user32.dll', 'keybd_event', ['N', 'N', 'L', 'L'], 'N');

	# Call the FindWindow function to get the window handle
	my $windowHandle = $findWindow->Call(0, $title);

	# Check if the window handle was found
	if ($windowHandle) {
    # Bring the window to the front
    Win32::API->new('user32.dll', 'SetForegroundWindow', ['N'], 'N')->Call($windowHandle);
	Win32::API->new('user32.dll', 'SetActiveWindow', ['N'], 'N')->Call($windowHandle);
	
    # Send the key press of Shift+F12 for script activation.
    my $VK_CONTROL = 0x10;
    my $VK_F2 = 0x7B;
    my $KEYEVENTF_EXTENDEDKEY = 0x0001;
    my $KEYEVENTF_KEYUP = 0x0002;

    $keybdEvent->Call($VK_CONTROL, 0, $KEYEVENTF_EXTENDEDKEY, 0);
    $keybdEvent->Call($VK_F2, 0, $KEYEVENTF_EXTENDEDKEY, 0);
    $keybdEvent->Call($VK_F2, 0, $KEYEVENTF_EXTENDEDKEY | $KEYEVENTF_KEYUP, 0);
    $keybdEvent->Call($VK_CONTROL, 0, $KEYEVENTF_EXTENDEDKEY | $KEYEVENTF_KEYUP, 0);
	
	#print "Window brought to front.\n";
} else {
    #print "Window not found.\n";
}
	
	
}
#####################################################################################
#							SUB-RUTINE TO SELECT USING FILTER						#
#####################################################################################
sub filter_select{
valor("filter_area_strt,",
		"filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no");
}
#####################################################################################
#				SUB-RUTINE TO CLEAR ALL FILTERS AND LAYER SELECTION					#
#####################################################################################
sub clear_and_reset {
	# Clears selects, highlights, layers, and resets filters

	$V->VOF;
		valor("zoom_home"
			,"clear_highlight"
			,"sel_clear_feat"
			,"filter_reset,filter_name=popup"
			,"filter_atr_reset"
			,"cur_atr_reset"
			,"affected_layer,name=,mode=all,affected=no"
			,"clear_layers"
			,"zoom_refresh");
	$V->VON;
}
#####################################################################################
#				SUB-RUTINE TO CALL THE POP UP TO GET USER INPUT						#
#####################################################################################
sub pop_up{
	$V->PAUSE(shift);
}

sub get_layer_names_by_row{
	info("-t matrix -e $JOB/matrix -m script -d ROW -p name -u no -s " . shift);
	return ${$V->{doinfo}{gROWname}}[0];
}

sub get_layer_names_by_type{
	my @names;
	my $type = shift;
	info("-t matrix -e $JOB/matrix");
	my $layer_count = $V->{doinfo}{gNUM_ROWS};
	foreach my $_row(@{$V->{doinfo}{gROWrow}}){
		my $row = ($_row - 1);
		#skip empty rows		
		if(${$V->{doinfo}{gROWlayer_type }}[$row] eq $type){
			push @names,${$V->{doinfo}{gROWname}}[$row];
		};
	}
	return @names;
}

sub get_comp_side{
	$temp = shift;
	$V->VOF();
	info("-t comp -e $JOB/$STEP/top/$temp -m display -d SIDE -u no");
	if($V->{STATUS}){
		$V->VON();
		return 'top';
	}
	$V->VON();
	return 'bottom';
}

#####################################################################################
#				SUB-RUTINE TO CHECK IF THERE IS A TOP & BOTTOM COMPS				#
#####################################################################################
sub check_comp_sides{
	#if STATUS = 0 then its fine
	my $STAT;
	my $counter = 0; 
	$V->VOF();
		valor("affected_layer,name=comp_+_top,mode=single,affected=yes");
	if($V->{STATUS} == 0){
		$counter = 1;
		valor("affected_layer,name=comp_+_top,mode=single,affected=no");
	}
		valor("affected_layer,name=comp_+_bot,mode=single,affected=yes");
	if($V->{STATUS} == 0){
		if($counter == 0){
			$counter = 2;
		} else {
			$counter = 3;
		}
		valor("affected_layer,name=comp_+_bot,mode=single,affected=no");
	}
	$V->VON();
	return $counter;
}

sub check_for_layer{
	$V->VOF;
	my $layer;
	while ($_[0] or $_){
		$layer = shift;
		valor("display_layer,display=yes,number=1,name=$layer");
		if ($V->{STATUS}){
			$V->VON;
			return $layer;
		}
	}
	$V->VON;
	return 0;
}
sub get_board_thickness{
	my $calculated_thickness;
	my $TempFile = ($ENV{VALOR_TMP} . "/infoout");
	$V->COM("info,args=-t job -e $JOB -m tab_delim -d ATTR -u no ,out_file=$TempFile,write_mode=replace,units=inch");
	open(INFO_FILE,"<$TempFile") || die "Cannot open $TempFile file.\n";
	while ( <INFO_FILE> ){
		my ($foo,$attr,$attrval) = split("\t");
		if ($attr =~ /.board_thickness/){
			my $temp_thickness_value = $attrval;
			my (  $numeric_value,  $trash) =  split (" ",$attrval);
			$calculated_thickness = sprintf("%.6f",$numeric_value);
			print ("Board Thickness numeric:  " . $calculated_thickness . "\n");
		}
	}
	close(INFO_FILE);
	unlink($TempFile);
	return $calculated_thickness;
}

sub get_cu_weight_value {
my $layer = shift;
my $unit = shift;

$unit = $unit eq "mil" ? 1.37 : $unit eq "mm" ? 0.0348 : $unit eq "inch" ? 0.0014 : 0.0014;

my ($weigth, $cu_thickness);
my $counter = 0;
#----------------- Loop in the attributes of the layer -------
info("-t layer -e $JOB/$STEP/$layer -m script -d ATTR");
	foreach my $_attr(@{$V->{doinfo}{gATTRname}}) {
		if ( $_attr eq ".copper_weight") {
			my @fields_per_line = ('');
			$weigth = $V->{doinfo}{gATTRval}[$counter];
			($weigth, my $other_string) = split(" ", $weigth);
			if (($weigth eq '') || ($weigth eq '0')) {
				$weigth='0.5';
				pop_up("No copper copper weight was found. setting 0.5 Oz as defult!");
			}
			$cu_thickness = $weigth*$unit;
		}
		$counter = $counter + 1;
	}
	return $cu_thickness;
}

sub data_pads{
	my $layer = shift;
	my $mode = shift || '';
	my $units = shift || 'inch';
	my $file = "C:\\MentorGraphics\\Valor\\vNPI_TMP\\pad_ID.txt";
	valor("info,args=-t layer -e $JOB/$STEP/$layer -m script -d FEATURES -u no" . ($mode eq "s" ? " -o select" : "") . " ,out_file=$file,write_mode=replace,units=$units");
	my $line_number = 0;
	my %data;
	open(my $fh, '<', $file) or die "Cannot open file: $!";

	while (my $line = <$fh>) {
		chomp $line;
		
	#	next unless $line =~ /^#P/;   
		if ($line =~ /^#P/){
			my @line = split ' ', $line;
			my $line_number = $. - 1;  
			my ($x, $y, $symbol, $polarity, $dcode, $angle, $mirror) = @line[1..7];
			my ($serial_net_attrs) = $line[8];
			my ($serial, $net, $attrs) = split ';', $serial_net_attrs;
			$data{$serial} = {
				type => 'pad',
				x => $x,
				y => $y,
				symbol => $symbol,
				polarity => $polarity,
				dcode => $dcode,
				angle => $angle,
				mirror => $mirror,
				serial => $serial,
				net => $net,
				attrs => $attrs,
			};
			
		} elsif ($line =~ /^#S/){
			my @line = split ' ', $line;
			my $line_number = $. - 1;  
			my ($polarity, $dcode, ) = @line[1..2];
			my ($serial_net_attrs) = $line[3];
			my ($serial,$net, $attrs) = split /;/, $serial_net_attrs;
			$data{$serial} = {
				type => 'surface',
				polarity => $polarity,
				dcode => $dcode,
				serial => $serial,
				net => $net,
				attrs => $attrs,
			};
		} elsif ($line =~ /^#L/){
			my @line = split ' ', $line;
			my $line_number = $. -1;
			my ($xs , $ys, $xe, $ye, $symbol, $polarity , $dcode, $serial_net_attrs) = @line[1..8];
			my ($serial, $net, $attrs) = split ';', $serial_net_attrs;
			$data{$serial} = {
				type => 'line',
				xs => $xs,
				ys => $ys,
				xe => $xe,
				ye => $ye,
				x => ($xs + $xe)/2,
				y => ($ys + $ye)/2,
				symbol => $symbol,
				polarity => $polarity,
				dcode => $dcode,
				serial => $serial,
				net => $net,
				attrs => $attrs,
				width =>  _round(sqrt( ($xs - $xe)**2 + ($ys - $ye)**2 ) + (($symbol =~ /([+-]?\d+(?:\.\d+)?)/)[0] /1000),6),
			};
		}
	}
	close($fh);
	return %data;	
}

sub _round($$){
  my ($value, $places) = @_;
  my $factor = 10**$places;
  return int($value * $factor + 0.5) / $factor; # +0.5 is magical sauce to do rounding instead of truncating
}

sub selected_refdes_full{
	info("-t eda -e $JOB/$STEP -m script -d COMP -p refdes -o select");		
	return $V->{doinfo}{gCOMPrefdes};
}

sub selected_refdes{
	info("-t eda -e $JOB/$STEP -m script -d COMP -p refdes -o select");		
	my $refz = ($V->{doinfo}{gCOMPrefdes});
	return ${$refz}[0];
}


sub create_checklist{
	# this will create a check list from scratch. and if it exists. it will delete it and crate a new one in its place.
	my $listname = shift;
	# checking for the existing checklists.
	info("-t step -e $JOB/$STEP -d CHECKS_LIST");
	foreach my $checkname(@{$V->{doinfo}{gCHECKS_LIST}}){
		print ("checkname is: " . $checkname . "\n");
		$V->VOF;
			valor("chklist_delete, chklist=checklist"); 
		$V->VOF;
		if ($listname =~ /$checkname/){
			pop_up("WARNING: $checkname already exists. CONTINUE SCRIPT will delete results.");
			valor("chklist_delete, chklist=$checkname"); 
		}
	}
	valor("chklist_create,chklist=$listname");
}

sub return_list{
	my ($ref_arry) = @_;
	return join(", ",@$ref_arry);
}
sub surface_to_pad{
	# better keep the only one layer active
	valor("sel_contourize,accuracy=0,break_to_islands=yes,clean_hole_size=3,clean_hole_mode=x_and_y",
		"sel_cont2pad,match_tol=1,restriction=,min_size=5,max_size=9999,suffix=+++",
		"get_work_layer"
		);
	my $layer = $V->{COMANS};
	$V->VOF();
		valor("delete_layer,layer=$layer+++");
	$V->VON();
	
}

sub get_data_comp{
	my @lines = @{$_[0]};
	my %issue;
	valor("affected_layer,name=comp_+_top,mode=single,affected=yes" , "affected_layer,name=comp_+_bot,mode=single,affected=yes");
	foreach (@lines){
		my $usedref = $_;
		$V->COM("filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$usedref");
		$V->COM("filter_area_strt");  
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select");  
		info("-t eda -e $JOB/$STEP -m script -d COMP -p centroidx -o select");
		my $x = ($V->{doinfo}{gCOMPcentroidx});
		if(!${$x}[0]){
			${$x}[0] = "$usedref was not found";
		} else {
			${$x}[0]*=1000;
		}
		info("-t eda -e $JOB/$STEP -m script -d COMP -p centroidy -o select");
		my $y = ($V->{doinfo}{gCOMPcentroidy});
			if(!${$y}[0]){
			${$y}[0] = "$usedref was not found";
		} else {
			${$y}[0]*=1000;
		}
		info("-t eda -e $JOB/$STEP -m script -d COMP -p SIDE -o select");
		my $side = ($V->{doinfo}{gCOMPside});
		${$side}[0] = "$usedref was not found" if(!${$side}[0]);
		valor("sel_clear_feat");
		$issue{$usedref} = {
			x => ${$x}[0],
			y => ${$y}[0],
			side => ${$side}[0],
		};
	}
	valor("affected_layer,name=comp_+_top,mode=single,affected=no" , "affected_layer,name=comp_+_bot,mode=single,affected=no");
	return %issue;
}

# to be able to use this module functions without the "DFM_Util::"
sub import {
    my $caller = caller;
    no strict 'refs';  # allow symbolic references

    # iterate through the symbol table
    foreach my $name (keys %{__PACKAGE__ . "::"}) {
        next if $name eq 'BEGIN';   # don't export BEGIN blocks
        next if $name eq 'import';  # don't export this sub
        next if $name =~ /^[A-Z]/;  # skip special symbols

        # export the symbol
        if (defined &{__PACKAGE__ . "::$name"}) {
            *{$caller . "::$name"} = \&{__PACKAGE__ . "::$name"};
        }
    }
}

sub draw_component{
	
	my $side = shift;
	my $mode = shift;
	my $layer_naming = shift || "temp";
			pop_up("WARNING some components are without a VPL. <br>
					this wasnt tested yet.") if $mode eq "cad";
	
	valor(
		# drawing pins of the BGA
		"comp_draw_to_layer,
		layer_mode=$mode,
		side=" . ($side eq "top" ? "top" : "bottom") .",
		layer_name_top=". $side eq "top" ? $layer_naming . "_pins_top" : "") .",
		layer_name_bot=". $side eq "top" ? "" : $layer_naming . "_pins_bot") .",
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
		layer_name_top=".  $side eq "top" ? $layer_naming . "_comp_top" : "") .",
		layer_name_bot=".  $side eq "top" ? "" : $layer_naming . "_comp_bot") .",
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