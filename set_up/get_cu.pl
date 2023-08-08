#!perl -w

use strict;
use warnings;
use File::Basename;
use lib (dirname(__FILE__).'\..');
use vars qw( @LAYERS_TYPE @WEIGHT_VALUES @COPPER_LAYERS $V $JOB $STEP $TMP_DIR $MW $PROGRESS_FOLDER);

use DFM_Util;
use Valor;

$V 					=	Valor->new();
$JOB				=	$ENV{JOB};
$STEP				=	$ENV{STEP};
$TMP_DIR			=	$ENV{VALOR_TMP};

#------------Search across the job layers for copper layers ----------
$V->DO_INFO("-t matrix -e $JOB/matrix");
foreach my $_row2(@{$V->{doinfo}{gROWrow}}) {
	my $row = ($_row2 - 1);
	#skip empty name layers
	next if(${$V->{doinfo}{gROWtype}}[$row] eq "empty");
	#skip non-Board layers
	next if(${$V->{doinfo}{gROWcontext}}[$row] eq "misc");
	#skip non-Board layers
	next if(${$V->{doinfo}{gROWlayer_type}}[$row] eq "dielectric");
		#----- Group the copper layers in an array --------
		if ((${$V->{doinfo}{gROWlayer_type}}[$row] eq "signal")  && (${$V->{doinfo}{gROWcontext}}[$row] eq "board") ||
			(${$V->{doinfo}{gROWlayer_type}}[$row] eq "mixed")  && (${$V->{doinfo}{gROWcontext}}[$row] eq "board") ||
			(${$V->{doinfo}{gROWlayer_type}}[$row] eq "power_ground")  && (${$V->{doinfo}{gROWcontext}}[$row] eq "board")) {
				my $layer = ${$V->{doinfo}{gROWname}}[$row];
				get_cu_weight_value ("$layer");
				push @COPPER_LAYERS, ("$layer");
				push @LAYERS_TYPE, ("signal");
		}
}

#	
#	support
#

$V->COM("get_job_path,job=$JOB");
my $JOBPATH = $V->{COMANS};
my $layers_list = $JOBPATH.'\support\layers.ini';

my $i = scalar @LAYERS_TYPE;

open(my $fh, '>', $layers_list);
for(my $i = 0; $i <= scalar @LAYERS_TYPE; $i++){
	print $fh, "layer:$i name:$COPPER_LAYERS[$i] value:$WEIGHT_VALUES[$i]";
}
close($fh);

sub get_cu_weight_value {
#--------------Variables --------------------
my $layer           =   $_[0];
my $weigth;
my $counter         =   0;
#----------------- Loop in the attributes of the layer -------
	$V->DO_INFO("-t layer -e $JOB/$STEP/$layer -m script -d ATTR");
		foreach my $_attr(@{$V->{doinfo}{gATTRname}}) {
			if ( $_attr eq ".copper_weight") {
					my @fields_per_line = ('');
					$weigth = $V->{doinfo}{gATTRval}[$counter];
					print ("Value found for layer $layer on attribute $_attr is :$weigth  \n");
                    ($weigth, my $other_string) = split(" ", $weigth);
                    if (($weigth eq '') || ($weigth eq '0')) {
                        $weigth='0.5';
                        $V->COM("set_attribute,type=layer,job=$JOB,name1=$STEP,name2=$layer,name3=,attribute=.copper_weight,value=$weigth");
                        }
                    my $value_string = $weigth;
                    my $thickness_factor = 0.0014;
					my $cu_thickness = $thickness_factor*$value_string;
					$V->COM("set_attribute,type=layer,job=$JOB,name1=$STEP,name2=$layer,name3=,attribute=.copper_thickness,value=$cu_thickness");
					push @WEIGHT_VALUES, ("$value_string");
				}
			$counter = $counter + 1;
			}
}







































































