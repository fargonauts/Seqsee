use strict;
use Tk;
use Carp;
use Smart::Comments;
use Getopt::Long;
use List::Util qw(sum);
my %options;

my $filename = 'codelet_tree.log';

use constant CODELET => 1;
use constant THOUGHT => 2;

# Format of that file:
# An unindented line indicates a "parent": a runnable run, or "Initial" or "Background"
# An indented line indicates an object being added to the coderack.

our %ObjectCounts;          # Keys: families
our %ObjectUrgencySums;     # Keys: families
our @DistributionAtTime;    # Index: time. Entries: Hash with keys families, values probabilities.

our $RunnableCount;
our %Type;
our %Family;
our %Urgency;

ReadFile();
my $MW = new MainWindow();
$MW->focusmodel('active');
$MW->bind(
    '<KeyPress-q>' => sub {
        exit;
    }
);
my $frame = $MW->Frame()->pack( -side => 'top' );
my $combo1 = $frame->ComboEntry(
    -itemlist => [ keys %ObjectCounts ],
    -width    => 40,
)->pack( -side => 'left' );
$frame->Button(
    -text    => 'Show',
    -command => sub {
        ShowGraph( $combo1->get() );
        }

)->pack( -side => 'left' );

my $Canvas = $MW->Canvas( -height => 300, -width => 800 )->pack( -side => 'top' );
MainLoop;

sub ReadFile {
    open my $file, '<', $filename;
    my $parent;
    while ( my $line = <$file> ) {
        if ( $line =~ /^Initial/ or $line =~ /^Background/ ) {
            $parent = '';
        }
        elsif ( $line =~ /^Expunge\s+(.*)$/ ) {

            # So some counts go down.
            my $expunged = $1;
            ProcessExpunging($expunged);
        }
        elsif ( $line =~ /^\S+ \s* (\S+)/x ) {

            # Running a runnable.
            ProcessRunnable($1);
        }
        elsif ( $line =~ /^\s* (\S+) \s* (.*)/x ) {

            # A new runnable added.
            ProcessAddition( $1, $2 );
        }
        else {
            confess "Unable to process line: >>$line<<\n";
        }
    }
}

sub ProcessExpunging {

    # An object is being expunged!
    my ($object) = @_;
    UncountRunnable($object);
}

sub ProcessAddition {
    my ( $object, $details ) = @_;
    if ( $Family{$object} ) {

        # Don't know why...
        warn "I already know family of >>$object<<";
    }
    if ( $object =~ /^SThought::(.*?)=/ ) {
        $Type{$object}   = THOUGHT;
        $Family{$object} = $1;
    }
    else {
        $Type{$object} = CODELET;
        $details =~ /^\s* (\S+) \s* (\d+)/x
            or confess "Cannot understand details: >>$details<< for object >>$object<<";
        my ( $family, $urgency ) = ( $1, $2 );
        $Family{$object}  = $family;
        $Urgency{$object} = $urgency;
        $ObjectCounts{$family}++;
        $ObjectUrgencySums{$family} += $urgency;
    }
}

sub UncountRunnable {
    my ($object) = @_;
    my $type = $Type{$object};    # 1=codelet, 2=thought
    confess "Missing type" unless $type;
    if ( $type == CODELET ) {
        my $family  = $Family{$object}  or confess;
        my $urgency = $Urgency{$object} or confess;
        $ObjectCounts{$family}--;
        $ObjectUrgencySums{$family} -= $urgency;

        # delete now useless info
        delete $Family{$object};
        delete $Urgency{$object};
        delete $Type{$object};
    }
    else {
        delete $Type{$object};
        delete $Family{$object};
    }
}

sub ProcessRunnable {

    # This is the point just before a runnable is chose, and I can evaluate pressure here.
    my ($object) = @_;
    $RunnableCount++;
    PrintPressure();
    UncountRunnable($object);
}

sub PrintPressure {
    print "State before runnable#: $RunnableCount\n";
    my $urgencies_sum = sum( values %ObjectUrgencySums );
    unless ($urgencies_sum) {
        print "\tNone\n";
        return;
    }
    while ( my ( $k, $v ) = each %ObjectUrgencySums ) {
        next unless $v;

        # print "\t$k\t=> ", sprintf("%5.3f", $v/$urgencies_sum), "\n";
        $DistributionAtTime[$RunnableCount]{$k} = $v / $urgencies_sum;
    }
}

sub ShowGraph {
    my ($family) = @_;
    my @data = map { $DistributionAtTime[$_]{$family} || 0 } 1 .. $RunnableCount;

    # print "@data\n";
    $Canvas->delete('all');
    $Canvas->create( 'rectangle', 10, 10, 790, 290 );
    my $width_per_runnable = 780 / $RunnableCount;
    my $x                  = 10;
    for ( 0 .. $RunnableCount - 1 ) {
        $x += $width_per_runnable;
        my $data = $data[$_];
        next unless $data;
        my $y = 290 - 280 * $data;
        $Canvas->create('rectangle', $x, $y, $x+1, $y+1, -fill=>'#0000FF', -outline=>'#0000FF');
    }
}

