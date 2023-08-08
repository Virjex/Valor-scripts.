#!perl -w

use strict;
use warnings;
use File::Basename;
use lib dirname(__FILE__).'\..' ;
use DFM_Util;
use vars qw ( $min_pad_size $unit @used_serial %data %issue %info );
use Data::Dumper;
use Tk;

clear_and_reset;

my $mw = MainWindow->new;
my $file = $mw->getOpenFile(-filetypes =>
                            [
                             ['All Files',   '*'],
                             ['Text Files', '.txt'],
                            ]);
if ($file eq ""){
	pop_up("No file was selected. exiting script");
	exit 0;
}

my ($current_side, $top_count, $bot_count);
my $read_lines = 0;
my $last_net_name = "";

if (defined $file and $file ne '') {
    open my $fh, '<', $file or die "Could not open file '$file' $!";
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /Minimum pad size for probing\s+\.{3}\s+(\d+\.\d+)\s+(\w+)/) {
            $min_pad_size = $1;
            $unit = $2;
        }
        # Match the line with TOP or BOTTOM side
        elsif ($line =~ /Nets currently under test for (\w+) side/) {
            $current_side = $1;
            $read_lines = 1; # Start reading lines for data

        }
        elsif ($line =~ /Total number of testpoints/) {
			if ($line =~ /(\d.*)/) {
				$current_side eq "TOP" ? $top_count = $1 : $bot_count = $1;
			}
            last if $current_side eq "BOTTOM";
        }
        elsif ($read_lines && $line =~ /^-/) {
            $read_lines = 0;
        }
        elsif ($read_lines && $line =~ /^\|\s+(.+?)\s+\|\s+\|\s*(\d+)\s+\|\s+(\w+)\s+\|\s+(\d+\.\d+)\s+\|\s+\((\d+\.\d+)\s+(\d+\.\d+)\)/) {
            my ($net_name, $id, $type, $pad_size, $x, $y) = ($1, $2, $3, $4, $5, $6);

            if ($net_name =~ /\S/) {
                $last_net_name = $net_name;
            }
            else {
                $net_name = $last_net_name;
            }

            $data{$current_side}{$net_name}{$id} = {
                'type' => $type,
                'pad_size' => $pad_size,
                'x' => $x,
                'y' => $y,
            };
        }
    }
    close $fh;
	
} else {
    print "No file selected\n";
}

our $top_data = $data{'TOP'};
our $bottom_data = $data{'BOTTOM'};
valor("units,type=$unit",
	"cur_atr_set,attribute=.test_point");

foreach my $pointer(keys %data){
	valor(
		"display_layer,name=$pointer,number=4,display=yes",
		"work_layer,name=$pointer",
		"sel_delete_atr,attributes=.test_point;,pkg_attr=no"
	);
	foreach my $net(keys %{$data{$pointer}}){
		foreach my $qnt(keys %{$data{$pointer}->{$net}}){
			select_pad_x_y_size($data{$pointer}->{$net}->{$qnt}->{x},$data{$pointer}->{$net}->{$qnt}->{y},$pointer,$data{$pointer}->{$net}->{$qnt}->{pad_size});
			undef @used_serial;
		}
	}
}



#	foreach my $net_name (keys %{$data{'BOTTOM'}}) {
#		print "Net name: $net_name\n";
#		my $info = $data{'BOTTOM'}{$net_name};
#		foreach my $id (keys %{$info}) {
#			print "Net: $id\n";
#			print "Type: ", $info->{$id}{'type'}, "\n";
#			print "Pad size: ", $info->{$id}{'pad_size'}, "\n";
#			print "X: ", $info->{$id}{'x'}, "\n";
#			print "Y: ", $info->{$id}{'y'}, "\n";
#		}
#	}


$file = "C:\\MentorGraphics\\Valor\\vNPI_TMP\\tp_x_y_results.txt";
open(my $fh, '>', $file) or die "Cannot open file: $!";
print $fh "Number of TP in file: top- $top_count , bottom- $bot_count\n" .
		"Number of defined TP: top- $info{TOP}->{success}, bottom-$info{BOTTOM}->{success}\n" .
		"List of nun-defined pads:\n";
foreach my $side(keys %issue){

	foreach my $index(keys %{$issue{$side}}){
		print $fh "$side\t$issue{$side}->{$index}->{x}\t$issue{$side}->{$index}->{y}\t$issue{$side}->{$index}->{size}\n";
	}
}


close($fh); 
system(1,"notepad.exe $file");

sub select_pad_x_y_size{
	my ($x ,$y ,$side, $size)= @_;
	valor(
		"sel_clear_feat",
		"sel_single_feat,operation=select,x=$x,y=$y,tol=50.00,cyclic=yes,shift=no",
	);
	my %features = data_pads("$side","s","mm");
	my %hash = map {$_ => 1} @used_serial;
	push ( @used_serial , $features{(keys %features)[0]}->{serial} );
	if (defined $hash{$features{(keys %features)[0]}->{serial}}) {
		my $key = scalar (keys %{$issue{$side}});
		$issue{$side}{$key} = {
			x => $x,
			y => $y,
			size => $size,
		};
		return 0;
	}
	if($features{(keys %features)[0]}->{type} eq 'line'){
		select_pad_x_y_size($x ,$y ,$side, $size);
	} else {
		$features{(keys %features)[0]}->{symbol} =~ /r(.*)/;
		if(($1 / 1000) == $size ){
			valor(
				"sel_change_atr,mode=add,pkg_attr=no"
			);
			$info{$side}->{success} = $info{$side}->{success} + 1 ;
			return 0;
		} else {
			select_pad_x_y_size($x ,$y ,$side, $size);
		}
	}
	return 0;
}