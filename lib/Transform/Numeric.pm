package Transform::Numeric;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;
use base qw{Transform};
use Memoize;

my %name_of : ATTR(:name<name>);
my %category_of : ATTR(:name<category>);

sub create {
    my ( $package, $name, $category ) = @_;
    die "Transform::Numeric creation attempted without name!" unless $name;
    state %MEMO;
    return $MEMO{ SLTM::encode( $name, $category ) } //= $package->new(
        {   name     => $name,
            category => $category,
        }
    );
}

sub serialize {
    my ($self) = @_;
    my $id = ident $self;
    return SLTM::encode( $name_of{$id}, $category_of{$id} );
}

sub deserialize {
    my ( $package, $str ) = @_;
    $package->create( SLTM::decode($str) );
}

sub get_memory_dependencies {
    my ($self) = @_;
    my $id = ident $self;
    return $category_of{$id};
}

sub get_pure {
    return $_[0];
}

sub FlippedVersion {
    my ($self) = @_;
    my $id = ident $self;
    state $FlipName = {qw{same same pred succ succ pred flip flip no_flip no_flip}};
    return Transform::Numeric->create( $FlipName->{ $name_of{$id} }, $category_of{$id} );
}

sub IsEffectivelyASamenessRelation {
    my ($self) = @_;
    my $id = ident $self;
    return $name_of{$id} eq 'same' ? 1 : 0;
}

sub as_text {
    my ($self) = @_;
    my $id     = ident $self;
    my $cat    = $category_of{$id};
    my $cat_string = ( $cat eq $S::NUMBER ) ? '' : $cat->as_text() . ' ';
    return "$cat_string$name_of{$id}";
}
memoize('as_text');

sub get_complexity_penalty {
    my ($self) = @_;
    my $id = ident $self;
    state $ComplexityLookup = {qw{same 1 succ 0.9 pred 0.9}};
    my $category_compexity = ( $category_of{$id} eq $S::NUMBER ) ? 1 : 0.8;
    return $ComplexityLookup->{ $name_of{$id} } * $category_compexity;
}

sub GetRelationBasedCategory {
    my ($self) = @_;
    my $id = ident $self;

    return SCat::OfObj::RelationTypeBased->Create($self) unless $category_of{$id} eq $S::NUMBER;

    my $name = $name_of{$id};
    given ($name) {
        when ('succ') { return $S::ASCENDING; }
        when ('same') { return $S::SAMENESS; }
        when ('pred') { return $S::DESCENDING; }
        default { confess "Should not reach herre" }
    }
}

1;
