{

package SCF::FocusOn;
our $package_name_ = 'SCF::FocusOn';
our $NAME = 'Read from Workspace';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $what = $opts_ref->{what} // 0;

    
        if ($what) {
            ContinueWith( SThought->create($what) );
        }

        # Equivalent to Reader
        if ( SUtil::toss(0.1) ) {
            SWorkspace::__CreateSamenessGroupAround($SWorkspace::ReadHead);
            return;
        }
        my $object = SWorkspace::__ReadObjectOrRelation() // return;
        main::message("Focusing on: ".$object->as_text()) if $Global::debugMAX;
        ContinueWith( SThought->create($object) );
    
}
 # end run


1;
} # end surrounding

;


{

package SCF::LookForSimilarGroups;
our $package_name_ = 'SCF::LookForSimilarGroups';
our $NAME = 'Look for Similar Groups';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $group = $opts_ref->{group} // confess "Needed 'group', only got " . join(';', keys %$opts_ref);

    my $wset = SWorkspace::__GetObjectsBelongingToSimilarCategories($group);
        return if $wset->is_empty();

        for ( $wset->choose_a_few_nonzero(3) ) {
            SCodelet->new("FocusOn", 
                         50,
                         { what => $_ })->schedule(); 
;
        }
    
}
 # end run


1;
} # end surrounding

;


{

package SCF::MergeGroups;
our $package_name_ = 'SCF::MergeGroups';
our $NAME = 'Merge Groups';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $a = $opts_ref->{a} // confess "Needed 'a', only got " . join(';', keys %$opts_ref);
	my $b = $opts_ref->{b} // confess "Needed 'b', only got " . join(';', keys %$opts_ref);

    
        return if $a eq $b;
        SWorkspace::__CheckLiveness($a, $b) or return;
        my @items = SUtil::uniq(@$a, @$b);
        @items = SWorkspace::__SortLtoRByLeftEdge(@items);

        return if SWorkspace::__AreThereHolesOrOverlap(@items);
        my $new_group;
        
       eval { 
            my @unstarred_items = map { $_->GetUnstarred() } @items;
            ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
            SWorkspace::__CheckLiveness(@unstarred_items) or return;    # dead objects.
            $new_group = SAnchored->create(@unstarred_items);
            if ($new_group and $a->get_underlying_reln()) {
                $new_group->set_underlying_ruleapp($a->get_underlying_reln()->get_rule());
                $a->CopyCategoriesTo($new_group);
                SWorkspace->add_group($new_group);
            }
         };
       if (my $err = $EVAL_ERROR) {
          CATCH_BLOCK: { if (UNIVERSAL::isa($err, 'SErr::ConflictingGroups')) {  return ; last CATCH_BLOCK; }die $err }
       }
    

    
}
 # end run


1;
} # end surrounding




{

package SCF::CleanUpGroup;
our $package_name_ = 'SCF::CleanUpGroup';
our $NAME = 'Clean Up Group';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $group = $opts_ref->{group} // confess "Needed 'group', only got " . join(';', keys %$opts_ref);

     
        return unless SWorkspace::__CheckLiveness($group);
        my @edges = $group->get_edges();
        my @potential_cruft = SWorkspace::__GetObjectsWithEndsNotBeyond(@edges);
        SWorkspace::__DeleteNonSubgroupsOfFrom({ of => [$group],
                                                 from => \@potential_cruft,
                                             });
    
}
 # end run


1;
} # end surrounding




