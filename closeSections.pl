#!/usr/bin/perl -w
use strict;
use FileHandle;
my $DEBUG = 0;
if( $ARGV[0] eq '-d' ) {
    $DEBUG = 1;
    shift( @ARGV );
}

my $SOURCEFILE = $ARGV[0];
my $DESTFILE = $ARGV[1];
if( ! $SOURCEFILE || ! $DESTFILE ) {
    die "ERROR: Must supply the input and output file names.\n\nUsage: closeSections.pl compiled-book.html closed.html\n";
}
if( ! -f $SOURCEFILE ) {
    die "ERROR: Unable to read file: $SOURCEFILE\n";
}

print 'Source: ' . $SOURCEFILE . "\n";
print 'Destination: ' . $DESTFILE . "\n";
my $SUFFIX = '.html';
my $SECTION_DEPTH = -1;

open( INPUT, "<${SOURCEFILE}" )
    or die "Unable to read sourcefile: ${SOURCEFILE}\n";

my $OUTPUTFH = FileHandle->new( $DESTFILE, 'w' );

# Front and end matter elements
my %sectionmatter = (
    'Preface'           => 'preface',
    'Foreword'          => 'foreword',
#    'Introduction'      => 'introduction',  # O'Reilly doesn't use this yet
    'Introduction'      => 'preface',
    'Afterword'         => 'afterword',
    'Acknowledgements'  => 'acknowledgements',
    'Conclusion'        => 'conclusion',
    'Colophon'          => 'colophon',
);

# Start a loop that outputs each line, starting a new file after each chapter or part break
my $line;
my $linenum = 0;
my $LEVEL0_IS_DIV = 0;
while( $line = <INPUT> ) {
    $linenum++;

    # If section level changes, close off the previous section
    if( $line =~ m|^\s*<section data-type="sect(\d+)" id="([^"]+)">| ) {
        my $depth = $1;
        my $idlabel = &cleanIdLabel( $2 );

        print "LINE $linenum: Starting sect${depth} id=${idlabel}\n" if $DEBUG;
        print $OUTPUTFH &closeSection( $depth, $linenum );
        print $OUTPUTFH qq|<section data-type="sect${depth}" id="${idlabel}">\n|;
        next;
    }

    # Change filehandles at each chapter start
    elsif( $line =~ m|^<section data-type="chapter" id="([^"]+)">| ) {
        my $idlabel = &cleanIdLabel( $1 );

        # Close off the previous section
        print $OUTPUTFH &closeSection( 0, $linenum );
        $LEVEL0_IS_DIV = 0;

        print "LINE $linenum: Starting new chapter.\n" if $DEBUG;
        print "LINE $linenum: Starting chapter id=${idlabel}\n" if $DEBUG;
        print $OUTPUTFH qq|<section data-type="chapter" id="${idlabel}">\n|;
        next;
    }

    # Parse out top-level elements
    elsif( $line =~ m|^\s*<section data-type="top-level-element" id="([^"]+)">| ) {
        my $title = $1;
        my $idlabel = $title;

        # Ensure the ID label is html-safe
        $idlabel =~ s/\s+/_/g;
        $idlabel =~ s/[^\w\-]//g;

        # Close off the previous section
        print $OUTPUTFH &closeSection( 0, $linenum );

        # if this is front or end matter
        if( $sectionmatter{ $title } ) {
            print $OUTPUTFH qq|<section data-type="$sectionmatter{ $title }" id="${idlabel}">\n|;
            next;
        }

        # Is this a new book part? Strip the "part" text
        elsif( $title =~ s/^part\s+([^:]+):\s+//i ) {
            my $partnum = $1;
            $LEVEL0_IS_DIV = 1;

            # Output the line
            print "LINE $linenum: Starting book Part ${partnum}.\n" if $DEBUG;
            print $OUTPUTFH qq|<div data-type="part" id="${idlabel}" xmlns="http://www.w3.org/1999/xhtml">\n|;
        }

        # Is this an appendix?
        elsif( $title =~ s/^appendix\s+([\w]+):\s+//i ) {
            my $appname = $1;
            $LEVEL0_IS_DIV = 0;

            # Output the line
            print "LINE $linenum: Starting Appendix $appname.\n" if $DEBUG;
            print $OUTPUTFH qq|<section data-type="appendix" id="${idlabel}">\n|;
        }

        else {
            die "ERROR at LINE $linenum: Found top-level section element which isn't a new part, appendix, nor valid front or end matter: $title = $idlabel\n";
        }
    }

    # Otherwise just print the line
    else {
        print $OUTPUTFH $line;
    }
}
print $OUTPUTFH &closeSection( 0, $linenum );
$OUTPUTFH->close();
print "LINE $linenum: Finished book.\n" if $DEBUG;

close( INPUT )
    or die;

exit 0;

sub cleanIdLabel() {
    my $idlabel = shift;
    $idlabel =~ s/\s+/_/g;
    $idlabel =~ s/[^\w\-]//g;
    return $idlabel;
}

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
                $text .= "</section>\n<!-- closing sect${uplevel} -->\n";
                print "LINE $linenum: Closed out section level $uplevel\n" if $DEBUG;
            }
        }
        # At this point section depth and new depth are equal, now close current depth
        # We have to handle 0-depth book parts are divs not sections
        if( $newdepth == 0 ) {
            if( $LEVEL0_IS_DIV ) {
                $text .= "</div>\n<!-- closing book part -->\n";
                $LEVEL0_IS_DIV = 0;
            }
            else {
                $text .= "</section>\n<!-- closing chapter, frontmatter, or backmatter -->\n";
            }
        }
        else { 
            $text .= "</section>\n<!-- closing sect${newdepth} -->\n";
        }

        print "LINE $linenum: Starting new section level $newdepth\n" if $DEBUG;
    }
    $SECTION_DEPTH = $newdepth;

    return $text;
}
