#!perl -w

use strict;
use warnings;
use Tk::BrowseEntry;
use Tk;

# Create the main window
my $mw = MainWindow->new;
$mw->title("FAB DATA");

# Create the top frame with a label
my $top_frame = $mw->Frame()->pack(-side => 'top', -fill => 'x');
$top_frame->Label(-text => "Job entity attributes and stack-up" ,-font => 18)->pack(-side => 'top', -padx => 10);

# Create the left frame with rows of labels and entry/dropdown widgets
my $left_frame = $mw->Frame()->pack(-side => 'left', -fill => 'y' );

# Define the options for each dropdown menu
my @options = (
    ['Option 1', 'Option 2', 'Option 3'],
    ['Option A', 'Option B', 'Option C'],
    ['Choice 1', 'Choice 2', 'Choice 3'],
    ['Select 1', 'Select 2', 'Select 3'],
    ['Item 1', 'Item 2', 'Item 3'],
    ['Alternative 1', 'Alternative 2', 'Alternative 3'],
    ['Pick 1', 'Pick 2', 'Pick 3'],
    ['Menu 1', 'Menu 2', 'Menu 3'],
    ['Value 1', 'Value 2', 'Value 3'],
    ['Selection 1', 'Selection 2', 'Selection 3'],
    ['Pick a', 'Pick b', 'Pick c'],
    ['Choice A', 'Choice B', 'Choice C'],
    ['Option X', 'Option Y', 'Option Z'],
    ['Alternative X', 'Alternative Y', 'Alternative Z'],
    ['Pick X', 'Pick Y', 'Pick Z'],
    ['Menu X', 'Menu Y', 'Menu Z'],
    ['Value X', 'Value Y', 'Value Z'],
    ['Selection X', 'Selection Y', 'Selection Z'],
    ['Pick 1', 'Pick 2', 'Pick 3']
);

# Create 20 rows of labels and entry/dropdown widgets
for (my $i = 1; $i <= 20; $i++) {
    my $label = $left_frame->Label(-text => "Label $i")->grid(-row => $i, -column => 0, -sticky => 'w', -padx => 10, -pady => 5);
    my $widget;
    if ($i >= 8) {
        # Create a dropdown widget for rows 8-20
        $widget = $left_frame->BrowseEntry(
            -choices => $options[$i-8],
        )->grid(-row => $i, -column => 1, -sticky => 'w', -padx => 10, -pady => 5);
    } else {
        # Create an entry widget for rows 1-7
        $widget = $left_frame->Entry()->grid(-row => $i, -column => 1, -sticky => 'w', -padx => 10, -pady => 5);
    }
}

MainLoop();