{

package SCF::DoTheSameThing;
our $package_name_ = 'SCF::DoTheSameThing';
our $NAME = 'Do The Same Thing';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';

 multimethod '__PlonkIntoPlace'; 

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $group = $opts_ref->{group} // 0;
	my $category = $opts_ref->{category} // 0;
	my $direction = $opts_ref->{direction} // 0;
	my $transform = $opts_ref->{transform} // confess "Needed 'transform', only got " . join(';', keys %$opts_ref);

    
        unless ( $group or $category ) {
            $category = $transform->get_category();
        }
        if ( $group and $category ) {
            confess "Need exactly one of group and category: got both.";
        }
        $direction ||= SChoose->choose( [ 1, 1 ], [ $DIR::LEFT, $DIR::RIGHT ] );
        unless ($group) {
            my @groups_of_cat = SWorkspace::__GetObjectsBelongingToCategory($category) or return;
            $group = SWorkspace::__ChooseByStrength( @groups_of_cat );
        }

        #main::message("DoTheSameThing: group=" . $group->as_text()." transform=".$transform->as_text());
        my $effective_transform
            = $direction eq $DIR::RIGHT ? $transform : $transform->FlippedVersion();
        $effective_transform or return;
        $effective_transform->CheckSanity() or confess "Transform insane!";

        my $expected_next_object;

        # BandAid: The following occasionally crashes.
        eval {$expected_next_object  = ApplyTransform( $effective_transform, $group )} or return;
        @$expected_next_object or return;

        my $next_pos = SWorkspace::__GetPositionInDirectionAtDistance(
            {   from_object => $group,
                direction   => $direction,
                distance    => DISTANCE::Zero(),
            }
        );
        return if ( !defined($next_pos) or $next_pos > $SWorkspace::ElementCount );

        my $is_this_what_is_present;
        
       eval { 
            $is_this_what_is_present = SWorkspace->check_at_location(
                {   start     => $next_pos,
                    direction => $direction,
                    what      => $expected_next_object,
                }
            );
         };
       if (my $err = $EVAL_ERROR) {
          CATCH_BLOCK: { if (UNIVERSAL::isa($err, 'SErr::ElementsBeyondKnownSought')) { 
              return;
            ; last CATCH_BLOCK; }die $err }
       }
    ;
        
        if ($is_this_what_is_present) {
            my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $expected_next_object );
            return unless $plonk_result->PlonkWasSuccessful();
            my $wso = $plonk_result->get_resultant_object() or return;

            $wso->describe_as($effective_transform->get_category());
            my @ends = ($direction eq $DIR::RIGHT) ? ($group, $wso) : ($wso, $group);
            SRelation->new({first=>$ends[0], second => $ends[1], type => $transform})->insert();
            #main::message("yeah, that was present!");
        }
    
}
 # end run


1;
} # end surrounding




{

package SCF::CreateGroup;
our $package_name_ = 'SCF::CreateGroup';
our $NAME = 'Create Group';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $items = $opts_ref->{items} // confess "Needed 'items', only got " . join(';', keys %$opts_ref);
	my $category = $opts_ref->{category} // 0;
	my $transform = $opts_ref->{transform} // 0;

    
      my ( @left_edges, @right_edges );
        for (@$items) {
            push @left_edges,  $_->get_left_edge;
            push @right_edges, $_->get_right_edge;
        }
        my $left_edge  = List::Util::min(@left_edges);
        my $right_edge = List::Util::max(@right_edges);
        my $is_covering
            = scalar( SWorkspace::__GetObjectsWithEndsBeyond( $left_edge, $right_edge ) );
        return if $is_covering;

        unless ($category or $transform) {
            confess "At least one of category or transform needed. Got neither.";
        }
        if ($category and $transform) {
            confess "Exactly one of  category or transform needed. Got both.";
        }

        unless ($category) {
            # Generate from transform.
            confess "transform should be a Transform!" unless $transform->isa('Transform');
            if ($transform->isa('Transform::Numeric')) {
                $category = $transform->GetRelationBasedCategory();
            } else {
                $category = SCat::OfObj::RelationTypeBased->Create($transform);
            }
        }

        my @unstarred_items = map { $_->GetUnstarred() } @$items;
        ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
        SWorkspace::__CheckLiveness(@unstarred_items) or return;    # dead objects.
        my $new_group;
        
       eval {  $new_group = SAnchored->create(@unstarred_items);  };
       if (my $err = $EVAL_ERROR) {
          CATCH_BLOCK: { if (UNIVERSAL::isa($err, 'SErr::HolesHere')) {  return; ; last CATCH_BLOCK; }die $err }
       }
    ;
        return unless $new_group;
        $new_group->describe_as($category) or return;
        if ($transform) {
            $new_group->set_underlying_ruleapp($transform);
        }
        SWorkspace->add_group($new_group);
    
}
 # end run


1;
} # end surrounding




