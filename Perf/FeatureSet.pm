package Perf::FeatureSet;

## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use strict;
use warnings;

use List::Util qw{min max sum first};
use Time::HiRes;
use Getopt::Long;
use Storable;

use File::Slurp;
use Smart::Comments;
use IO::Prompt;
use Class::Std;
use Class::Multimethods;

use Carp;
## END OF STANDARD INCLUDES



my @Inconsequential_features = qw{debug CodeletTree
  LogActivations debugMAX};
my %Inconsequential_features =
  map { ( "-f=$_" => 1 ) } @Inconsequential_features;

my %String_of : ATTR(:name<string>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $String_of{$id} = _NormalizeFeatures( $opts_ref->{string} );
}

sub _NormalizeFeatures {
    my ($features_string) = @_;
    return '' unless $features_string;

    my @parts =
      grep { !$Inconsequential_features{$_} }
      split( ';', $features_string );
    return '' unless @parts;
    return join( ';', @parts );
}

use overload 'eq' => sub {
    my ( $a, $b ) = @_;
    return $a->get_string() eq $b->get_string();
};

sub as_str : STRINGIFY {
    my ($self) = @_;
    my $id = ident $self;
    $String_of{$id};
}

1;

