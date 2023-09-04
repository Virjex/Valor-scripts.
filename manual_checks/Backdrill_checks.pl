#!perl -w

use strict;
use warnings;
use File::Basename;
use vars qw( $temp %issue %data @names @drill_names);

use lib dirname(__FILE__).'\..';
use DFM_Util;

use Test::More tests => 1;
clear_and_reset;
# first fond the back drills
# this hold all the data about the drills in the JOB
our %drill_data = %{get_drill_data()};
Confirm_layers();
# now we got the names sorted
# creating dupe layers

my $rule_factor = 2;

create_testing_layers($rule_factor);

recreate_layers("drills_for_testing");
foreach my $name(@drill_names){
	valor(
		"affected_layer,name=$name,mode=single,affected=yes",
		"sel_copy_other,dest=layer_name,target_layer=drills_for_testing,invert=no,dx=0,dy=0,size=0",
		"affected_layer,name=,mode=all,affected=no"
	);
}

clear_and_reset;
foreach my $name(@names){
	my $collect_data = 0;
	#holds all the backdrills data 
	my %back_drills = data_pads($name);

	# checking for the central X Y
	# the %back_drills holding the current X Y cords of the drill
	foreach my $id(keys %back_drills){
#		pop_up("\$id = $id \$name = $name");
		valor(
			"affected_layer,name=drills_for_testing,mode=single,affected=yes",
			"sel_single_feat,operation=select,x=$back_drills{$id}->{x},y=$back_drills{$id}->{y},tol=0.5,cyclic=yes,shift=no"
		);
		my %normal_drills = data_pads("drills_for_testing",'s');
		for my $normal_drill(keys %normal_drills){
#			pop_up("
#				\$name = $name
#				\$normal_drills{$normal_drill}->{x} = $normal_drills{$normal_drill}->{x} <br> 
#				\$backdrill{$id}->{x} $back_drills{$id}->{x} <br> 
#				\$normal_drills{$normal_drill}->{y} $normal_drills{$normal_drill}->{y}  <br> 
#				\$backdrill{$id}->{y} $back_drills{$id}->{y}");
			if (($normal_drills{$normal_drill}->{x} != $back_drills{$id}->{x}) && ($normal_drills{$normal_drill}->{y} != $back_drills{$id}->{y})){
				pop_up("i found something");
				$issue{missaligment}->{$normal_drill} = {

					backdrill_x => $back_drills{$id}->{x},
					backdrill_y => $back_drills{$id}->{y},
					backdrill_layer => substr($name, 0, -8),

					drill_x => $normal_drills{$normal_drill}->{x},
					drill_y => $normal_drills{$normal_drill}->{y},
				};

			}
		}
		valor("affected_layer,name=,mode=all,affected=no");
	}


	valor(
		"affected_layer,name=$name,mode=single,affected=yes",
		"sel_all_feat"
	);
	my $count = get_select_count;

	valor(
		"affected_layer,name=drills_for_testing,mode=single,affected=yes",
		"sel_ref_feat,layers=,use=select,mode=cover,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative"
	);
	if (get_select_count == 0){
		valor(
			"affected_layer,name=drills_for_testing,mode=single,affected=no",
			"sel_resize,size=$rule_factor"
		);
		$collect_data = 1;
		%{$issue{wrong_size}->{substr ($name,0,-8)}} = data_pads($name);

	} elsif ($count != get_select_count){
		$collect_data = 1;
		valor(
			"affected_layer,name=$name,mode=single,affected=no",
			"sel_reverse",
			"affected_layer,name=$name,mode=single,affected=yes",
			"sel_ref_feat,layers=,use=select,mode=cover,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative",
			"sel_copy_other,dest=layer_name,target_layer=temp,invert=no,dx=0,dy=0,size=0",
			"affected_layer,name=drills_for_testing,mode=single,affected=no",
			"sel_resize,size=$rule_factor",
			"sel_ref_feat,layers=temp,use=filter,mode=touch,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative,include_syms=,exclude_syms="
		);
		remove_layers("temp");
		%{$issue{wrong_size}->{substr ($name,0,-8)}} = data_pads($name,'s');
	}
	if($collect_data){
		valor("affected_layer,name=drills_for_testing,mode=single,affected=yes");
		foreach my $id(keys %{$issue{wrong_size}->{substr ($name,0,-8)}}){
			select_pad($id,$name);
			valor("sel_ref_feat,layers=,use=select,mode=touch,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative");
			my %temp = data_pads("drills_for_testing",'s');
			$issue{wrong_size}->{substr ($name,0,-8)}->{$id}->{via} = $temp{(keys %temp)[0]}->{symbol};
			valor("sel_clear_feat");
		}
		valor("affected_layer,name=,mode=all,affected=no");
	}
}
remove_layers(@names);
create_testing_layers();
# Now we going to loop from the top to the bottom searching for traces touching the back drills

my $top_row = get_layer_row_number_by_name("top");
my $bot_row = get_layer_row_number_by_name("bottom");

