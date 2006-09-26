package S;

use Global;

use List::Util;
use Scalar::Util;

use SNode;
use SHistory;

use SLog;
use SInsertList;

use SSet;
use SErr;
use SChoose;
use SBindings;
use SInstance;
use SPos;
use SSet;
use SFasc;


use SCodelet;
use SAction;
use SCoderack;

use SMetonym;
use SMetonymType;
use SMulti;

#use SCat;
use SCat::OfObj;
use SCat::OfCat;
use SCat::ascending;
use SCat::descending;
use SCat::mountain;
use SCat::sameness;
#use SCat::number;
use SCat::literal;
use SCat::reln_based;
use SCat::ad_hoc;

use SObject;
use SAnchored;
use SElement;
use SWorkspace;

# Need to convert the next four
#use SCat::Derive::assuming;
#use SCat::Derive::blemished;
#use SCat::Derive::blemish_count;
#use SCat::Derive::blemish_position;

#use SReln;
use SReln::Simple;
use SReln::Compound;
use SReln::Position;
use SReln::MetoType;
use SThought;
use SStream;
use SWorkspace;
 
use SCF::All;
use SThought::All;

# use SUtil;

our $ASCENDING  = $SCat::ascending::ascending;
our $DESCENDING = $SCat::descending::descending;
our $MOUNTAIN   = $SCat::mountain::mountain;
our $LITERAL    = $SCat::literal::literal;
#our $number     = $SCat::number::number;
our $SAMENESS    = $SCat::sameness::sameness;
our $RELN_BASED = $SCat::reln_based::reln_based;
our $AD_HOC     = $SCat::ad_hoc::AD_HOC;

our $DOUBLE = SMetonymType->new(
    { category => $S::SAMENESS,
      name     => "each",
      info_loss=> {length => 2},
  }
        );

our $cats_and_blemish_ref =
    [$ascending, $descending, $mountain];

package DIR;
our $LEFT = bless {text => 'left'}, 'DIR';
our $RIGHT = bless {text => 'right'}, 'DIR';
our $UNKNOWN = bless {text => 'unknown'}, 'DIR';
our $NEITHER = bless {text => 'neither'}, 'DIR';

sub LEFT{ $LEFT }
sub RIGHT{ $RIGHT }
sub UNKNOWN{ $UNKNOWN }
sub NEITHER{ $NEITHER }

sub as_text{
    my ( $self ) = @_;
    return $self->{text};
}


package POS_MODE;
our $FORWARD = bless { mode => 'FORWARD'}, 'POS_MODE';
our $BACKWARD = bless { mode => 'FORWARD'}, 'POS_MODE';

sub FORWARD { $FORWARD }
sub BACKWARD{ $BACKWARD }



package METO_MODE;
our $NONE = bless { mode => 'NONE'}, 'METO_MODE';
our $SINGLE = bless { mode => 'SINGLE'}, 'METO_MODE';
our $ALLBUTONE = bless { mode => 'ALLBUTONE'}, 'METO_MODE';
our $ALL = bless { mode => 'ALL'}, 'METO_MODE';
sub NONE { $NONE }
sub SINGLE { $SINGLE }
sub ALLBUTONE { $ALLBUTONE }
sub ALL { $ALL }


package EXTENDIBILE;
our $NO = 0;
our $PERHAPS = bless { mode => 'PERHAPS' }, 'EXTENDIBILE';
our $UNKNOWN = bless {mode => 'UNKNOWN' }, 'EXTENDIBILE';
sub NO{ $NO }
sub PERHAPS { $PERHAPS }
sub UNKNOWN{ $UNKNOWN }

package RELN_SCHEME;
our $NONE = 0;
our $CHAIN = bless { type => 'CHAIN' }, 'RELN_SCHEME';
sub NONE{$NONE}
sub CHAIN{$CHAIN}



1;
