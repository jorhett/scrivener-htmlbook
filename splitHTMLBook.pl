#!/usr/bin/perl -w
use strict;
use FileHandle;
my $DEBUG = 0;
if( $ARGV[0] eq '-d' ) {
    $DEBUG = 1;
    shift( @ARGV );
}

my $SOURCEFILE = $ARGV[0];
if( ! $SOURCEFILE ) {
    die "ERROR: Must supply the output file name from Scrivener.\n\nUsage: splitHTMLBook.pl compiled-book.txt\n";
}
if( ! -f $SOURCEFILE ) {
    die "ERROR: Unable to read file: $SOURCEFILE\n";
}
if( ! -f 'atlas.json' ) {
    die "ERROR: Unable to read file: atlas.json\nAre you in the book directory?\n";
}

print 'Source: ' . $SOURCEFILE . "\n";
my $SUFFIX = '.html';
my $SECTION_DEPTH = -1;
my $LEVEL0_IS_DIV = 0;
my $FILENUM = 3;           # All chapters come after 3 (table of contents)

# Get the start and end of the Json file
my( $pre, $post ) = &readJsonFile( 'atlas.json' );
# Start rewriting the Json file
my $ATLAS_JSON = FileHandle->new( 'atlas.json.new', 'w' );
print $ATLAS_JSON $pre;

open( INPUT, "<${SOURCEFILE}" )
    or die "Unable to read sourcefile: ${SOURCEFILE}\n";

# Read past the start of the preface
my $OUTPUTFH = FileHandle->new( 'pre-book-start.html', 'w' );

# Start a loop that outputs each line, starting a new file after each chapter or part break
while( my $line = <INPUT> ) {
    if( $line =~ m|^<section data-type="sect| ) {
       # Do nothing special for lower-level sections
    }

    # Change filehandles at each chapter/part/heading start
    elsif( $line =~ m|^<section data-type="chapter" | ) {
        $OUTPUTFH = &nextFile( $OUTPUTFH, $ATLAS_JSON, ++$FILENUM );
    }
    elsif( $line =~ m|^<section data-type="appendix" id="appendix_(\w+)">|i ) {
        my $name = $1;
        $OUTPUTFH = &nextFile( $OUTPUTFH, $ATLAS_JSON, $name, 'appendix' );
    }
    elsif( $line =~ m|^<div data-type="part" id="part_([\w]+)"|i ) {
        my $name = $1;
        $OUTPUTFH = &nextFile( $OUTPUTFH, $ATLAS_JSON, $name, 'part' );
    }
    elsif( $line =~ m|^<section data-type="\w+" id="(\w+)">| ) {
        my $name = $1;
        $OUTPUTFH = &nextFile( $OUTPUTFH, $ATLAS_JSON, ++$FILENUM, $name );
    }

    # Now print the line regardless
    print $OUTPUTFH $line;
}
$OUTPUTFH->close();

print $ATLAS_JSON $post;
$ATLAS_JSON->close();
rename 'atlas.json.new', 'atlas.json'
    || die "ERROR: Unable to install new atlas file $? $!\n";

close( INPUT )
    or die;

exit 0;

sub nextFile() {
    use vars qw( $SUFFIX );
    my $fh = shift;
    my $jsonfile = shift;
    my $iterator = shift;
    my $name = shift || 'chapter';

    if( ref( $fh ) eq 'FileHandle' ) {
        $fh->close();
    }

    my $identifier;
    if( ( $name eq 'part' ) || ( $name eq 'appendix' ) ) {
      $identifier = sprintf( '%s', $iterator );
    }
    else {
      $identifier = sprintf( '%02i', $iterator );
    }
    my $filename = $identifier . '-' . lc $name . $SUFFIX;  
    print 'Filename: ' . $filename . "\n";
    print $jsonfile qq|,\n    "${filename}"|;

    $fh = FileHandle->new( $filename, 'w' )
        || die;

    return $fh;
}

sub readJsonFile {
    my $filename = shift;

    open( JSON, "<${filename}" )
        || die;
    my $line;
    # Find the end of the opening
    while( $line = <JSON> ) {
        $pre .= $line;
        if( $line =~ /toc.html/ ) {
            # Remove the training comma
            $pre =~ s/,\s*$//;
            last;
        }
    }
    # Ignore lines until closure
    while( $line = <JSON> ) {
        if( $line =~ /^\s*],\s*$/ ) {
            $post = "\n" . $line;
            last;
        }
    }
    # Read in everything after the files
    while( $line = <JSON> ) {
        $post .= $line;
    }
    close( JSON );
    return( $pre, $post );
}
