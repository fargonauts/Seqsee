package Tk::SWorkspace2;
use strict;
use warnings;
use Carp;
use Config::Std;
use Smart::Comments;
use Tk::widgets qw{Canvas};
use List::Util qw(min max);
use base qw/Tk::Derived Tk::Canvas/;

our $canvas;
our %Id2Obj;

my ($Height, $Width, $Margin, $eff_width, $eff_height);
my (@element_options, @line_options, @reln_options,
    @group_options, @group_meto_options,
        );
my ($space_per_elem);
my %RelationAnchor;
BEGIN {
    read_config 'config/GUI_ws2.conf' => my %config;
    @element_options  = %{$config{elements}};
    @line_options     = %{$config{line}};
    @reln_options = %{$config{reln}}; 
    @group_options = %{$config{group}}; 
    @group_meto_options= %{$config{group_meto}};
    $Margin            = $config{placing}{-margin};
}

Construct Tk::Widget 'SWorkspace2';
sub Populate{
    my ( $self, $args ) = @_;

    $canvas = $self;
    $Height = $args->{'-height'} or confess;
    $Width  = $args->{'-width'} or confess;

    #    $self->SUPER::Populate($args);
    $eff_width  = $Width - 2 * $Margin;
    ### eff_width: $eff_width
    $eff_height = $Height - 2 * $Margin;
}

sub clear{
    $canvas->delete('all');
}

sub Update{
    $canvas->delete('all');
    %RelationAnchor = ();
    draw_groups();
    draw_elements();
    draw_relations();
}

sub new_object{
    my ( $obj ) = shift;
    my $id = $obj->draw_ws2( @_ );
    $Id2Obj{$id} = $obj;
    return $id;
}

sub draw_elements{
    # main::message("draw_elements called");
    my $elements_count = $SWorkspace::elements_count;
    $space_per_elem = $eff_width / ( $elements_count + 1);
    ## $space_per_elem
    ## $Margin
    
    my $counter = 0;
    for my $elt (@SWorkspace::elements) {
        new_object( $elt, $counter, $Margin + (0.5+$counter) * $space_per_elem,
                    $Margin + $eff_height * 0.5
                        );
        $counter++;
    }
}

sub draw_groups{
    for my $gp (values %SWorkspace::groups) {
        $gp->draw_ws2();
    } 
}

sub draw_relations{
    for my $rel (values %SWorkspace::relations) {
        $rel->draw_ws2();
    }
}


sub SElement::draw_ws2{
    my ( $self ) = shift;
    my $idx = shift;
    my $id = $canvas->createText( @_, @element_options,
                                  -text => $self->get_mag(),
                                  -tags => [$self, "element", $idx],
                                      );
    $RelationAnchor{$self} = [@_[0,1]];
    return $id;
}

sub SAnchored::draw_ws2{
    my ( $self ) = @_;
    my (@edges) = $self->get_edges();
    my $leftx = $Margin + ($edges[0] + 0.1) * $space_per_elem;
    my $rightx = $Margin + ($edges[1] + 0.9) * $space_per_elem;
    my $top =   $Margin + $eff_height * 0.4;
    my $bottom = $Margin + $eff_height * 0.6;
    ## Drawing group: $leftx, $top, $rightx, $bottom
    $RelationAnchor{$self} = [($leftx + $rightx) / 2, $top];
    my @options = $self->get_metonym_activeness() ?
        @group_meto_options : @group_options;
    return $canvas->createOval($leftx, $top, $rightx, $bottom, @options);
}

sub SReln::draw_ws2{
    my ( $self ) = @_;
    my @ends = $self->get_ends();
    my ($x1, $y1) = @{$RelationAnchor{$ends[0]} || []};
    my ($x2, $y2) = @{$RelationAnchor{$ends[1]} || []};
    return unless ($x1 and $x2);
    ## drawing a relation: $x1, $y1, $x2, $y2
    return $canvas->createLine($x1, $y1,
                               ($x1 + $x2) / 2, $Margin + 0.2 * $eff_height,
                               $x2, $y2,
                               @reln_options,
                                  );
}
