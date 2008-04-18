#!/usr/bin/perl 
# A program to automatically sort initiative (who goes when)
# in any RPG system using normal numbers, highest-goes-first.

use Tk;
require Tk::Font;
use Carp;
use strict;
use warnings;

my $name = "";
my $init = 0;
my $dex = 10;
my %charactersbyinit = ();
my @listchars = ();
my $charlist;

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
	
=cut

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

#Adds (or updates) a character to the initiative order.
sub add_char{
  my ($name,$init,$dex) = @_;
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
#(Note: Second double for loop is to prune empty dexes and
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

#Make main window
my $mw= MainWindow->new;
$mw->title("Initiative");
$mw->Label(-text => "Inititative Program:\n",  
	   -font => "{Courier New} 12")->pack;

#Frames for name, initiative, and dexterity score.
my $nameframe = $mw->Frame(-label => "Name: ", 
			   -labelPack => [ -side => 'left'])->pack;

my $initframe = $mw->Frame(-label => "Init: ", 
			   -labelPack => [ -side => 'left'])->pack;

my $dexframe  = $mw->Frame(-label => "Dex: ", 
			   -labelPack => [ -side => 'left'])->pack;


#Entries for name, initiative, and dexterity score
my $nameentry = $nameframe->Entry(-width => 10,
				  -textvariable => \$name, 
				  -background => "white")->pack;
		   
my $initentry = $initframe->Entry(-width => 4,
				  -textvariable => \$init, 
				  -background => "white")->pack;

my $dexentry =  $dexframe->Entry(-width => 4,
				 -textvariable => \$dex, 
				 -background => "white")->pack;

#Bindings create this workflow:
#    [Enter Name] -> <Return> -> [Enter Init] -> <Return> {Repeat}
# OR [Enter Name] -> <Return> -> [Enter Init] -> <Tab> -> [Enter Dex] -> <Return> {Repeat}
$nameentry->bind("<Return>", sub { $init = "";
				   $initentry->focus();
				 });

$initentry->bind("<Return>", sub { add_char($name, $init, $dex);
				   $name = $init = "";
				   $dex = 10;
				   $nameentry->focus();
		 }); 

$dexentry->bind("<Return>", sub { add_char($name, $init, $dex);
				  $name = $init = "";
				  $dex = 10;
				  $nameentry->focus();
		});


#Add and delete buttons in frame that fills bottom of window above Exit
my $adddeleteframe = $mw->Frame()->pack;

$adddeleteframe->Button(-text => "Add", 
			-font => "{Courier New} 12", 
			-command => sub{add_char($name, $init, $dex)})->pack(-side => 'left', 
								       -expand => 0, 
								       -fill => 'x');

$adddeleteframe->Button(-text => "Delete", 
			-font => "{Courier New} 12", 
			-command => sub{rm_char($name)})->pack(-side => 'left', 
							       -expand => 0, 
							       -fill => 'x');


#Creates a listbox to hold the initiatives and names
$charlist = $mw->Scrolled("Listbox",
			  -scrollbars => "oe",
			  -selectmode => "single",
			  -height => 20,
			  -width => 30)->pack(-side => "top");

#If clicked with mouse, loads name and initiative into boxes!
$charlist->bind('<Button-1>', 
		sub { 
		    if ($charlist->curselection()){
		        my $element = $charlist->get($charlist->curselection());
			$element =~ /(\d+): (.+) \((\d+)\)/;
			if ($1){$init = $1};
			if ($2){$name = $2}; 
			if ($3){$dex =  $3};
		    }
		});

#Clear initiative list
$mw->Button(-text => "Clear", 
	    -font => "{Courier New} 12", 
	    -command => sub {%charactersbyinit = ();
			     print_initiative();})->pack(-side => 'top', 
						     -expand => 1, 
						     -fill => 'x');


#Exit button fills bottom of window
$mw->Button(-text => "Exit", 
	    -font => "{Courier New} 12", 
	    -command => sub {$mw->destroy})->pack(-side => 'top', 
						  -expand => 1, 
						  -fill => 'x');


MainLoop;