{

package SCF::FindIfRelatedRelations;
our $package_name_ = 'SCF::FindIfRelatedRelations';
our $NAME = 'Find if Analogies are Related';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $a = $opts_ref->{a} // confess "Needed 'a', only got " . join(';', keys %$opts_ref);
	my $b = $opts_ref->{b} // confess "Needed 'b', only got " . join(';', keys %$opts_ref);

    my ( $af, $as, $bf, $bs ) = ( $a->get_ends(), $b->get_ends() );
        if ($bs eq $af) {
            # Switch the two...
            ($af, $as, $a, $bf, $bs, $b) = ($bf, $bs, $b, $af, $as, $a);
        }

        return unless $as eq $bf;

        my ($a_transform, $b_transform) = ($a->get_type(), $b->get_type());
        if ($a_transform eq $b_transform) {
            SCodelet->new("CreateGroup", 
                         100,
                         { items => [$af, $as, $bs],
                                        transform => $a_transform,
                                    })->schedule(); 
;
        } elsif ($Global::Feature{Alternating} and
            $a_transform->get_category() eq $b_transform->get_category()) {
            # There is a chance that these are somehow alternating...
            my $new_transform = SCat::OfObj::Alternating->CheckForAlternation(
                # $a_transform->get_category(),
                $af, $as, $bs);
            if ($new_transform) {
                SCodelet->new("CreateGroup", 
                         100,
                         { items => [$af, $as, $bs],
                                            transform => $new_transform,
                                        })->schedule(); 
;
            }
        }
    
}
 # end run


1;
} # end surrounding




{

package SCF::CheckIfAlternating;
our $package_name_ = 'SCF::CheckIfAlternating';
our $NAME = 'Check if Alternating';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $first = $opts_ref->{first} // confess "Needed 'first', only got " . join(';', keys %$opts_ref);
	my $second = $opts_ref->{second} // confess "Needed 'second', only got " . join(';', keys %$opts_ref);
	my $third = $opts_ref->{third} // confess "Needed 'third', only got " . join(';', keys %$opts_ref);

    my $transform_to_consider;

        my $t1 = FindTransform($first, $second);
        my $t2 = FindTransform($second, $third);
        if ($t1 and $t1 eq $t2) {
            $transform_to_consider = $t1;
        } else {
            $transform_to_consider = SCat::OfObj::Alternating->CheckForAlternation($first, $second, $third) or return;
        }
        SCodelet->new("CreateGroup", 
                         100,
                         { items => [$first, $second, $third],
                                    transform => $transform_to_consider,
                                })->schedule(); 
;
    
}
 # end run


1;
} # end surrounding




{

package SCF::FindIfRelated;
our $package_name_ = 'SCF::FindIfRelated';
our $NAME = 'Check Whether Analogous';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $a = $opts_ref->{a} // confess "Needed 'a', only got " . join(';', keys %$opts_ref);
	my $b = $opts_ref->{b} // confess "Needed 'b', only got " . join(';', keys %$opts_ref);

    return unless SWorkspace::__CheckLiveness( $a, $b );
        ( $a, $b ) = SWorkspace::__SortLtoRByLeftEdge( $a, $b );
        if ( $a->overlaps($b) ) {
            my ( $ul_a, $ul_b ) = ( $a->get_underlying_reln(), $b->get_underlying_reln() );
            return unless ( $ul_a and $ul_b );
            return unless $ul_a->get_rule() eq $ul_b->get_rule();
            return unless ("$a->[-1]" ~~ @$b); #i.e., actual subgroups overlap.
            SCodelet->new("MergeGroups", 
                         200,
                         { a => $a, b => $b })->schedule(); 
;
            return;
        }

        if (my $relation = $a->get_relation($b)) {
            SLTM::SpikeBy(10, $relation->get_type());
            SCodelet->new("FocusOn", 
                         100,
                         { what => $relation })->schedule(); 
;
            return;
        }

        my $reln_type = FindTransform($a, $b) || return;
        SLTM::SpikeBy(10, $reln_type);
        
        # insert relation with certain probability:
        my $transform_complexity = $reln_type->get_complexity();
        my $transform_activation = SLTM::GetRealActivationsForOneConcept($reln_type);
        my $distance = SWorkspace::__FindDistance($a, $b, $DISTANCE_MODE::ELEMENT)->GetMagnitude();
        my $sense_in_continuing = ShouldIContinue($transform_complexity,
                                                  $transform_activation,
                                                  $distance
                                                      );
        main::message("Sense in continuing=$sense_in_continuing") if $Global::debugMAX;
        return unless SUtil::toss($sense_in_continuing);

        SLTM::SpikeBy(10, $reln_type);
        my $relation = SRelation->new({first => $a,
                                       second => $b,
                                       type => $reln_type
                                           });
        $relation->insert();
        SCodelet->new("FocusOn", 
                         200,
                         { what => $relation })->schedule(); 
;
    
}
 # end run

        sub ShouldIContinue {
            my ( $transform_complexity, $transform_activation, $distance ) = @_;
            # transform_activation and transform_complexity are between 0 and 1

            my $not_continue = $transform_complexity * (1 - $transform_activation)
                * sqrt($distance);
            return 1 - $not_continue;
        }
    

