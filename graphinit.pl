#!/usr/bin/perl 
# A program to automatically sort initiative (who goes when)
# in any RPG system using normal numbers, highest-goes-first.

use Tk;
use Tk::Font;
use Carp;
use Storable;
use strict;
use warnings;
use Tk::FBox;

my $name = "";
my $init = 0;
my $dex = 10;
my $selected = '';
my $scratchpad = '';
my %charactersbyinit = ();
my %notes = ();
my $charlist;
my ($nameframe, $initframe, $dexframe, $boxframe, $buttonframe, $adddeleteframe);
my ($nameentry, $initentry, $dexentry);
my $mw;
my $menu;
my $filecascade;
=pod

=head1 DATA STRUCTURE NOTES: 

%charactersbyinit is a hash of hashes of arrays.
The first level hash is indexed by the initiative number.
The second level hashes are indexed by dexterity score.
The arrays are unsorted lists of names.

Example: 
Foo the barbarian rolls an initiative of 12, and has a Dex score of 8,
Baz the thief also rolls a 12, and has a dex score of 18,
Quux the Bard also rolls a 12 and has a dex of 18 
Bar the Wizard rolls an 8, and has a dex score of 16 
the hash would look like this:

%charactersbyinit-> {
    12 -> {
           18 -> ( Baz, Quux)
           8 -> (Foo)
    }
     8 -> {
           16 -> (Bar)
     }
}

%notes is a simple hash keyed by name, the value being that character's
attached notes.

=cut

#Prints the current initiative from %charactersbyinit  to $charlist
sub print_initiative{
    $charlist->delete(0, 'end');
    my @sorted_keys = sort {$b <=> $a} keys %charactersbyinit;
    for my $current_init (@sorted_keys){
        my $dexhash = $charactersbyinit{$current_init};
        my @sorted_dexkeys = sort {$b <=> $a} keys %$dexhash;
        for my $current_dex (@sorted_dexkeys){
            my @chars = @{$charactersbyinit{$current_init}{$current_dex}};
            for (@chars){
                $charlist->insert("end", "$current_init: $_ ($current_dex)");
            }
        }   
    }
}

sub update_notes {
    my $name = shift;
    my $text = $scratchpad->Contents();
    chomp $text;
    $notes{$selected} = $text; 
    $selected = $name;
    $scratchpad->Contents($notes{$name});
}

    
#Adds (or updates) a character to the initiative order.
sub add_char{
    my ($name,$init,$dex) = @_;
    update_notes($name);
    if ($init =~ /^\d+$/ && $dex =~ /^\d+$/ && $name ne ''){
        rm_char($name);
        push(@{$charactersbyinit{$init}{$dex}}, $name);
        print_initiative();
    }
    else {
        carp "Non-numeric Init or non-extant Name!\n";
    }
}

#For each init, loops for each dexterity score 
#and deletes based just on name.
#(Note: Second for loop is to prune empty dexes and
# inits.)
sub rm_char{
    my $name = shift;
    for my $hashref (values %charactersbyinit){
        for my $arrayref (values %$hashref){
            @$arrayref = grep( $_ ne $name , @$arrayref);
        }
    }
    for my $init (keys %charactersbyinit){
        my $temp = $charactersbyinit{$init};
        for my $dex (keys %$temp){
            my $temp2 = $charactersbyinit{$init}{$dex};
            delete $charactersbyinit{$init}{$dex} if scalar(@$temp2) == 0;
            }
        delete $charactersbyinit{$init} if scalar(keys %{$charactersbyinit{$init}}) == 0;
    }
    print_initiative();
}

sub fileDialog {
    my $w = shift;
    my $operation = shift;
    my @types;
    my $file;
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    @types =
      (["Init files",           [qw/.init/]],
       ["All files",		'*']
      );
    if ($operation eq 'open') {
	$file = $w->getOpenFile(-filetypes => \@types);
    } else {
	$file = $w->getSaveFile(-filetypes => \@types,
				-initialfile => 'Untitled',
				-defaultextension => '.init');
    }
    if (defined $file and $file ne '') {
	return $file;
    }
}


sub save_inits {
  my $filename = shift;
  store [\%charactersbyinit, \%notes], $filename;
}

sub load_inits {
  my $filename = shift;
  my $inits_notes = retrieve "$filename";
  %charactersbyinit = %{$inits_notes->[0]};
  %notes = %{$inits_notes->[1]};
  print_initiative();
}

sub focus_on_nameentry {
   $nameentry->focus();
   $nameentry->selectionRange(0,'end');
}


#Make main window
$mw= MainWindow->new;
my $xe = $mw->XEvent;
$mw->resizable(0,1);
$mw->title("Initiative");
$mw->Label(-text => "Inititative Program:\n",  
           -font => "{Courier New} 12")->pack;
