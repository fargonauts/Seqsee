#####################################################
#
#    Package: SStream
#
#####################################################
#   Manages the stream of thought.
#
#####################################################

package SStream;
use strict;
use Carp;
use Smart::Comments;
use Scalar::Util qw(blessed reftype);

my $DiscountFactor    = 0.8;    # Controls how fast the effect fades with age.
my $MaxOlderThoughts  = 10;     # Maximum number of older thoughts.
my $OlderThoughtCount = 0;      # Actual number of Older thoughts.
our @OlderThoughts = ();        # Older thoughts, the most recent coming first.
                                # Excludes current thought.
my %ThoughtsSet       = ();     # Another view of thoughts, but including Current Thought.
my %ComponentStrength = ();     # Keeps track of the strength of fringes.
our %ComponentOwnership_of = ();    # Who owns a particular component.
                                    # Key are components. values are hash refs, whose
                                    # keys are thoughts, values intensities
our $CurrentThought        = '';    # The current thought.
our %vivify;
our %hit_intensity         = ();    # keys are components, values numbers
our %thought_hit_intensity = ();    # keys are thoughts, values intensity

# method: clear
# Clears stream entirely
#
sub clear {
    $OlderThoughtCount     = 0;
    @OlderThoughts         = ();
    $CurrentThought        = '';
    %ComponentStrength     = ();
    %ComponentOwnership_of = ();
    %ThoughtsSet           = ();
    %vivify                = ();
}

# method: add_thought
# Adds a thought to the stream, and "thinks it"
#
#    This is a crucial function, so I must document it carefully.
#
#    Here are the steps of what happens:
#    * The fringe and extended fringe is calculated, by calls to get_fringe()
#      and get_extended_fringe()
#    * These are compared with older thoughts (via the fringes remembered in
#      %ComponentStrength. If there is a hit, then the hit is remembered in the
#      local variable $_hit_with.
#    * The action set of the thought is calculated by a call to get_actions().
#      This is appended to if there was a hit.
#    * All actions apart from those that are about "future actions" (like
#      launching codelets) are executed. These may add yet more "future actions
#    * of these future actions, 0 or 1 can be chosen as a thought to schedule,
#      and such scheduling occurs via a call to SCoderack->schedule_thought(
#      $thought). Others are launched as codelets via
#      SCoderack->launch_codelets(@...). This interface may change...
#
#    usage:
#     SStream->add_thought( $thought )
#
#    possible exceptions:
#        SErr::ProgOver
#

sub add_thought {
    @_ == 2 or confess "new thought takes two arguments";
    my ( $package, $thought ) = @_;

    return if $thought eq $CurrentThought;

    # XXX(Board-it-up): [2006/10/23] Need to hook into "real" memory
    # my $node = SNode->create($thought, 1, 100);

    if ( exists $ThoughtsSet{$thought} ) {    #okay, so this is an older thought
        unshift( @OlderThoughts, $CurrentThought ) if $CurrentThought;
        @OlderThoughts = grep { $_ ne $thought } @OlderThoughts;
        $CurrentThought = $thought;
        _recalculate_Compstrength();
        $OlderThoughtCount = scalar(@OlderThoughts);
    }

    else {
        SStream->antiquate_current_thought() if $CurrentThought;
        $CurrentThought = $thought;
        $ThoughtsSet{$CurrentThought} = $CurrentThought;
        _maybe_expell_thoughts();
    }
    _think_the_current_thought();

}

# method: _think_the_current_thought
#
#
sub _think_the_current_thought {
    my $thought = $CurrentThought;
    return unless $thought;

    my $fringe = $thought->get_fringe();
    ## $fringe
    $thought->set_stored_fringe($fringe);
    my $extended_fringe = $thought->get_extended_fringe();

    my $hit_with = _is_there_a_hit( $fringe, $extended_fringe );
    ## $hit_with

    my @action_set = $thought->get_actions();

    if ($hit_with) {
        my $new_thought = SCodelet->new(
            'AreRelated',
            100,
            {   a => $hit_with,
                b => $thought
            }
        )->schedule();
    }

    my (@_thoughts);
    for my $x (@action_set) {
        my $x_type = ref $x;
        if ( $x_type eq "SCodelet" ) {
            SCoderack->add_codelet($x);
        }
        elsif ( $x_type eq "SAction" ) {

            # print "Action of family ", $x->get_family(), " to be run\n";
            # main::message("Action of family ", $x->get_family());
            if ( $Global::Feature{CodeletTree} ) {
                my $family      = $x->get_family;
                my $probability = $x->get_urgency;
                print {$Global::CodeletTreeLogHandle} "\t$x\t$family\t$probability\n";
            }
            $x->conditionally_run();
        }
        else {
            confess "Huh? non-thought '$x' returned by get_actions"
                unless UNIVERSAL::isa( $x, "SThought" );
            push @_thoughts, $x;
        }
    }

    # Choose a thought and schedule it.
    if (@_thoughts) {
        my $idx = int( rand() * scalar(@_thoughts) );
        SCoderack->schedule_thought( $_thoughts[$idx] );
    }

}