1;
} # end surrounding




{

package SCF::AttemptExtensionOfRelation;
our $package_name_ = 'SCF::AttemptExtensionOfRelation';
our $NAME = 'Attempt Extension of Analogy';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';

 multimethod '__PlonkIntoPlace'; multimethod 'SanityCheck'; 

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $core = $opts_ref->{core} // confess "Needed 'core', only got " . join(';', keys %$opts_ref);
	my $direction = $opts_ref->{direction} // confess "Needed 'direction', only got " . join(';', keys %$opts_ref);

    ## Codelet started:
        my $transform = $core->get_type();
        my ($end1, $end2) = $core->get_ends();
        ## ends: $end1->as_text, $end2->as_text
        my ($effective_transform, $object_at_end);
        if ($direction eq $DIR::RIGHT) {
            ($effective_transform, $object_at_end) = ($transform, $end2);
            ## Thought it was right:
        } else {
            $effective_transform = $transform->FlippedVersion() or return;
            $object_at_end = $end1;        
        }

        my $distance = SWorkspace::__FindDistance( $end1, $end2 );
        ## oae_l: $object_at_end->get_left_edge(), $distance, $direction
        my $next_pos = SWorkspace::__GetPositionInDirectionAtDistance(
            {   from_object => $object_at_end,
                direction   => $direction,
                distance    => $distance,
            }
        );
        ## next_pos: $next_pos
        return unless defined($next_pos);
        ## distance, next_pos: $distance, $next_pos
        return if ( !defined($next_pos) or $next_pos > $SWorkspace::ElementCount );

        my $what_next = ApplyTransform( $effective_transform,
                                        $object_at_end->GetEffectiveObject() );
        return unless $what_next;
        return unless @$what_next;    # 0 elts also not okay

        my $is_this_what_is_present;
        
       eval { 
            $is_this_what_is_present = SWorkspace->check_at_location(
                {   start     => $next_pos,
                    direction => $direction,
                    what      => $what_next
                }
            );
         };
       if (my $err = $EVAL_ERROR) {
          CATCH_BLOCK: { if (UNIVERSAL::isa($err, 'SErr::ElementsBeyondKnownSought')) { 
              return unless EstimateAskability($core, $transform, $end1, $end2);
              SCodelet->new("AskIfThisIsTheContinuation", 
                         100,
                         {
                  relation  => $core,
                  exception => $err,
                  expected_object => $what_next,
                  start_position => $next_pos,
                  known_term_count => $SWorkspace::ElementCount,
                      })->schedule(); 
;
            ; last CATCH_BLOCK; }die $err }
       }
    ;

        ## is_this_what_is_present:
        if ($is_this_what_is_present) {
            SLTM::SpikeBy(10, $transform);
            
            my $plonk_result = __PlonkIntoPlace( $next_pos, $direction, $what_next );
            return unless $plonk_result->PlonkWasSuccessful();
            my $wso = $plonk_result->get_resultant_object();

            my $cat = $transform->get_category();
            SLTM::SpikeBy(10, $cat);
            $wso->describe_as($cat) or return;

            my $reln_to_add;
            if ($direction eq $DIR::RIGHT) {
                    $reln_to_add = SRelation->new({first => $end2,
                                                   second => $wso,
                                                   type => $transform,
                                               });
                } else {
                    $reln_to_add = SRelation->new({first => $wso,
                                                   second => $end1,
                                                   type => $transform,
                                               });
               
                }
            $reln_to_add->insert() if $reln_to_add;
            ## HERE1:
            # SanityCheck($reln_to_add);
            ## Here2:
        }
    
}
 # end run

        sub EstimateAskability {
            my ( $relation, $transform, $end1, $end2 ) = @_;
            if (SWorkspace->AreThereAnySuperSuperGroups($end1) or
                    SWorkspace->AreThereAnySuperSuperGroups($end2)
                    ) {
                return 0;
            }

            my $supergroup_penalty = 0;
            if (SWorkspace->GetSuperGroups($end1) or SWorkspace->GetSuperGroups($end2)) {
                $supergroup_penalty = 0.6;
            }

            my $transform_activation = SLTM::GetRealActivationsForOneConcept($transform);
            return SUtil::toss($transform_activation * ( 1 - $supergroup_penalty ));
        }
    

