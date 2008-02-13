#!/usr/bin/perl -w

#
# Copyright 2007-2008 by Alex Linke, <alinke@lingua-systems.com>
#
# $Id: xml2dump.pl 93 2008-02-13 13:39:27Z rlinke $
#


use strict;
use warnings;

require 5.008;

use XML::Simple;
use Data::Dumper;
use Getopt::Long;

use Encode;
use utf8;
no bytes;


my $VERSION = '0.2';


my %tables;


# set default options
my %opt = (
    output  =>	"transtbl.dump",
    verbose =>	0,
);


# parse commandline options
show_help(1) unless GetOptions(
    "output|o=s"    =>  \$opt{output},
    "verbose|v"	    =>  \$opt{verbose},
    "help|h"	    =>  \$opt{help}
);
show_help(1) if scalar(@ARGV) == 0;   # No XML file(s) given
show_help(0) if $opt{help};


# Treat everything else in @ARGV as a filename
foreach my $file (@ARGV) {
    print "Parsing $file..." if $opt{verbose};

    my %counts = (rules => 0, contexts => 0);

    my $ds = XMLin($file, GroupTags => { "rules" => "rule" })
	or die "Error parsing $file: $!\n";

    # Perform some additional basic checks
    die "Name undefined.\n"		unless $ds->{name};
    die "Description undefined.\n"	unless $ds->{desc};
    die "Reversibility undefined.\n"	unless $ds->{reverse};
    die "Table is not an array.\n"	unless ref($ds->{rules}) eq "ARRAY";

    # Check <reverse> tag contains valid data. TODO: move this to the DTD
    die "Reversibility: '$ds->{reverse}' -- Should be 'true' or 'false'.\n"
	unless $ds->{reverse} =~ /^(true|false)$/;

    foreach my $rule (@{$ds->{rules}}) {
	# Count rules and contexts for statistical purposes
	$counts{rules}++;
	$counts{contexts}++ if defined $rule->{context};

	# Convert "from"- and "to"-rules to octets (byte semantics)
	#$rule->{from}	= Encode::encode_utf8($rule->{from});
	#$rule->{to}	= Encode::encode_utf8($rule->{to});


	croak($ds->{name} . ": 'from' and 'to' match: " . $rule->{from})
	    if ($rule->{from} eq $rule->{to});
    }

    # Copy transliteration structure over to the final hash
    $tables{$ds->{name}} = $ds;

    print " ($ds->{name}: rules=$counts{rules}, contexts=$counts{contexts})\n"
	if $opt{verbose};


    undef($ds); # free memory
}

# Configure Data::Dumper
my $dumper = new Data::Dumper([ \%tables ], [ qw/*tables/ ]);
$dumper->Purity(0);
$dumper->Useqq(1);
$dumper->Indent(1);

# Dump the table(s) to disk
open FH, ">$opt{output}" or die "$opt{output}: $!\n";
print FH $dumper->Dump();
close(FH);

print scalar(keys(%tables)) .
    " transliteration table(s) dumped to $opt{output}.\n" if $opt{verbose};


sub show_help
{
    my $retval = shift();

    print STDERR
	"xml2dump v$VERSION -- Copyright 2007-2008 by Alex Linke ",
	"<alinke\@lingua-systems.com>\n\n",
	"usage: $0  [-v -h]  -o FILE  XML-FILE(s)\n\n",
	"\t--output  -o  FILE     set output file (default: transtbl.dump)\n",
	"\t--verbose -v           be verbose\n",
	"\t--help    -h           show this help\n";
  
    exit($retval);
}
  

# vim: sts=4 enc=utf-8