for (my $i = $top_row; $i <= $bot_row; $i++){
	my $layer = get_layer_names_by_row($i);
	next if check_for_dielectric($layer);
	valor("filter_set,filter_name=popup,update_popup=no,feat_types=line");
	my $counter = 0;
	# now find what backdrill layers should be affected
	foreach my $name(@names){
		if ($i >= get_layer_row_number_by_name($drill_data{$name}->{start}) && $i <= get_layer_row_number_by_name($drill_data{$name}->{end})){
			++$counter;
			valor("affected_layer,name=$name,mode=single,affected=yes");
		}
	}
	next unless $counter;
	valor(
		"sel_all_feat",
		"affected_layer,name=". get_layer_names_by_row($i). ",mode=single,affected=yes",
		"sel_ref_feat,layers=,use=select,mode=touch,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative,include_syms=,exclude_syms="
	);
	if(get_select_count){
		valor(
			"filter_reset",
			"sel_ref_feat,layers=,use=select,mode=touch,f_types=line\;pad\;surface\;arc\;text,polarity=positive\;negative,include_syms=,exclude_syms="
		);
		foreach my $name(@names){
			my %temp = data_pads($name, 's');
			if(scalar (keys %temp) > 0){
				%{$issue{trace}->{$layer}} = %temp;
			}
		}
	}
	valor("affected_layer,name=,mode=all,affected=no");
}

#my $file = get_result_folder("backdrill.txt");
my $file = 'C:\MentorGraphics\Valor\vNPI_TMP\backdrills.txt';

open(my $fl, '>', $file) or die "Cannot open file: $!";
print $fl "Wrong size:\n";
print $fl "layer \tx \ty \tbackdrill size \tvia size\n";
my @id = (sort keys %{$issue{wrong_size}});
foreach my $i(@id){
	foreach my $key(keys %{$issue{wrong_size}->{$i}}){
		print $fl "$i\t$issue{wrong_size}->{$i}->{$key}->{x}\t$issue{wrong_size}->{$i}->{$key}->{y}\t$issue{wrong_size}->{$i}->{$key}->{symbol}\t$issue{wrong_size}->{$i}->{$key}->{via}\n";
	}
}

print $fl "Backdrill touching trace:\n";
print $fl "Copper layer:\tx\ty\n";

foreach my $layer(keys %{$issue{trace}}){
	foreach my $i(keys %{$issue{trace}->{$layer}}){
		print $fl "$layer\t$issue{trace}->{$layer}->{$i}->{x}\t$issue{trace}->{$layer}->{$i}->{y}\n";
	}
}

print $fl "Backdrill missaligment:\n";
print $fl "backdrill name:\tbackdrill x\tbackdrill y\tdrill x\tdrill y\n";
foreach my $drill(keys %{$issue{missaligment}}){
#	foreach my $id(keys %{$issue{missaligment}->{$drill}}){
		print $fl "$issue{missaligment}->{$drill}->{backdrill_layer}\t$issue{missaligment}->{$drill}->{backdrill_x}\t$issue{missaligment}->{$drill}->{backdrill_y}\t$issue{missaligment}->{$drill}->{drill_x}\t$issue{missaligment}->{$drill}->{drill_y}";
#	}
}
#				$issue{missaligment}->{$normal_drill} = {
#					backdrill_x = $back_drills{$id}->{x},
#					backdrill_y = $back_drills{$id}->{y},
#					backdrill_layer = substr($name, 0, -8),
#					drill_x = $normal_drills{$normal_drill}->{x},
#					drill_y = $normal_drills{$normal_drill}->{y},
#				}

close $fl;
clear_and_reset;
system(1,"notepad.exe $file");

sub Confirm_layers {
	foreach my $i(keys %drill_data){
		push @names, $i if $drill_data{$i}->{type} eq "backdrill";
	}
	pop_up("The known back drills are:  <br> <b>" . join("<br>",@names) . "</b> <br> <br> to add more backdrills. set the drill layers as back drills");
	my %temp = %drill_data;
	%drill_data = %{get_drill_data()};
	if (!(is_deeply(\%temp, \%drill_data))){
		@names=();
		Confirm_layers();
	} else {
		# break out
		@names=();
		foreach my $i(keys %drill_data){
			if ($drill_data{$i}->{type} ne "backdrill"){
				push @drill_names, $i;
			} else {
				push @names, $i;
			}
		}
	}
	valor("affected_layer,name=,mode=all,affected=no");
}

sub create_testing_layers{

	my $rule_factor = shift || 0;
	if(!($rule_factor)){
		@names=();
		foreach my $i(keys %drill_data){
			if ($drill_data{$i}->{type} ne "backdrill"){
				push @drill_names, $i;
			} else {
				push @names, $i;
			}
		}
	}
	return if(!($rule_factor));

	foreach my $name(0..(scalar @names -1)){
		valor("affected_layer,name=$names[$name],mode=single,affected=yes");
		$names[$name] = $names[$name] . "_testing";
		recreate_layers($names[$name]);
		valor(
			"sel_copy_other,dest=layer_name,target_layer=$names[$name],invert=no,dx=0,dy=0,size=0",
			"affected_layer,name=,mode=all,affected=no",
			"affected_layer,name=$names[$name],mode=single,affected=yes",
			"sel_resize,size=-$rule_factor",
			"affected_layer,name=,mode=all,affected=no",
		);
	}
}