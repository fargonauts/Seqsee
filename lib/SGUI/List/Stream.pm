package SGUI::List::Stream;
use strict;
use Sort::Key qw{rnkeysort};
our @ISA = qw{SGUI::List};

sub new {
    my ($package) = @_;
    my $self = bless { HeightPerRow => 40,
                       intensity_x => 5,
                       name_x => 100,
                       fringe_y => 20,
                       fringe_x => 10,
                   }, $package;

    return $self;
}

sub GetItemList {
    my $tht_intensity_hash = $Global::MainStream->{thought_hit_intensity};
    my $current = $Global::MainStream->{CurrentThought} or return;
    my @older_thoughts
        = rnkeysort { $tht_intensity_hash->{$_} } @{ $Global::MainStream->{OlderThoughts} };
    return ( $current, @older_thoughts );
}

sub DrawOneItem {
    my ( $self, $Canvas, $left, $top, $thought ) = @_;
    my @item_ids;
    my $is_current_thought = ( $thought eq $Global::MainStream->{CurrentThought} ) ? 1 : 0;
    my $intensity
        = $is_current_thought ? '-' : $Global::MainStream->{thought_hit_intensity}{$thought};
    my $name = $thought->as_text();
    $Canvas->createText($left + $self->{intensity_x},
                        $top + 5,
                        -text => $intensity,
                        -anchor => 'nw',
                            );
    $Canvas->createText($left + $self->{name_x},
                        $top + 5,
                        -text => $name,
                        -anchor => 'nw',
                            );

    my $fringe_string;
    {
        my $fringe = $thought->get_stored_fringe() or return;
        my @fringe_parts = rnkeysort { $_->[1] } @$fringe;
        for (@fringe_parts) {
            my ($component, $activation) = @$_;
            $fringe_string .= "[$activation] $component; ";
        }
    }

    $Canvas->createText($left + $self->{fringe_x},
                        $top + $self->{fringe_y},
                        -text => $fringe_string,
                        -anchor => 'nw',
                            );
}

1;
