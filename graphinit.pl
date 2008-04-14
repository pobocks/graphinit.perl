#!/usr/bin/perl 
# A program to automatically sort initiative (who goes when)
# in any RPG system using normal numbers, highest-goes-first.

use Tk;
require Tk::Font;
use Carp;
use strict;
use warnings;
my $inits = "";
my $name = "";
my $init = 0;
my %charactersbyinit = ();
my @listchars = ();
my $charlist;
# DATA STRUCTURE NOTES: %charactersbyinit is a hash of array references.  
# The keys of the hash are the numbers entered as initiatives, the
# arrays contain the names of the characters that go on that 
# initiative.  Example: If Dave has a 15, Candy has a 17, and 
# Moose and Squirrel both have a 6, the hash will look like this:
#      %hash = (15 => ["Dave"], 17 => ["Candy"], 6 => ["Moose", "Squirrel"]);
# add_char and rm_char are constructed so as not to allow duplicate
# names, and so as to trim numbers when they are not used.


sub print_initiative{
  $charlist->delete(0, 'end');
  my @sorted_keys = sort {$b <=> $a} keys %charactersbyinit;
  for my $current_init (@sorted_keys){
    my @chars = @{$charactersbyinit{$current_init}};
    for (@chars){
      $charlist->insert("end", "$current_init: $_");
    }
  }
}


sub add_char{
  my ($name,$init) = @_;
  rm_char($name);
  if ($init =~ /\d/ && $name ne ''){
    push(@{$charactersbyinit{$init}}, $name);
    print_initiative();
  }
  else {
    carp "Non-numeric Init or non-extant Name!\n";
  }
}

sub rm_char{
  my $name = shift;
  for my $arrayref (values %charactersbyinit){
    @$arrayref = grep( $_ ne $name , @$arrayref);
  }
  for (keys %charactersbyinit){
    my $temp = $charactersbyinit{$_};
    delete $charactersbyinit{$_} if scalar(@$temp) == 0;
  }
  print_initiative();
}

#Make main window
my $mw= MainWindow->new;
$mw->title("Initiative");
$mw->Label(-text => "Inititative Program:\n",  
	   -font => "{Courier New} 12")->pack;

my $nameframe = $mw->Frame(-label => "Name: ", 
			-labelPack => [ -side => 'left'])->pack;

my $initframe = $mw->Frame(-label => "Init: ", 
			-labelPack => [ -side => 'left'])->pack;

#Add and delete buttons in frame that fills bottom of window above Exit
my $adddeleteframe = $mw->Frame()->pack;

$adddeleteframe->Button(-text => "Add", 
			-font => "{Courier New} 12", 
			-command => sub{add_char($name, $init)})->pack(-side => 'left', 
								       -expand => 0, 
								       -fill => 'x');

$adddeleteframe->Button(-text => "Delete", 
			-font => "{Courier New} 12", 
			-command => sub{rm_char($name)})->pack(-side => 'left', 
							       -expand => 0, 
							       -fill => 'x');


#Entries for name and initiative number
my $nameentry = $nameframe->Entry(-width => 10,
		  -textvariable => \$name, 
		  -background => "white")->pack;
		   
my $initentry = $initframe->Entry(-width => 4,
		  -textvariable => \$init, 
		  -background => "white")->pack;

#Bindings create this workflow:
#    [Enter Name] -> <Return> -> [Enter Init] -> <Return> {Repeat}
$nameentry->bind("<Return>", sub { $init = "";
				   $initentry->focus();
				 });

$initentry->bind("<Return>", sub{ add_char($name, $init);
				  $name = $init = "";
				  $nameentry->focus();
				}); 

#Creates a listbox to hold the initiatives and names
$charlist = $mw->Scrolled("Listbox",
			     -scrollbars => "oe",
			     -selectmode => "single",
			     -height => 20,
			     -width => 30)->pack(-side => "top");

#If clicked with mouse, loads name and initiative into boxes!
$charlist->bind('<Button-1>', sub { my $element = $charlist->get($charlist->curselection());
				    $element =~ /(\d+): (.+)/;
				    $init = $1;
				    $name = $2;
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

