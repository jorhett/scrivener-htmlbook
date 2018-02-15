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
    die "ERROR: Must supply the input file name.\n\nUsage: splitHTMLBook.pl chapter.txt\n";
}
if( ! -f $SOURCEFILE ) {
    die "ERROR: Unable to read file: $SOURCEFILE\n";
}

print 'Source: ' . $SOURCEFILE . "\n";
print 'Output: ' . $OUTFILE . "\n";
if( -f $OUTFILE ) {
    print "WARNING: Overwriting existing temp file: $OUTFILE\n";
}

my $fulltext;
open( INPUT, "<${SOURCEFILE}" )
    or die "Unable to read sourcefile: ${SOURCEFILE}\n";
while( <INPUT> ) {
    $fulltext .= $_;
}
close( INPUT )
    or die;

# Fix paragraphs inside line elements
$fulltext =~ s|<li>\n<p>(.*?)</p>\n</li>\n|<li>$1</li>\n|gs;

# Fix quote marks
$fulltext =~ s|&#8217;|'|g;

# Fix invalid anchors
# F: <a data-type="xref" href="#([\w\-\:\.]+)"/>
# R: <a data-type="xref" href="#$1">#$1</a>
$fulltext =~ s|(<a data-type="xref" href="(#[\w\-\.]+)")/>|$1>$2</a>|g;

# Remove 3 or more blank lines in a row.
while( $fulltext =~ s|\n\n\n|\n\n|gs ) {}


# Output the file
my $OUTPUTFH = FileHandle->new( $OUTFILE, 'w' );
print $OUTPUTFH $fulltext;
$OUTPUTFH->close();
print "Finished parsing for paragraphs.\n" if $DEBUG;

exit 0;
