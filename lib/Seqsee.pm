package Seqsee;
use S;
use version; our $VERSION = version->new( "0.0.3" );


sub run{
    my (@sequence) = @_;
    SWorkspace->clear(); SWorkspace->init(@sequence);
    SStream->clear();    SStream->init();
    SCoderack->clear();  SCoderack->init();

    _SeqseeMainLoop();

}


#### method initialize_codefamilies
# description    :loads up all the codefamilies. Their list occurs in SCF.list
# argument list  :
# return type    :
# context of call:void
# exceptions     :missing codefamily etc. 

sub initialize_codefamilies{
    use UNIVERSAL::require;
    open(IN, "SCF.list") or SErr::Code->throw("Could not open SCF.list");
    while (my $in = <IN>) {
        $in =~ s{#.*}{};
        $in =~ s#\s##g;
        next unless $in;
        $in->require or SErr::Code->throw("Required Codefamily '$in' missing");

        #unless (defined ${"$in"."::logger"}) {
        #    die"Error in processing codefamily '$in': It defines no variable \$logger\n";
        #}

        unless (UNIVERSAL::can($in, "run")) {
            SErr::Code->throw("Error in processing codefamily '$in': It does not define the method run()");
        }
    }
}


#### method _SeqseeMainLoop
# description    :runs the program, basically calling _SeqseeMainStep() until it returns false
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub _SeqseeMainLoop{
    while (_SeqseeMainStep()) {  }
}


#### method _SeqseeMainStep
# description    :Takes a single step: could include running a codelet, and following through some of its consequences. I am not sure I understand how this "central executive" would function
# argument list  :
# return type    : true if the program has not "halted"
# context of call: only from _SeqseeMainLoop
# exceptions     :

sub _SeqseeMainStep{
}

1;
