#!/usr/bin/perl -w
use strict;
use FileHandle;
my $DEBUG = 0;
if( $ARGV[0] eq '-d' ) {
    $DEBUG = 1;
    shift( @ARGV );
}

my $SOURCEFILE = $ARGV[0];
my $OUTFILE = $ARGV[1];
if( ! $SOURCEFILE ) {
    die "ERROR: Must supply the output file name from Scrivener.\n\nUsage: splitHTMLBook.pl compiled-book.txt\n";
}
if( ! -f $SOURCEFILE ) {
    die "ERROR: Unable to read file: $SOURCEFILE\n";
}

print 'Source: ' . $SOURCEFILE . "\n";
print 'Output: ' . $OUTFILE . "\n";
if( -f $OUTFILE ) {
    print "WARNING: Overwriting existing temp file: $OUTFILE\n";
}

my $IS_IN_PRE = 0;

my $fulltext;
open( INPUT, "<${SOURCEFILE}" )
    or die "Unable to read sourcefile: ${SOURCEFILE}\n";
while( <INPUT> ) {
    $fulltext .= $_;
}
close( INPUT )
    or die;

# Prevent adding paragraphs to pre blocks
$fulltext =~ s|(<pre ?[^>]*>.*)\n\n(.*</pre>)|$1\n<!-- PRE -->\n$2|gs;

# Add paragraphs to everything that looks like a paragraph
$fulltext =~ s|\n\n([\w]+[^\n]+)\n\n|\n\n<p>$1</p>\n\n|gs;

# Add paragraphs to things that start with an internal anchor
$fulltext =~ s|\n\n(<a href="#[\w]+[^\n]+)\n\n|\n\n<p>$1</p>\n\n|gs;

# Remove the pre-comments
$fulltext =~ s|\n<!-- PRE -->\n|\n\n|gs;

# Output the file
my $OUTPUTFH = FileHandle->new( $OUTFILE, 'w' );
print $OUTPUTFH $fulltext;
$OUTPUTFH->close();
print "Finished parsing for paragraphs.\n" if $DEBUG;

exit 0;
