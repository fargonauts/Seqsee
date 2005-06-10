use blib;
use Test::Seqsee;
BEGIN { plan tests => 7; }

use SBuiltObj;
use SCat;
use SPos;

use SBlemish;
use SBlemish::double;

use SCat::mountain;

my $bl      = $SBlemish::double::double;
my $cat_mtn = $SCat::mountain::mountain;

my $bo = $cat_mtn->build(foot => 2, peak => 5);

#################################
# ADDING BLEMISHES

Numbered: {
  my $pos = new SPos 1;
  my $bo_derived = $bo->apply_blemish_at($bl, $pos);
  $bo_derived->structure_ok([[2, 2], 3, 4, 5, 4, 3, 2]);
}

Named: {
  my $pos = new SPos "peak";
  my $bo_derived = $bo->apply_blemish_at($bl, $pos);
  $bo_derived->structure_ok([2, 3, 4, [5, 5], 4, 3, 2]);
}

Everywhere: {
 SKIP: {
    skip "positions like 'everywhere' not yet implemented", 1;
    my $pos = new SPos::Range "all";
    my $bo_derived = $bo->apply_blemish_at($bl, $pos);
    $bo_derived->structure_ok([[2, 2], [3, 3], [4, 4], [5, 5], [4, 4], [3, 3], [2, 2]]);
  }
}

################################
# Testing for blemishes

my $bo2 = new SBuiltObj(3, 3);
my $bo3 = new SBuiltObj(3, 3, 4);
my $bo4 = new_deep SBuiltObj([2, 3], [2, 3]);
my $bo5 = new_deep SBuiltObj([2, 3], [2, 3, 4]);

my $bindings;

$bindings = $bl->is_blemished($bo2);
ok exists($bindings->{what});

$bindings = $bl->is_blemished($bo3);
undef_ok $bindings;

$bindings = $bl->is_blemished($bo4);
ok exists($bindings->{what});

$bindings = $bl->is_blemished($bo5);
undef_ok $bindings;