$menu = $mw->Menu(-type => 'menubar');
$mw ->configure(-menu => $menu);
$filecascade = $menu->cascade(-label => '~File', -tearoff => 0);
$filecascade->command(-label => 'Save Initiatives',
		      -command => sub { update_notes($name);
			                my $file = fileDialog($mw, 'Save');
					save_inits($file) if ($file);
				      });

$filecascade->command(-label => 'Load Initiatives',
		      -command => sub { my $file = fileDialog($mw, 'open');
					load_inits($file) if ($file);
				      });

$filecascade->command(-label => 'Exit',
		      -command => sub { exit;});

#Frames for name, initiative, and dexterity score.
$nameframe = $mw->Frame(-label => "Name: ", 
                           -labelPack => [ -side => 'left'])->pack;

$initframe = $mw->Frame(-label => "Init: ", 
                           -labelPack => [ -side => 'left'])->pack;

$dexframe  = $mw->Frame(-label => "Dex: ", 
                           -labelPack => [ -side => 'left'])->pack;


#Entries for name, initiative, and dexterity score
$nameentry = $nameframe->Entry(-width => 10,
                                  -textvariable => \$name, 
                                  -background => "white")->pack;

$initentry = $initframe->Entry(-width => 4,
                                  -textvariable => \$init, 
                                  -background => "white")->pack;

$dexentry =  $dexframe->Entry(-width => 4,
                                     -textvariable => \$dex, 
                                 -background => "white")->pack;

#Bindings create this workflow:
#    [Enter Name] -> <Return> -> [Enter Init] -> <Return> {Repeat}
# OR [Enter Name] -> <Return> -> [Enter Init] -> <Tab> -> [Enter Dex] -> <Return> {Repeat}
$nameentry->bind("<Return>", sub { $init = "";
                                   $initentry->focus();
                               });

$initentry->bind("<Return>", sub { add_char($name, $init, $dex);
                                   focus_on_nameentry();
                               }); 

$dexentry->bind("<Return>", sub { add_char($name, $init, $dex);
                                  focus_on_nameentry();
                              });


#Add and delete buttons in frame that fills bottom of window above Exit
$adddeleteframe = $mw->Frame()->pack;

$adddeleteframe->Button(-text => "Add", 
			-font => "{Courier New} 12", 
			-command => sub{add_char($name, $init, $dex)})->pack(-side => 'left', 
								       -expand => 0, 
								       -fill => 'x');

$adddeleteframe->Button(-text => "Delete", 
			-font => "{Courier New} 12", 
			-command => sub{rm_char($name);
                                        delete $notes{$name};
                                        $scratchpad->Contents('')})->pack(-side => 'left', 
                                                                          -expand => 0, 
                                                                          -fill => 'x');
#Creates a frame with a listbox to hold the initiatives and names, and a textarea
#for the notes
$boxframe = $mw->Frame()->pack( -expand => 1,
                                -fill => 'y');

$charlist = $boxframe->Scrolled("Listbox",
                                -label => 'Characters',
                                -scrollbars => "oe",
                                -selectmode => "single",
                                -height => 20,
                                -width => 20)->pack(-side => 'left',
                                                    -expand => 1,
                                                    -fill => 'y');

$scratchpad = $boxframe->Scrolled("Text",
                                  -label => "Notes",
                                  -scrollbars =>'oe',
                                  -background => 'white',
                                  -width => 30)->pack(-side => 'right',
                                      -expand => 1,
                                      -fill => 'y');



#If clicked with mouse, loads name and initiative into boxes!

#If clicked with mouse, loads name and initiative into boxes!
$charlist->bind('<Button-1>', 
		sub { 
		    if ($charlist->curselection()){
		        my $element = $charlist->get($charlist->curselection());
			$element =~ /(\d+): (.+) \((\d+)\)/;
			if ($1){$init = $1};
			if ($2){$name = $2;
                                update_notes($name);
                        }; 
			if ($3){$dex =  $3};
		    }
		});

#Clear initiative list
$buttonframe = $mw->Frame()->pack(-fill => 'x',
                                  -side => 'top');

$buttonframe->Button(-text => "Clear", 
	    -font => "{Courier New} 12", 
	    -command => sub {
	                     $name = '';
			     update_notes($name);
	                     %charactersbyinit = ();
			     print_initiative();})->pack(-side => 'top', 
						     -expand => 1, 
						     -fill => 'x');

$buttonframe->Button(-text => 'Notes',
            -font => '{Courier New} 12',
            -command => sub {
                if (eval {$scratchpad->packInfo()} ) {
                    $scratchpad->packForget();
                }
                else {
                    $scratchpad->pack(-side => 'right',
                                      -expand => 1,
                                      -fill => 'y',
                                      -after => $charlist,
                                      -in => $boxframe);
                }
                }
        )->pack(-side => 'top',
                -expand => 1,
                -fill => 'x');

$mw->minsize(0, 700);

MainLoop;
