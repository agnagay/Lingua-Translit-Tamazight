package Lingua::Translit;


#
# Copyright 2007-2008 by ...
#   Alex Linke, <alinke@lingua-systems.com>
#   Rona Linke, <rlinke@lingua-systems.com>
#
# $Id: Translit.pm 206 2008-04-08 06:16:22Z alinke $
#


use strict;
use warnings;

require 5.008;

use Carp;

use utf8;
no bytes;
use Encode;

use Lingua::Translit::Tables;


our $VERSION = '0.09';


=pod

=head1 NAME

Lingua::Translit - transliterates text between writing systems

=head1 SYNOPSIS

  use Lingua::Translit;

  my $tr = new Lingua::Translit("ISO 843");
 
  my $text_tr = $tr->translit("character oriented string");

  if ($tr->can_reverse()) {
    $text_tr = $tr->translit_reverse("character oriented string");
  }


=head1 DESCRIPTION

Lingua::Translit can be used to convert text from one writing system to
another, based on national or international transliteration tables.
Where possible a reverse transliteration is supported.

The term C<transliteration> describes the conversion of text from one
writing system or alphabet to another one.
The conversion is ideally unique, mapping one character to exactly one
character, so the original spelling can be reconstructed.
Practically this is not always the case and one single letter of the
original alpabet can be transcribed as two, three or even more letters.

Furthermore there is more than one transliteration scheme for one writing
system.
Therefore it is an important and necessary information, which scheme will be
or has been used to transliterate a text, to work integrative and be able to
reconstruct the original data.

Reconstruction is a problem though for non-unique transliterations, if no
language specific knowledge is available as the resulting clusters 
of letters may be ambigous.
For example, the Greek character "PSI" maps to "ps", but "ps" could also
result from the sequence "PI", "SIGMA" since "PI" maps to "p" and "SIGMA"
maps to s.
If a transliteration table leads to ambigous conversions, the provided
table cannot be used reverse.

Otherwise the table can be used in both directions, if appreciated.
So if ISO 9 is originally created to convert Cyrillic letters to
the Latin alphabet, the reverse transliteration will transform Latin
letters to Cyrillic.

=head1 METHODS

=head2 new(I<"name of table">)

Initializes an object with the specific transliteration table, e.g. "ISO 9".

=cut

sub new
{
    my $class = shift();
    my $name  = shift();

    my $self;

    # Assure that a table name was set
    croak("No transliteration name given.") unless $name;

    # Stay compatible with programs that use Lingua::Translit < 0.05
    if ($name =~ /^DIN 5008$/i)
    {
	$name = "Common DEU";
    }

    my $table = Lingua::Translit::Tables::_get_table_reference($name);

    # Check that a table reference was assigned to the object
    croak("No table found for $name.") unless $table;

    # Assure the table's data is complete
    croak("$name table: missing 'name'")    unless defined $table->{name};
    croak("$name table: missing 'desc'")    unless defined $table->{desc};
    croak("$name table: missing 'reverse'") unless defined $table->{reverse};
    croak("$name table: missing 'rules'")   unless defined $table->{rules};

    # Copy over the table's data
    $self->{name}   = $table->{name};
    $self->{desc}   = $table->{desc};
    $self->{rules}  = $table->{rules};

    # Set a truth value of the transliteration's reversibility according to
    # the natural language string in the original transliteration table
    $self->{reverse} = ($table->{reverse} =~ /^true$/i) ? 1 : 0;

    undef($table);

    return bless $self, $class;
}


=head2 translit(I<"character oriented string">)

Transliterates the given text according to the object's transliteration
table.
Returns the transliterated text.

=cut

sub translit
{
    my $self = shift();
    my $text = shift();

    my $utf8_flag_on = Encode::is_utf8($text);

    unless ($utf8_flag_on)
    {
	$text = decode("UTF-8", $text);
    }

    # Return if no input was given
    return unless $text;

    # Copy over the input string. It will be modified directly.
    my $tr_text = $text;

    foreach my $rule (@{$self->{rules}})
    {
	if (defined $rule->{context})
	{
	    my $c = $rule->{context};

	    if (defined $c->{before})
	    {
		$tr_text =~ s/\Q$rule->{from}\E(?=$c->{before})/$rule->{to}/g;
	    }
	    elsif (defined $c->{after})
	    {
		$tr_text =~ s/(?<=$c->{after})\Q$rule->{from}\E/$rule->{to}/g;
	    }
	    else
	    {
		croak("incomplete rule context");
	    }
	}
	else
	{
	    $tr_text =~ s/\Q$rule->{from}\E/$rule->{to}/g;
	}
    }

    unless ($utf8_flag_on)
    {
	return encode("UTF-8", $tr_text);
    }
    else
    {
	return $tr_text;
    }
}


