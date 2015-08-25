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

my $fulltext;
open( INPUT, "<${SOURCEFILE}" )
    or die "Unable to read sourcefile: ${SOURCEFILE}\n";
while( <INPUT> ) {
    $fulltext .= $_;
}
close( INPUT )
    or die;

# Prevent adding paragraphs to pre blocks
$fulltext =~ s|(<pre [^>]*?>)(.*?)(</pre>)|$1 . &addBreak( $2 ) . $3|egs;

# Add paragraphs to things inside an aside
while( $fulltext =~ s|\n\n(<aside data-type="\w+">\s*)([\w]+.*?)\s*\n\n|\n\n$1<p>$2</p>\n\n|gs ) {}

# Add paragraphs to everything that looks like a paragraph
while( $fulltext =~ s|\n\n([\w\.]+.*?)\s*\n\n|\n\n<p>$1</p>\n\n|gs ) {}
while( $fulltext =~ s|(\s*)</aside></p>|</p>$1</aside>|gs ) {}

# Add paragraphs to things that start with an internal anchor
while( $fulltext =~ s|\n\n(<a href="#[\w]+.*?)\s*\n\n|\n\n<p>$1</p>\n\n|gs ) {}

# Remove the pre-comments
$fulltext =~ s|(<pre [^>]*?>)(.*?)(</pre>)|$1 . &removeBreak( $2 ) . $3|egs;

# Output the file
my $OUTPUTFH = FileHandle->new( $OUTFILE, 'w' );
print $OUTPUTFH $fulltext;
$OUTPUTFH->close();
print "Finished parsing for paragraphs.\n" if $DEBUG;

exit 0;

sub addBreak {
    my $codeblock = shift;
    $codeblock =~ s|\n\n|\n<!-- PRE -->\n|gs;
    return $codeblock;
}

sub removeBreak {
    my $codeblock = shift;
    $codeblock =~ s|\n<!-- PRE -->\n|\n\n|gs;
    return $codeblock;
}
