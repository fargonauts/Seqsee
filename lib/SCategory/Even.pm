package SCategory::Even;
use 5.010;
use Moose;
use English qw( -no_match_vars );
use Smart::Comments;

sub NumericInstancer {
  my ($self, $mag) = @_;
  return if $mag % 2;
  return SBindings->create({}, {});
}

sub FindTransformForCat {
  my ( $me, $a, $b ) = @_;

  # Assume $a, $b are integers.

  my $str;
  if ( $a == $b ) {
    $str = "same";
  }
  elsif ( $a + 2 == $b ) {
    $str = "succ";
  }
  elsif ( $a - 2 == $b ) {
    $str = "pred";
  }
  else {
    return;
  }
  return Transform::Numeric->create( $str, $me );
}

sub ApplyTransformForCat {
  my ( $cat, $transform, $object ) = @_;

  # Assume $object is number..

  my $name = $transform->get_name();
  my $mag  = $object;
  my $new_mag;
  given ($name) {
    when ('same') { $new_mag = $mag }
    when ('succ') { $new_mag = $mag + 2 }
    when ('pred') { $new_mag = $mag - 2 }
  }
  $new_mag // return;
  return $new_mag;
};

with 'LTMStorable::Independent';
with 'SCategory::MetonymySpec::NotMetonyable';
with 'SCategory::Numeric';
with 'SCategory';

sub string_to_recreate {
  q{SCategory::Even->new()};
}

sub get_name {
  return "even";
}

sub as_text {
  return "even";
}

__PACKAGE__->meta->make_immutable;
1;