1;
} # end surrounding




{

package SCF::AttemptExtensionOfGroup_proposed;
our $package_name_ = 'SCF::AttemptExtensionOfGroup_proposed';
our $NAME = 'Attempt Extension of Group';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';

 multimethod '__PlonkIntoPlace'; 

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $object = $opts_ref->{object} // confess "Needed 'object', only got " . join(';', keys %$opts_ref);
	my $direction = $opts_ref->{direction} // confess "Needed 'direction', only got " . join(';', keys %$opts_ref);

    SWorkspace::__CheckLiveness($object) or return;
        my $underlying_reln = $object->get_underlying_reln() or return;
        my $transform = $underlying_reln->get_rule()->get_transform();

        my ($next_position, $expected_next_object);
        given ($direction) {
            when ($DIR::RIGHT) {
                $expected_next_object = ApplyTransform($transform, $object->[-1]) or return;
                $next_position = $object->get_right_edge() + 1;
            }
            when ($DIR::LEFT) {
                my $effective_transform = $transform->FlippedVersion() or return;
                $expected_next_object = ApplyTransform($effective_transform, $object->[0]);
                $next_position = $object->get_left_edge() - 1;
                return if $next_position == -1;
            }
        }

        my $result_of_something_like =
            SWorkspace->LookForSomethingLike({
                object => $expected_next_object,
                start_position => $next_position,
                direction => $direction,
                    });

        if (my $to_ask = $result_of_something_like->get_to_ask()) {
            if (EstimateAskability($object)) {
                SCodelet->new("AskIfThisIsTheContinuation", 
                         100,
                         {
                    %$to_ask,
                    group => $object,
                    known_term_count => $SWorkspace::ElementCount,
                        })->schedule(); 
;
                return;
            }
        }
        if ($Global::Feature{AllowSquinting}) {
            confess "IMPLEMENT ME!";
        } else {
            my $literally_present = $result_of_something_like->get_literally_present() or return;
            my $plonk_result = __PlonkIntoPlace(@$literally_present);
            my $new_object = $plonk_result->get_resultant_object() or return;

            given ($direction) {
                when ($DIR::RIGHT) {
                    # main::message("In AttemptExtensionOfGroup: $object->[-1] and $new_object and $transform");
                    my $new_relation = SRelation->new({first => $object->[-1],
                                                       second => $new_object, 
                                                       type => $transform,
                                                   });
                    $new_relation->insert() or return;
                    $object->Extend($new_object, 1);
                }
                when ($DIR::LEFT) {
                    my $effective_transform = $transform->FlippedVersion() or return;
                    my $new_relation = SRelation->new({first => $new_object,
                                                       second => $object->[0], 
                                                       type => $effective_transform,
                                                   });
                    $new_relation->insert() or return;
                    $object->Extend($new_object, 0);
                }
            }
        }
    
}
 # end run

          sub EstimateAskability {
              my ( $group ) = @_;
              
          }
      

1;
} # end surrounding

