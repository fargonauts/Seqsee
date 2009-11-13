package Transform;
use 5.10.0;
use Class::Std;
use Class::Multimethods;
use strict;
use Carp;

multimethod FindTransform => ( '*', '*', '*' ) => sub {
  *__ANON__ = "((__ANON__ FindTransform ***))";
  my ( $a, $b, $cat ) = @_;
  $cat->FindTransformForCat( $a, $b );
};

{
  my $numeric_FindTransorm = sub {
    *__ANON__ = "((__ANON__ FindTransform SInt/Seqsee::Element SInt/Seqsee::Element))";
    my ( $a, $b ) = @_;
    my @common_categories = $a->get_common_categories($b) or confess;
    if ( grep { not defined $_ } @common_categories ) {
      confess
      "undef in common_categories FindTransform SInt/Seqsee::Element SInt/Seqsee::Element:"
      . join( ', ', @common_categories );
    }
    my $cat = SLTM::SpikeAndChoose( 0, @common_categories ) // $S::NUMBER;
    if ( $cat->IsNumeric() ) {
      $cat->FindTransformForCat( $a->get_mag(), $b->get_mag() );
    }
    else {
      $cat->FindTransformForCat( $a, $b );
    }
  };
  multimethod FindTransform => qw{SInt SInt}         => $numeric_FindTransorm;
  multimethod FindTransform => qw{Seqsee::Element Seqsee::Element} => $numeric_FindTransorm;
}

multimethod FindTransform => qw(# #) => sub {
  *__ANON__ = "((__ANON__ FindTransform ##))";
  my ( $a, $b ) = @_;
  $S::NUMBER->FindTransformForCat( $a, $b );
};

multimethod FindTransform => qw(Seqsee::Anchored Seqsee::Anchored) => sub {
  *__ANON__ = "((__ANON__ FindTransform Seqsee::Anchored Seqsee::Anchored))";
  my ( $a, $b ) = @_;
  my @common_categories = $a->get_common_categories($b) or return;
  my $cat = SLTM::SpikeAndChoose( 10, @common_categories ) or return;
  $cat->FindTransformForCat( $a, $b );
};

# More FindTransform in Transform::Dir

multimethod ApplyTransform => qw(Transform::Numeric #) => sub {
  *__ANON__ = "((__ANON__ ApplyTransform Transform::Numeric #))";
  my ( $transform, $num ) = @_;
  $transform->get_category()->ApplyTransformForCat( $transform, $num );
};

multimethod ApplyTransform => qw(Transform::Numeric SInt) => sub {
  *__ANON__ = "((__ANON__ ApplyTransform Transform::Numeric SInt))";
  my ( $transform, $num ) = @_;
  my $new_mag =
  $transform->get_category()
  ->ApplyTransformForCat( $transform, $num->get_mag() ) // return;
  SInt->new($new_mag);
};

multimethod ApplyTransform => qw(Transform::Numeric Seqsee::Element) => sub {
  *__ANON__ = "((__ANON__ ApplyTransform Transform::Numeric Seqsee::Element))";
  my ( $transform, $num ) = @_;
  my $new_mag =
  $transform->get_category()
  ->ApplyTransformForCat( $transform, $num->get_mag() ) // return;
  Seqsee::Element->create( $new_mag, -1 );
};

multimethod ApplyTransform => qw(Transform::Structural Seqsee::Object) => sub {
  my ( $transform, $object ) = @_;
  $transform->get_category()->ApplyTransformForCat( $transform, $object );
};

{
  my $Fail = sub {
    return;
  };
  multimethod FindTransform  => qw{SInt Seqsee::Element}                => $Fail;
  multimethod FindTransform  => qw{Seqsee::Element SInt}                => $Fail;
  multimethod FindTransform  => qw{Seqsee::Anchored SInt}               => $Fail;
  multimethod FindTransform  => qw{SInt Seqsee::Anchored}               => $Fail;
  multimethod ApplyTransform => qw{Transform::Numeric Seqsee::Anchored} => $Fail;
}

sub CheckSanity {
  my ($self) = @_;
  return 1 unless $self->isa('Transform::Structural');
  my $cat  = $self->get_category();
  my @atts = keys %{ $self->get_changed_bindings };
  unless ( $cat->AreAttributesSufficientToBuild(@atts) ) {
    my $cat_name = $cat->as_text();
    main::message("This transform is bogus! CAT=$cat_name ATTS=@atts");

    # die("This transform is bogus! CAT=$cat_name ATTS=@atts");
    return;
  }
  return 1;
}

1;
