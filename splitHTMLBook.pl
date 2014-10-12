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

# Front and end matter elements
my %sectionmatter = (
    'Preface'           => 'preface',
    'Foreword'          => 'foreword',
    'Introduction'      => 'introduction',
    'Afterword'         => 'afterword',
    'Acknowledgements'  => 'acknowledgements',
    'Conclusion'        => 'conclusion',
    'Colophon'          => 'colophon',
);

# Start a loop that outputs each line, starting a new file after each chapter or part break
my $line;
my $linenum = 0;
while( $line = <INPUT> ) {
    $linenum++;

    # If section level changes, close off the previous section
    if( $line =~ m|^\s*<section data-type="sect(\d+)">| ) {
        my $depth = $1;
        print $OUTPUTFH &closeSection( $depth, $linenum );

        # Output the line
        print $OUTPUTFH $line;
        next;
    }

    # Change filehandles at each chapter start
    elsif( $line =~ m|^<section data-type="chapter">| ) {
        # Close off the previous section
        print $OUTPUTFH &closeSection( 0, $linenum );
        $LEVEL0_IS_DIV = 0;

        print "LINE $linenum: Starting new chapter.\n" if $DEBUG;
        # Change file handles
        $OUTPUTFH = &nextFile( $OUTPUTFH, $ATLAS_JSON, ++$FILENUM );
        print $OUTPUTFH $line;
        next;
    }

    # Fix all IDs to make valid link targets
    elsif( $line =~ m|^(\s*<h\d) id="([^"]+)">(.*)$| ) {
        # First, fix any IDs that have spaces or non-alpha characters
        my $opening = $1;
        my $idlabel = $2;
        my $remainder = $3;
        $idlabel =~ s/\s/_/g;
        $idlabel =~ s/[^\w\-]//g;

        # Either way print out both lines and proceed
        print $OUTPUTFH qq|${opening} id="${idlabel}">${remainder}\n|;
        next;
    }

    # Parse out top-level elements
    elsif( $line =~ m|^\s*<section data-type="top-level-element">| ) {
        # Close off the previous section
        print $OUTPUTFH &closeSection( 0, $linenum );
        $LEVEL0_IS_DIV = 0;

        # See if the next line is a front or end matter
        $linenum++;
        my $nextline = <INPUT>;
        if( $nextline =~ m|^\s*<h1 id="([^"]+)">([\w\s\:\-]+)</h1>\s*$| ) {
            my $idlabel = $1;
            my $heading = $2;

            if( $sectionmatter{ $heading } ) {
                # Change file handles
                $OUTPUTFH = &nextFile( $OUTPUTFH, $ATLAS_JSON, ++$FILENUM, $sectionmatter{ $1 } );
                print $OUTPUTFH qq|<section data-type="$sectionmatter{ $heading }">\n|;
            }

            # Is this a new book part?
            elsif( $heading =~ /^part\s+/i ) {
                $LEVEL0_IS_DIV = 1;

                # Output the line
                print "LINE $linenum: Starting new book part.\n" if $DEBUG;
                $OUTPUTFH = &nextFile( $OUTPUTFH, $ATLAS_JSON, ++$FILENUM, 'part' );
                print $OUTPUTFH qq|<div data-type="part">\n|;
            }

            else {
                die "ERROR at LINE $linenum: Found top-level section element which isn't a new part, nor HTMLBook front or end matter: $heading\n";
            }

            # First, fix any IDs that have spaces or non-alpha characters
            $idlabel =~ s/\s/_/g;
            $idlabel =~ s/[^\w\-]//g;

            # Print out the revised label
            print $OUTPUTFH qq|  <h1 id="${idlabel}">${heading}</h1>\n|;
            next;
        }
        else {
            die "ERROR at LINE $linenum: Found top-level section element which isn't formatted correctly.\n";
        }
    }

    # Otherwise just print the line
    else {
        print $OUTPUTFH $line;
    }
}
print $OUTPUTFH "</section>\n";
$OUTPUTFH->close();
print "LINE $linenum: Finished book.\n" if $DEBUG;

print $ATLAS_JSON $post;
$ATLAS_JSON->close();
rename 'atlas.json.new', 'atlas.json'
    || die "ERROR: Unable to install new atlas file $? $!\n";

close( INPUT )
    or die;

exit 0;

sub closeSection() {
    use vars qw( $DEBUG $SECTION_DEPTH $LEVEL0_IS_DIV );
    my $newdepth = shift;
    my $linenum = shift;
    my $text = '';

    # Now do the right thing for the various changes
    if( $newdepth > $SECTION_DEPTH ) {
        print "LINE $linenum: Entering section level $newdepth\n" if $DEBUG;
    }
    else {
        if( $newdepth < $SECTION_DEPTH ) {
            # Close out the current section and any levels in between
            # e.g. from 3 up to 1 is closing 3, 2, and previous 1...
            my $uplevels = $SECTION_DEPTH - $newdepth + 1;
            for( my $uplevel = $SECTION_DEPTH; $uplevel > $newdepth ; $uplevel-- ) {
                $text .= "</section> <!-- closing sect${uplevel} -->\n";
                print "LINE $linenum: Closed out section level $uplevel\n" if $DEBUG;
            }
        }
        # At this point section depth and new depth are equal, now close current depth
        # We have to handle 0-depth book parts are divs not sections
        if( $newdepth == 0 ) {
            if( $LEVEL0_IS_DIV ) {
                $text .= "</div> <!-- closing book part -->\n";
            }
            else {
                $text .= "</section> <!-- closing chapter, frontmatter, or backmatter -->\n";
            }
        }
        else { 
            $text .= "</section> <!-- closing sect${newdepth} -->\n";
        }

        print "LINE $linenum: Starting new section level $newdepth\n" if $DEBUG;
    }
    $SECTION_DEPTH = $newdepth;

    return $text;
}

sub nextFile() {
    use vars qw( $SUFFIX );
    my $fh = shift;
    my $jsonfile = shift;
    my $iterator = shift;
    my $name = shift || 'chapter';

    if( ref( $fh ) eq 'FileHandle' ) {
        $fh->close();
    }

    my $chapternum = sprintf( '%02i', $iterator );
    my $filename = $chapternum . '-' . $name . $SUFFIX;  
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
