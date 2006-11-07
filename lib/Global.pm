package Global;

our $Steps_Finished;                # Number od codelets/thoughts run.
our $Break_Loop;                    # Boolean: Break out of main loop after this iteration?
our $CurrentCodelet;                # Current codelet.
our $CurrentCodeletFamily;          # Family of current codelet.
our $CurrentRunnableString;         # String representation, for logging purposes.
our $AtLeastOneUserVerification;    # Bool: Has the user ever said 'yes' ? to 'is this next?'
our $TestingOptionsRef;             # Global options when in testing mode.
our $TestingMode;                   # Bool: are we running in testing mode?
our %ExtensionRejectedByUser;       # Rejected continuations.
our $LogString;                     # Generated log string. See log.cong
our %PossibleFeatures;              # Possible features, to catch typos in -f option.
our %Feature;                       # Features turned on from commandline with -f.
our $Options_ref;                   # Global options, includes defaults, configs and commandline

%PossibleFeatures = map { $_ => 1 } qw(interlaced meto);
$LogString = '';

sub clear {
    $Steps_Finished             = 0;
    $AtLeastOneUserVerification = 0;
    %ExtensionRejectedByUser    = ();
    $LogString                  = '';
}

1;