=head2 translit_reverse(I<"character oriented string">)

Transliterates the given text according to the object's transliteration 
table, but uses it the other way round. For example table ISO 9 is a 
transliteration scheme for the converion of Cyrillic letters to the Latin 
alphabet. So if used reverse, Latin letters will be mapped to Cyrillic ones.

Returns the transliterated text.

=cut

sub translit_reverse
{
    my $self = shift();
    my $text = shift();

    my $utf8_flag_on = Encode::is_utf8($text);

    unless ($utf8_flag_on)
    {
	$text = decode("UTF-8", $text);
    }

    # Return if no input was given
    return unless $text;

    # Is this transliteration reversible?
    croak("$self->{name} cannot be reversed") unless $self->{reverse};

    # Copy over the input string. It will be modified directly.
    my $tr_text = $text;

    foreach my $rule (@{$self->{rules}})
    {
	if (defined $rule->{context})
	{
	    my $c = $rule->{context};

	    if (defined $c->{before})
	    {
		$tr_text =~ s/\Q$rule->{to}\E(?=$c->{before})/$rule->{from}/g;
	    }
	    elsif (defined $c->{after})
	    {
		$tr_text =~ s/(?<=$c->{after})\Q$rule->{to}\E/$rule->{from}/g;
	    }
	    else
	    {
		croak("incomplete rule context");
	    }
	}
	else
	{
	    $tr_text =~ s/\Q$rule->{to}\E/$rule->{from}/g;
	}
    }

    unless ($utf8_flag_on)
    {
	return encode("UTF-8", $tr_text);
    }
    else
    {
	return $tr_text;
    }
}


=head2 can_reverse()

Returns true (1), iff reverse transliteration is possible.
False (0) otherwise.

=cut

sub can_reverse
{
    return $_[0]->{reverse};
}


=head2 name()

Returns the name of the chosen transliteration table, e.g. "ISO 9".

=cut

sub name
{
    return $_[0]->{name};
}


=head2 desc()

Returns a description for the transliteration,
e.g. "ISO 9:1995, Cyrillic to Latin". 

=cut

sub desc
{
    return $_[0]->{desc};
}


=head1 SUPPORTED TRANSLITERATIONS

=over 4

=item B<ISO 843>, not reversible, C<ISO 843:1997, Greek to Latin>

=item B<ISO 9>, reversible, C<ISO 9:1995, Cyrillic to Latin>

=item B<Greeklish>, not reversible, C<Greeklish (Phonetic), Greek to Latin>

=item B<DIN 31634>, not reversible, C<DIN 31634:1982, Greek to Latin>

=item B<Common RON>, not reversible, C<Romanian without diacritics as commonly used>

=item B<Common DEU>, not reversible, C<German without umlauts>

=item B<Common CES>, not reversible, C<Czech without diacritics>

=item B<Common Classical MON>, reversible=true, C<Classical Mongolian to Latin>

=back

=head1 RESTRICTIONS

L<Lingua::Translit> is suited to handle B<Unicode> and utilizes comparisons
and regular expressions that rely on B<code points>.
Therefore, any input is supposed to be B<character oriented>
(C<use utf8;>, ...) instead of byte oriented.

However, if your data is byte oriented, be sure to pass it
B<UTF-8 encoded> to translit() and/or translit_reverse() - it will be
converted internally.

=head1 BUGS

None known.

Please report bugs to perl@lingua-systems.com.

=head1 SEE ALSO

L<Lingua::Translit::Tables>, L<utf8>, L<Encode>, L<perlunicode>, L<bytes>

L<translit(1)>

C<http://www.lingua-systems.com/products/translit/> provides an online
frontend for L<Lingua::Translit>.

=head1 CREDITS

Thanks to Dr. Daniel Eiwen, Romanisches Seminar, Universitaet Koeln for his
help on Romanian transliteration.

Thanks to Bayanzul Lodoysamba <baynaa@users.sourceforge.net> for contributing
the "Common Classical Mongolian" transliteration table.

=head1 AUTHORS

Alex Linke <alinke@lingua-systems.com>

Rona Linke <rlinke@lingua-systems.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Alex Linke and Rona Linke. All rights reserved.

This module is free software. It may be used, redistributed
and/or modified under the terms of either the GPL v2 or the
Artistic license.

=cut


1;


# vim: sts=4 enc=utf-8