# method: _maybe_expell_thoughts
# Expells thoughts if $MaxOlderThoughts exceeded
#

sub _maybe_expell_thoughts {
    return unless $OlderThoughtCount > $MaxOlderThoughts;
    for ( 1 .. $OlderThoughtCount - $MaxOlderThoughts ) {
        delete $ThoughtsSet{ pop @OlderThoughts };
    }
    $OlderThoughtCount = $MaxOlderThoughts;
    _recalculate_Compstrength();
}

#method: _recalculate_Compstrength
# Recalculates the strength of components from scratch
sub _recalculate_Compstrength {
    %ComponentOwnership_of = ();
    %vivify                = ();
    for my $t (@OlderThoughts) {
        my $fringe = $t->get_stored_fringe();
        for my $comp_act (@$fringe) {
            my ( $comp, $act ) = @$comp_act;
            $vivify{$comp} = $comp;
            $ComponentOwnership_of{$comp}{$t} = $act;
        }
    }
}

# method: init
# Does nothing.
#
#    Here for symmetry with similarly named methods in Coderack etc

sub init {
    my $Optsref = shift;
}

# method: antiquate_current_thought
# Makes the current thought the first old thought
#

sub antiquate_current_thought {
    my $package = shift;
    unshift( @OlderThoughts, $CurrentThought );
    $CurrentThought = '';
    $OlderThoughtCount++;
    _recalculate_Compstrength();
}

# method: _is_there_a_hit
# Is there another thought with a common fringe?
#
# Given the fringe and the extended fringe (each being an array ref, each of
# whose elements are 2 element array refs, the first being a component and the
# second the strength, it checks if there is a hit; If there is, the thought
# with which the hit occured is returned. Perhaps only thoughts of the same
# core type as the current are returned.
sub _is_there_a_hit {
    my ( $fringe_ref, $extended_ref ) = @_;
    ## $fringe_ref
    ## $extended_ref
    my %components_hit;    # keys values same
    our %hit_intensity = ();    # keys are components, values numbers

    for my $in_fringe ( @$fringe_ref, @$extended_ref ) {
        my ( $comp, $intensity ) = @$in_fringe;
        next unless exists $ComponentOwnership_of{$comp};
        $components_hit{$comp} = $comp;
        $hit_intensity{$comp}  = $intensity;
    }

    # Now get a list of which thoughts are hit.
    our %thought_hit_intensity = ();    # keys are thoughts, values intensity

    for my $comp ( values %components_hit ) {
        next unless exists $ComponentOwnership_of{$comp};
        my $owner_ref = $ComponentOwnership_of{$comp};
        my $intensity = $hit_intensity{$comp};
        for my $tht ( keys %$owner_ref ) {
            $thought_hit_intensity{$tht} += $owner_ref->{$tht} * $intensity;
        }
    }

    return unless %thought_hit_intensity;

    # Dampen their effect...
    my $dampen_by = 1;
    for my $i ( 0 .. $OlderThoughtCount - 1 ) {
        $dampen_by *= $DiscountFactor;
        my $thought = $OlderThoughts[$i];
        next unless exists $thought_hit_intensity{$thought};
        $thought_hit_intensity{$thought} *= $dampen_by;
        $thought_hit_intensity{$thought} *= thoughtTypeMatch( $thought, $CurrentThought );
    }

    my $chosen_thought
        = SChoose->choose( [ values %thought_hit_intensity ], [ keys %thought_hit_intensity ] );
    return $ThoughtsSet{$chosen_thought};
}

{
    my %Mapping = (

    );

    sub thoughtTypeMatch {
        my ( $othertht, $cur_tht ) = @_;
        my ( $type1, $type2 ) = map { blessed($_) } ( $othertht, $cur_tht );

        #main::message("$type1 and $type2");
        return 1 if $type1 eq $type2;
        my $str = "$type1;$type2";
        return $Mapping{$str} if exists $Mapping{$str};

        #main::message("$str barely match!");
        return 0.01;
    }
}

1;
