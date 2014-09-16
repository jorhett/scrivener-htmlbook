#!/usr/bin/perl -w
use strict;
use FileHandle;

our $SOURCEFILE = $ARGV[0];
print 'Source: ' . $SOURCEFILE . "\n";
our $SUFFIX = '.html';

# Get the start and end of the Json file
my( $pre, $post ) = &readJsonFile( 'atlas.json' );
# Start rewriting the Json file
my $ATLAS_JSON = FileHandle->new( 'atlas.json', 'w' );
print $ATLAS_JSON $pre;

open( INPUT, "<${SOURCEFILE}" )
    or die "Unable to read sourcefile: ${SOURCEFILE}\n";

# Read past the start of the preface
my $OUTPUTFH = FileHandle->new( 'pre-book-start.html', 'w' );

# All chapters come after 3 (table of contents)
my $iterator = 3;

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

# Now create a loop that outputs each line, starting a new file after each chapter or part break
my $line;
while( $line = <INPUT> ) {
    # Fix all IDs to make valid link targets
    if( $line =~ m|^(\s*<h\d) id="([^"]+)">(.*)$| ) {
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

    # Change filehandles at each chapter start
    elsif( $line =~ m|^<section data-type="chapter">| ) {
        # Change file handles
        $OUTPUTFH = &nextFile( $ATLAS_JSON, $OUTPUTFH, ++$iterator );
        print $OUTPUTFH $line;
        next;
    }

    # Parse out top-level elements
    elsif( $line =~ m|^<div data-type="part">| ) {
        # See if the next line is a front or end matter
        my $nextline = <INPUT>;
        if( $nextline =~ m|^\s*<h1 id="([^"]+)">([\w\s\-]+)</h1>\s*$| ) {
            my $idlabel = $1;
            my $heading = $2;

            if( $sectionmatter{ $1 } ) {
                # Change file handles
                $OUTPUTFH = &nextFile( $ATLAS_JSON, $OUTPUTFH, ++$iterator, $sectionmatter{ $1 } );
                print $OUTPUTFH qq|<section data-type="$sectionmatter{ $1 }">|;
            }
            else {
                # If not, print out the original line
                print $OUTPUTFH $line;
            }

            # First, fix any IDs that have spaces or non-alpha characters
            $idlabel =~ s/\s/_/g;
            $idlabel =~ s/[^\w\-]//g;

            # Print out the revised label
            print $OUTPUTFH qq|  <h1 id="${idlabel}">${heading}</h1>\n|;
            next;
        }
        else {
            # Either way print out both lines and proceed
            print $OUTPUTFH $line . $nextline;
        }
    }

    # Otherwise just print the line
    else {
        print $OUTPUTFH $line;
    }
}
$OUTPUTFH->close();

print $ATLAS_JSON $post;
$ATLAS_JSON->close();

close( INPUT )
    or die;

exit 0;

sub nextFile() {
    use vars qw( $SUFFIX );
    my $jsonfile = shift;
    my $fh = shift;
    my $iterator = shift;
    my $name = shift || 'chapter';

    if( ref( $fh ) eq 'FileHandle' ) {
        $fh->close();
    }

    my $chapternum = sprintf( '%02i', $iterator );
    my $filename = $chapternum . '-' . $name . $SUFFIX;  
    print 'Filename: ' . $filename . "\n";
    print $jsonfile qq|    "${filename}",\n|;

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
            last;
        }
    }
    # Ignore lines until closure
    while( $line = <JSON> ) {
        if( $line =~ /^\s*],\s*$/ ) {
            $post = $line;
            last;
        }
    }
    # Read in the formats, theme, and title
    while( $line = <JSON> ) {
        $post .= $line;
    }
    close( JSON );
    return( $pre, $post );
}
