#!perl -w

use strict;
use warnings;
use vars qw ( $V $JOB $STEP );
use Valor;
use Tk;

our $V 				= 	Valor->new();
$JOB				=	$ENV{JOB};
$STEP				=	$ENV{STEP};

my $checklistname =('nvidia_dfa');
my 	@checksgroup	=	('valor_assembly_component', 'valor_assembly_pin2pad'	,'valor_assembly_component'); 
my 	@erfgroup	=	('comp_spacing_std', 'pintopad_common_checks'	,'component_common_checks');

# Create a button and pack it
my $mw = MainWindow->new;
my $label = $mw->Label(-text => "Select The DFA")->pack;
my $button = $mw->Button(
  -text => "DFA 1",
  -command => sub { 
					create_dfa1();
					$mw->destroy;
					},
)->pack;

my $button2 = $mw->Button(
  -text => "DFA 2",
  -command => sub { 
					create_dfa2(); 
					$mw->destroy;
				},
)->pack;

# Run the Tk event loop
MainLoop;

sub create_dfa1{
	
	create_checklist("_1");
	
}

sub create_dfa2{
	@checksgroup	=	('valor_assembly_component', 'valor_assembly_pin2pad'	,'valor_assembly_component','valor_assembly_testpoint'); 
	@erfgroup	=	('comp_spacing_std', 'pintopad_common_checks'	,'component_common_checks', 'testpoint_common_checks');
	create_checklist("_2");
	
}


sub create_checklist {
	$checklistname = $checklistname.shift;
	my $counter = 1;
	my $line2num =0;
	my $qty_of_checks = scalar @checksgroup;
	my $qty_of_erfs = scalar @erfgroup;	
		if ($qty_of_checks != $qty_of_erfs)
		{
			pop_up("WARNING: There are some missing ERF models or actions for checklist creation, script will exit");
			exit (0);
		}
###############################################################################
#		Need to ensure Checklist doesn't exist before creating
###############################################################################	
	$V->DO_INFO ("-t step -e $JOB/$STEP -d CHECKS_LIST");

	foreach my $checkname(@{$V->{doinfo}{gCHECKS_LIST}})
	{
		print ("checkname is: " . $checkname . "\n");
		if ($checklistname =~ /$checkname/)
		{
			pop_up("WARNING: $checklistname already has results. CONTINUE SCRIPT will delete results.");
			valor("chklist_delete, chklist=$checklistname"); 
		}
		#---------------------Delete any Checklist empty or with the name "checklist" -------------------
		if ($checklistname =~ /checklist/)
		{
			#$V->PAUSE("WARNING: checklist call checklist will be delete.");
			valor("chklist_delete, chklist=checklist");
		}

		#-------------------------------------------------------------------------------------------------
	} 
	valor("chklist_create,chklist=checklist",
			"chklist_show,chklist=checklist",
			"chklist_rename,chklist=checklist,newname=$checklistname");	
######################################################
	while ($counter <= $qty_of_checks)
		{
		
		foreach my $indv_check (@checksgroup)
				{
					my $First_check = shift @checksgroup;
					my $First_erf = shift @erfgroup;
					print (".. adding $First_check \n");
					valor("chklist_single,action=$First_check,show=no"
						,"chklist_pclear"
						,"chklist_erf,chklist=$First_check,nact=1,erf=$First_erf"
						,"chklist_pcopy,chklist=$First_check,nact=1"
						,"chklist_close,chklist=$First_check"
						,"chklist_ppaste,chklist=$checklistname,row=$line2num");
					$line2num++;
				}
		$counter++;
		}
}

sub valor{
	while ($_[0] or $_){
		$V->COM(shift);
	}
}

sub pop_up{
	$V->PAUSE(shift);
}
