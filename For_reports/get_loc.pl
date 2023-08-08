#!perl -w
use warnings;
use Valor;
use IO::File;
use vars qw( $V $JOB $STEP $x $y $layer $measurement );
use subs qw ( valor pop_up );
use Tk;
#####################################################
#													#
#				Main Var decleration				#
#													#
#####################################################

our $V = new Valor;
$JOB = $ENV{JOB};
$STEP = $ENV{STEP};

# Create a new Tk window
my $mw = MainWindow->new;
$mw->title("RefDes Locations");

# Create a label
$mw->Label(-text => "Paste the refdes list")->pack;

# Create a text input box
my $text_input = $mw->Text(
							-width => 40,
							)->pack;

# Create a button
$mw->Button(
	-height => 5,
	-width => 15, 
    -text    => "Get Locations",
    -command => \&button_click
)->pack(-pady => 5);

MainLoop;

sub button_click {
	my $input_text = $text_input->get('1.0', 'end-1c');
    @lines = split("\n", $input_text); 
	if(!$lines[0]){
		pop_up "REFDES was not received to Valor <br>
				re-run this script and add the refdes line by line save the file and close it";
		exit(0);
	}	
	clearAndReset();
	my @xy;

	valor "affected_layer,name=comp_+_top,mode=single,affected=yes" , "affected_layer,name=comp_+_bot,mode=single,affected=yes";
	foreach (@lines){
		my $usedref = $_;
		$V->COM("filter_comp_set,filter_name=popup,update_popup=no,ref_des_names=$usedref");
		$V->COM("filter_area_strt");  
		$V->COM("filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,min_angle=0,max_angle=0");  
		$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p centroidx -o select");
		my $x = ($V->{doinfo}{gCOMPcentroidx});
		if(!${$x}[0]){
			${$x}[0] = "$usedref was not found";
		} else {
			${$x}[0]*=1000;
		}
		$V->DO_INFO("-t eda -e $JOB/$STEP -m script -d COMP -p centroidy -o select");
		my $y = ($V->{doinfo}{gCOMPcentroidy});
			if(!${$y}[0]){
			${$y}[0] = "$usedref was not found";
		} else {
			${$y}[0]*=1000;
		}
		push (@xy , "${$x}[0]\t${$y}[0]" );
		valor "sel_clear_feat";
	}
	$filename = 'C:\MentorGraphics\Valor\vNPI_TMP\ref_des_xy.txt';
	open($fh, '>',$filename) or die "Clound not open file.";
	foreach (@xy){
		print $fh "$_\n";
	}
	close($fh);
	clearAndReset();
	system(1,"notepad.exe $filename");
	$mw->destroy;
}

sub valor{
	while ($_[0] or $_){
		$V->COM(shift);
	}
}

sub pop_up{
	$V->PAUSE(shift);
}

sub clearAndReset {
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


sub clearTempLayer{
	SeleteRadLayer();
	valor("sel_delete");
}