=begine
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&#&@@@@@
@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@## //(&(%@@@@@@
@@@@@@@%@.@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*,.%#%(,%,@@@@@@@@
@@@@@@@@@..*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&, */@&@/,..@@@@@@&%@@
@@@@@@@@&/ *./@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#* /%%@@@#*,.@@@#(#,&@%@@
@@@@@@@@@&, @% (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#.,/(&@@@@@/.*%/...,,.#&@@@@
@@@@@@@@@@%  %@* (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/*/*#@@@@@@@(.   ,,*** (*@@@@@@
@@@@@@@@@@@, (@@@. (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#(,.*@@@@@@@%#   ,**//, .*@@@@@@@@
@@@@@@@@@@@%  &@@@@  (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*..(#@@@@@@@@@   .////,. ,@@@@@@@@@@
@@@@@@@@@@@@%  @@@@&%  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*,./*@@@@@@@@@@(  ,//*/*. (@@@@@@@@@@@@
@@@@@@@@@@@@@/  @@@@@@/  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,,/*&@@@@@@@@@@@/ .*//**. /(@@@@@@@@@@@@@
@@@@@@@@@@@@@@,  @@@@@@@* .@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#,*(*@@@@@@@@@@@@@/ *///** .(@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@  *@@@@@@@@%..%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*(**/@@@@@@@@@@@@@#,.*///* .*&@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&  *@@@@@@@@@@. *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#,,%@@@@@@@@@@@@@@& *////. .%@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%   @@@@@@@@@@@* ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.%@@@@@@@@@@@@@@@& *///*. /@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@,   @@@@@@@@@@@@( .%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,&@@@@@@@@@@@@@@@@*.////*, #@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@, , ,@@@@@@@@@@@@@  ,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(.&@@@@@@@@@@@@@@@@.,////, (@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@, *  %@@@@@@@@@@@@@%  *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ .&@@@@@@@@@@@@@@@@@@@@**@@@@@@@@@@@@@@@&*.,////* #@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@* *. *@@@@@@@@@@@@@@@.  ##@@@@@@@@@@@@@@@@@@@@@@.  /@@@@.@@@@@@@@@@@@@@@@@@@@.,@@@@@@@@@@@@@@%*..////*,.@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@( ./  /@@@@@@@@@@@@@@&  @@@@@@@@@@@@@@@@@@@@@..@@@@@@@(&@@@@@@@@@@@@@@@@@@&.,@@@@@@@@@@@@@@ ..////// ,@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@  */  .@@@@@@@@@@@@@@. @@@@@@@@@@@@@@@@@@@*.@@@@@@@@ @@@@@@@@@@@@@@@@@@& .@@@@@@@@@@@@@*..*//////.(@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@(  //, .#@@@@@@@@@@@#. #@@@@@@@@@@@@@@@@/ @@@@@@@@.. *,#@@@@@@@@@@@@@&.,@@@@@@@@@@@@%..*////**./#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@(  ,//,. %&@@@@@@@@@@  #@@@@@@@@@@@@@@% @@@@@@@@( /// @@@@@@@@@@@@@, *@@@@@@@@@@@#*..//*//, ,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%  *///, %&@@@@@@@@@, *@@@@@@@@@@@@% @@@@@@@@% ///*(@@@@@@@@@@@@. /@@@@@@@@@@@/ .*////* .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  .///, @&@@@@@@@@*..@@@@@@@@@@&,&@@@@@@@# ////.@%*@*@@@@@@%. *@@@@@@@@@@@,. ////,..(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@, .*//, @@@@@@@@@/..%@@@@@@@&,/@@@@@@@@ ///*. @@@@@.@@@@&  *@@@@@@@@@@&..,////,./&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(.,*//. %@@@@@@@@*,/@@@@@@#(@@@@@@@@ ////.,@@@@@@#*@@# .%@@@@@@@@@@/  ////,,**@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*.*//..@@@@@@@@* ,&@@@./@@@@@@@@.*///, &@@@@@@@,.#  %@@@@@@@@@%..,////*.*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.*//,.@@@@@@@/  ,@/.@@@@@@@@**///. #(@@@@@@@@.  #@@@@@@@@@%  /////./,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.,*/*./@@@@@@&* ,.@@@@@@@@.///// &#.@@@@@@@%,.(@@@@@@@@@# .////*,,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,*/* /@@@@@@/ &@@@@@@& /////.#@#*@@@@@@&  (@@@@@@@@@, *////...@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.//. /@@@& &@@@@@@, ///// #@@%,@@@@@@, *@@@@@@@@&  *///, ,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@% *//. @#.&@@@@@@ ,*////.%@@@(.@@@@@(.*@@@@@@@@# ,////*.,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@( */*  @@@@@@& .*//// @@@@@%.@@@@, /@@@@@@@@(.,.///, (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@( .,@@@@@@@(@..*/*.@@@@@@@ %@@* (@@@@@@@(,,@@# ,. &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@, #@@@@@#/#@@@/  ,@@@@@@@%.,   #@@@@@@@(,(@@@@@. %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@% .@@@@@@. *@@@@@%./@@@@@@@&./  %@@@@@@@(/@@@@@@@@@. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  (@@@@@% ./, %@@@@@*,&@@@@@@&  (@@@@@@&,@@@@@@@@@@@@& ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* ,@@@@@/  *///*.,@@@@@@/*@@@@@* *@@@@@@/./* %@@@@@@@@@@@/ ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@& ,%@@@@@.  ///////*.*@@@@&./@&@. *@@@@@@  *////* %@@@@@@@@@@, (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.,#@@@@@(  ,/////*  **.,&@@@@%*#,//@@@@@@  *////////, %@@@@@@@@@* %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.*@@@@@@   */////.*@/../*,,@@@@@. *@@@@@@. *///* *//////, @&@@@@@@@. &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.*@@@@@@.  ,/////,*&@@@@*.*/, %@@@&(.@@@@* .*///..@@/ */////,,  #@@@@@@. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,./@@@@@@@  ./////*.,@@@@@@@@,./, .@@@%@.(@*..*/// .&@@@@@# */////* ,%@@@@@@ .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,*(@@@@@@@   //////,,#@@@@@@@@@@%,...,@@@@@/  .//// .&@@@@@@@@@/ */// /@@@@@@@@(/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#/(@@@@@@@   //////*..@@@@@@@@@@@@@@. *&*/@@@#/ ,/// .@@@@@@@@@@@@@@* ,@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/*&@@@@@@@/,**///*..(@@@@@@@@@@@@@@/ ,@@@/*@@@@@ .* *&@@@@@@@@@@@@% ,#@@@@@@%  ** ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.*@@@@@@@@@#... *@@@@@@@@@@@@@@@, .@@@@@%,%@@@@* *%@@@@@@@@@@@& .#@@@@@@(  /////, /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#  @@@@@@@@@@#..@@@@@@@@@@@@@#. .@@@@@@.  #@@@@(,@@@@@@@@@@# ,#@@@@@@( .///////*.,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#/.*/. @@@@@@@@@@@@&./@@@@@@@@&.  @@@@@@&  . (@@@@@,#@@@@@@%.,*@@@@@@(  ///////*  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.,///. &@@@@@@@@@@@@&((@@@@%,  @@@@@@@  *.. .%@@@@*/@@@@...@@@@@@&  *//////,..@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* .///, #@@@@@@@@@@@@@@/./, .@@@@@@@..*//. ..(@@@@/*@#..%@@@@@@  *//////. *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ .///,./@@@@@@@@@@@@@@,  (@@@@@@*.*//,   ..,@@@@.  ,@@@@@@  *//////. %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ .///*.,@@@@@@@@@@&/ #@@@@@@@#.///*,.(* . .@@@/ @@@@@@&  //////. %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ .////.,%@@@@@@&*.#@@@@@@@#  //* ,&@#* .. @ #@@@@@@, ,/////, ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/..*///. /@@@%..&@@@@@@@**@@@@(  *@@%# ., (@@@@@/  *////* .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.,*///..**  @@@@@@@@@/&@@@@@@@ /@@@#,.(@@@@@,   ////  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.,///   @@@@@@@@@/#@@@@&  @@@@@@@..&@@@& ,@@&*., /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/.,  *@@@@@@@@@#*@@@. , /@@@@@@% %@@@. .@@@@@  ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%  *@@@@@@@@@#.@#  //////* ,@@ #@@@  * .@@@@@&#*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(  %@@@@@@@@@*. .//////////,.@ ,@@& .///,,%@@@@@%*/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@% ./@@@@@@@@@* */////////. #@@(.%@%  /////*./@@@@@&/,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,. %@@@@@@@@@# *///////* ,%@@@@ .@(  *///*  *,,&@@@@&%*%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@, /@@@@@@@@@@( *////// .@@@@@@@@ &.% ,///./@, ,*/%@@@@@%/*%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,,*@@@@@@@@@@# ,////,.&@@@@@@@@@**.@. //* %@@@/ *,,(@@@@@@/.%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,(@@@@@@@@@@# **//* &@@@@@@@@@@@/(@% ,/*.@&@@@@#,.,.%@@@@@@#,(%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.,*&@@@@@@@@@&(..*//, %@@@@@@@@@@@#@@@, /./@@@@@@@@&/,,..&@@@@@@*.(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,*,%@@@@@@@@@@@/ .*//, #@@@@@@@@@@@@@@@@ ,.@@@@@@@@@@@@,,/. #@@@@@@/,/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,(,%@@@@@@@@@@@/ .,//, %@@@@@@@@@@@@@@@@#,.@@@@@@@@@@@@@@(,/. *@@@@@@@,*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/.*%@@@@@@@@@@@/..,**/, %@@@@@@@@@@@@@@@@@/#@@@@@@@@@@@@@@@@@,,,..&@@@@@@/*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,/,(@@@@@@@@@@@(. ,*/*, *%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. *..(@@@@@@@*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/*.*@@@@@@@@@@@#(.**///, ,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ .*.*@@@@@@@&/#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..*(@@@@@@@@@@#(.,*///*. *#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&. *.#@@@@@@@@*/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.,/@@@@@@@@@@(,**/////...&@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..*,(@@@@@@@@&*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/. @@@@@@@@@@/,/*//////, .%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.**/@@@@@@@@@,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%, ,#@@@@@@#%,/**//////,.*(%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.,*./@@@@@@@@/#@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/.*%@@@@@#..***//////../&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,.*, ./@@@@&@%/@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,/@@@@@%*.**//////*. (&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.,/**...(@@&@,&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*,#@@%. .**//////,..%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.*/////,. ,/@*%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#,/@@.  ,*/////*. *%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.,/////*/*.*%%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%.,#*, .*/////*..(&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&**..*/////.(&&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@&..(@#..*////...%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#/  ,/*/.(@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@ (*&@(.,///..*@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*,*/*(@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@,%&@@#,./,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@(#@@@%,..,(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%&@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@(@@@@@.,/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&./#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@/#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  
=cut