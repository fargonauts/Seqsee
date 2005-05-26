use Test::More tests=> 12;
use Test::Exception;
use Test::Deep;
use blib;

use SBuiltObj;
use SBindings;
use SCat;

BEGIN{
  use_ok "SCat::descending";
}

my $cat = $SCat::descending::descending;
isa_ok($cat, "SCat" );

BUILDING: {
  my $ret;
  $ret = $cat->build(start => 5, end => 2);
  isa_ok($ret, "SBuiltObj");
  cmp_deeply($ret->items, [5, 4, 3, 2], "start => 5, end => 2");
  $ret = $cat->build(start => 2, end => 2);
  cmp_deeply($ret->items, [2], "start => 2, end => 2");
  $ret = $cat->build(start => 1, end => 2);
  cmp_deeply($ret->items, [], "start => 1, end => 2");
}

IS_INSTANCE: {
  my $bindings;
  $bindings = $cat->is_instance(4, 3, 2);
  isa_ok($bindings, "SBindings");
  is($bindings->{start}, 4);
  is($bindings->{end}, 2);

  $bindings = $cat->is_instance(2);
  is($bindings->{start}, 2);
  is($bindings->{end}, 2);

  $bindings = $cat->is_instance();
  isa_ok($bindings, "SBindings");
}
