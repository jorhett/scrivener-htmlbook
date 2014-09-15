#!/usr/bin/perl -w
use strict;
use FileHandle;

our $SOURCEFILE = $ARGV[0];
print 'Source: ' . $SOURCEFILE . "\n";
our $SUFFIX = '.html';

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
    # Change filehandles at each chapter start
    if( $line =~ m|^<section data-type="chapter">| ) {
        # Change file handles
        $OUTPUTFH = &nextFile( $OUTPUTFH, ++$iterator );
        print $OUTPUTFH $line;
        next;
    }

    # Parse out top-level elements
    elsif( $line =~ m|^<div data-type="part">| ) {
        # See if the next line is a front or end matter
        my $nextline = <INPUT>;
        $nextline =~ m|^<h1>([\w\s\-]+)</h1>$|;
        my $heading = $1;
        if( $sectionmatter{ $1 } ) {
            # Change file handles
            $OUTPUTFH = &nextFile( $OUTPUTFH, ++$iterator, $sectionmatter{ $1 } );
            print $OUTPUTFH qq|<section data-type="$sectionmatter{ $1 }">|;
            print $OUTPUTFH $nextline;
        }
        else {
            # If not, print out both lines and proceed
            print $OUTPUTFH $line . $nextline;
            next;
        }
    }

    # Otherwise just print the line
    else {
        print $OUTPUTFH $line;
    }
}
$OUTPUTFH->close();

close( INPUT )
    or die;

exit 0;

sub nextFile() {
    use vars qw( $SUFFIX );
    my $fh = shift;
    my $iterator = shift;
    my $name = shift || 'chapter';

    if( ref( $fh ) eq 'FileHandle' ) {
        $fh->close();
    }

    my $chapternum = sprintf( '%02i', $iterator );
    my $filename = $chapternum . '-' . $name . $SUFFIX;  
    print 'Filename: ' . $filename . "\n";

    $fh = FileHandle->new( $filename, 'w' )
        || die;

    return $fh;
}
