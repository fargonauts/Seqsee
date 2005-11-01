#####################################################
#
#    Package: SThought::SReln_Simple
#
# Thought Type: SReln_Simple
#
# Core:
#
# 
# Fringe:
#
# Extended Fringe:
#
# Actions:
#
#####################################################
#   
#####################################################
package SThought::SReln_Simple;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use English qw(-no_match_vars);
use base qw{SThought};


# variable: %core_of
#  The Core
my %core_of :ATTR( :get<core>);


# method: BUILD
# Builds
#
sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    
    my $core = $core_of{$id} = $opts_ref->{core} or confess "Need core";
    
}

# method: get_fringe
# 
#
sub get_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    return \@ret;
}

# method: get_extended_fringe
# 
#
sub get_extended_fringe{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    return \@ret;
}

# method: get_actions
# 
#
sub get_actions{
    my ( $self ) = @_;
    my $id = ident $self;
    my @ret;

    return @ret;
}

# method: as_text
# textual representation of thought
sub as_text{
    my ( $self ) = @_;
    my $id = ident $self;

    return "SThought::SReln_Simple";
}

1;
