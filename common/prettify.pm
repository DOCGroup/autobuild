#
# $Id$
#

###############################################################################
###############################################################################

package Prettify::Full_HTML;

use strict;
use warnings;

use FileHandle;

###############################################################################

sub new ($)
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    my $basename = shift;
    my $filename = $basename . "_Full.html";
    
    $self->{ERROR_COUNTER} = 0;
    $self->{WARNING_COUNTER} = 0;
    $self->{SECTION_COUNTER} = 0;
    $self->{SUBSECTION_COUNTER} = 0;
    $self->{FH} = new FileHandle ($filename, 'w');

    bless ($self, $class);
    return $self;
}

sub Header ()
{
    my $self = shift;
    print {$self->{FH}} "<html>\n";
    print {$self->{FH}} "<head>\n<title>Daily Build Log</title>\n</head>\n";
    print {$self->{FH}} "<body bgcolor=\"white\">\n";
    print {$self->{FH}} "<h1>Daily Build Log</h1>\n";
}

sub Footer ()
{
    my $self = shift;
    print {$self->{FH}} "</body>\n";
    print {$self->{FH}} "</html>\n";
}

sub Section ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    my $counter = ++$self->{SECTION_COUNTER};
    
    print {$self->{FH}} "<a name=\"section_$counter\"></a>\n";
    print {$self->{FH}} "<hr><h2>$s</h2>\n";
}

sub Description ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    print {$self->{FH}} "<h3>$s</h3>\n";
}

sub Timestamp ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    print {$self->{FH}} "<b>$s</b><br><br>\n";
}

sub Subsection ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    my $counter = ++$self->{SUBSECTION_COUNTER};
    
    print {$self->{FH}} "<a name=\"subsection_$counter\"></a>\n";

    print {$self->{FH}} "<br><b>$s</b><br><br><br>\n";
}

sub Error ($)
{
    my $self = shift;
    my $s = shift;
 
    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    my $counter = ++$self->{ERROR_COUNTER};
    
    print {$self->{FH}} "<a name=\"error_$counter\"></a>\n";
    print {$self->{FH}} "<font color=\"FF0000\"><tt>$s</tt></font><br>\n";
}

sub Warning ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    my $counter = ++$self->{WARNING_COUNTER};
    
    print {$self->{FH}} "<a name=\"warning_$counter\"></a>\n";
    print {$self->{FH}} "<font color=\"FF7700\"><tt>$s</tt></font><br>\n";
}

sub Normal ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    print {$self->{FH}} "<tt>$s</tt><br>\n";
}


###############################################################################
###############################################################################

package Prettify::Brief_HTML;

use strict;
use warnings;

use FileHandle;

###############################################################################

sub new ($)
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    my $basename = shift;
    my $filename = $basename . "_Brief.html";
    
    $basename =~ s/^.*\///;
    
    $self->{FULLHTML} = $basename . "_Full.html";
    $self->{ERROR_COUNTER} = 0;
    $self->{WARNING_COUNTER} = 0;
    $self->{SECTION_COUNTER} = 0;
    $self->{SUBSECTION_COUNTER} = 0;
    $self->{FH} = new FileHandle ($filename, 'w');

    bless ($self, $class);
    return $self;
}

sub Header ()
{
    my $self = shift;
    print {$self->{FH}} "<html>\n";
    print {$self->{FH}} "<head>\n<title>Daily Build Log (Brief)</title>\n</head>\n";
    print {$self->{FH}} "<body bgcolor=\"white\">\n";
    print {$self->{FH}} "<h1>Daily Build Log (Brief)</h1>\n";
}

sub Footer ()
{
    my $self = shift;
    print {$self->{FH}} "</body>\n";
    print {$self->{FH}} "</html>\n";
}

sub Section ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    my $counter = ++$self->{SECTION_COUNTER};
    
    # Save for later use
    
    $self->{LAST_SECTION} = $s;
}

sub Description ($)
{
    my $self = shift;
    
    # Ignore
}

sub Timestamp ($)
{
    my $self = shift;
    # Ignore
}

sub Subsection ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    my $counter = ++$self->{SUBSECTION_COUNTER};

    # Save for later use    
    
    $self->{LAST_SUBSECTION} = $s;
}

sub Print_Sections ()
{
    my $self = shift;
   
    if (defined $self->{LAST_SECTION}) {
        print {$self->{FH}} "<a name=\"section_$self->{SECTION_COUNTER}\"></a>";
        print {$self->{FH}} "<hr><h2>$self->{LAST_SECTION}</h2>\n";
        $self->{LAST_SECTION} = undef;
    }
    if (defined $self->{LAST_SUBSECTION}) {
        print {$self->{FH}} "<a name=\"subsection_$self->{SUBSECTION_COUNTER}\"></a>";
        print {$self->{FH}} "<hr><h3>$self->{LAST_SUBSECTION}</h3>\n";
        $self->{LAST_SUBSECTION} = undef;
    }
}

sub Error ($)
{
    my $self = shift;
    my $s = shift;
 
    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    
    my $counter = ++$self->{ERROR_COUNTER};
    
    $self->Print_Sections ();

    print {$self->{FH}} "<a name=\"error_$counter\"></a>\n";
    print {$self->{FH}} "<tt>[<a href=\"$self->{FULLHTML}#error_$counter"
                        . "\">Details</a>] </tt>";
    print {$self->{FH}} "<font color=\"FF0000\"><tt>$s</tt></font><br>\n";
}

sub Warning ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs 
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    my $counter = ++$self->{WARNING_COUNTER};
    
    $self->Print_Sections ();

    print {$self->{FH}} "<a name=\"warning_$counter\"></a>\n";
    print {$self->{FH}} "<tt>[<a href=\"$self->{FULLHTML}#warning_$counter"
                        . "\">Details</a>] </tt>";
    print {$self->{FH}} "<font color=\"FF7700\"><tt>$s</tt></font><br>\n";
}

sub Normal ($)
{
    my $self = shift;
    
    # Ignore
}


###############################################################################
###############################################################################

package Prettify;

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use FileHandle;

###############################################################################

sub new ($)
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    my $basename = shift;
    
    # Initialize some variables
    
    $self->{STATE} = '';
    $self->{LAST_SECTION} = '';
    $self->{LAST_DESCRIPTION} = '';
    
    # Initialize the hash table of handlers for each section
    
    %{$self->{HANDLERS}} = 
        ( 
            'begin'   => \&Normal_Handler,
            'setup'   => \&Setup_Handler,
            'config'  => \&Normal_Handler,
            'compile' => \&Compile_Handler,
            'test'    => \&Test_Handler,
            'end'     => \&Normal_Handler
        );    

    # Initialize the list of output classes
    
    @{$self->{OUTPUT}} = 
        ( 
            new Prettify::Full_HTML ($basename),
            new Prettify::Brief_HTML ($basename),
        );
    
    # Output the header for the files

    foreach my $output (@{$self->{OUTPUT}}) {
        $output->Header ();
    }
    
    bless ($self, $class);
    return $self;
}

sub DESTROY 
{
    my $self = shift;
    
    # Output the footer for the files
    
    foreach my $output (@{$self->{OUTPUT}}) {
        $output->Footer ();
    }
}

sub Process_Line ($)
{
    my $self = shift;
    my $s = shift;

    if ($s =~ m/^#################### (.*)$/) {
        my $section = $1;
        my $description;
        my $timestamp = "";

        if ($section =~ m/(.*) \[(.*)\]/) {
            $section = $1;
            $timestamp = $2;
        }
        if ($section =~ m/(.*) \((.*)\)/) {
            $section = $1;
            $description = $2;
        }
        
        $self->{LAST_DESCRIPTION} = $description;
        
        if ($self->{LAST_SECTION} eq $section) {
            foreach my $output (@{$self->{OUTPUT}}) {
                $output->Description ($description);
                $output->Timestamp ($timestamp);
            }
            
            return;
        }
        else {
            foreach my $output (@{$self->{OUTPUT}}) {
                $output->Section ($section);
                $output->Description ($description) if defined ($description);
                $output->Timestamp ($timestamp);
            }
        }

        $self->{LAST_SECTION} = $section;

        $self->{STATE} = 'unknown';
        $self->{STATE} = 'begin'   if (lc $section eq 'begin');
        $self->{STATE} = 'setup'   if (lc $section eq 'setup');
        $self->{STATE} = 'config'  if (lc $section eq 'config');
        $self->{STATE} = 'compile' if (lc $section eq 'compile');
        $self->{STATE} = 'test'    if (lc $section eq 'test');
        $self->{STATE} = 'end'     if (lc $section eq 'end');
        
        return;
    }
    
    if (defined $self->{HANDLERS}->{$self->{STATE}}) {
        $self->{HANDLERS}->{$self->{STATE}} ($self, $s);
    }
    
}

sub Output_Subsection ($)
{
    my $self = shift;
    my $s = shift;
    
    foreach my $output (@{$self->{OUTPUT}}) {
        $output->Subsection ($s);
    }
}

sub Output_Error ($)
{
    my $self = shift;
    my $s = shift;
    
    foreach my $output (@{$self->{OUTPUT}}) {
        $output->Error ($s);
    }
}

sub Output_Warning ($)
{
    my $self = shift;
    my $s = shift;
    
    foreach my $output (@{$self->{OUTPUT}}) {
        $output->Warning ($s);
    }
}

sub Output_Normal ($)
{
    my $self = shift;
    my $s = shift;
    
    foreach my $output (@{$self->{OUTPUT}}) {
        $output->Normal ($s);
    }
}

sub Normal_Handler ($)
{
    my $self = shift;
    my $s = shift;
    
    $self->Output_Normal ($s);
}

sub Setup_Handler ($)
{
    my $self = shift;
    my $s = shift;

    if ($s =~ m/aborted/i || 
        $s =~ m/cannot access/i || 
        $s =~ m/no such file/i) 
    {
        $self->Output_Error ($s);
    }
    elsif ($s =~ /^C /) {
        $self->Output_Error ($s);
    }
    elsif  ($s =~ /^M /) {
        $self->Output_Warning ($s);
    }
    else {
        $self->Output_Normal ($s);
    }
}

sub Compile_Handler ($)
{
    my $self = shift;
    my $s = shift;

    # Check for the subsection indicator

    if ($s =~ m/^Auto_compiling (.*)/ || $s =~ /Entering directory (.*)/) {
        $self->Output_Subsection ($1);
        return;
    }

    # Check out the line to figure out whether it is an error or not

    if ($s =~ m/^ld: \d+\-\d+ WARNING: Duplicate symbol:/) {
        # AIX reports a bazillion multiple defines when doing templates; some
        # have the word 'error' in the symbol name - ignore those.
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/is dangerous, better use/) {
        # Linux has this annoying mktemp, mkstemp stuff. Ignore that
        # for the timebeing
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/^.*:[0-9]+: / && $s !~ m/^.*:[0-9]+: warning:/) {
        # Definately an error
        $self->Output_Error ($s);
    }
    elsif ($s =~ m/^ld: \d+\-\d+/) {
        # AIX linking errors from ld
        if ($s =~ m/^ld: 0711\-345/) {
            # But don't report the extra "check the map" message
            $self->Output_Normal ($s);
        }
        else {
            $self->Output_Error ($s);
        }
    }
    elsif ($s =~ m/undefined reference to/
           || $s =~ m/: cannot open/
           || $s =~ m/: multiple definition of/
           || $s =~ m/path name does not exist/)
    {
        # Look for linking errors too
        $self->Output_Error ($s);
    }
    elsif (($s =~ m/error/i 
            && $s !~ m/ error\(s\), / 
            && $s !~ m/error \(future\)/i)
           || $s =~ m/^Fatal\:/
           || $s =~ m/: fatal:/)
    {
        # Look for possible errors
        $self->Output_Error ($s);
    }
    elsif ($s =~ m/.*\d+\-\d+:? \([SI]\)/) {
        # Again, IBM's compilers speak in code langauge
        if ($s =~ /.*Compilation will proceed shortly./) {
            # Ignore licensing messages
            $self->Output_Normal ($s);
        }
        else {
            $self->Output_Error ($s);
        }    
    }
    elsif ($s =~ m/^LINK : warning LNK4089:/) {
        # Ignore this warning from MSVC
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/^ld: \d+\-\d+ WARNING: Duplicate symbol:/) {
        # AIX reports a bazillion multiple defines when doing templates.
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/vnocompatwarnings/) {
        # HP-UX uses 'nocompatwarnings' as an option to the compiler.
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/in call to __pthread_cleanup_push\(extern/) {
        # SUN CC 5.0 defines __pthread_cleanup_push as a macro which causes
        # warnings. See /usr/include/pthread.h and
        # $ACE_ROOT/examples/Timer_Queue/Thread_Timer_Queue_Test.cpp for more
        # information.
        $self->Output_Normal ($s);
    }
    elsif (($s =~ m/warning/i 
            && $s !~ m/ warning\(s\)/)
           || $s =~ m/info: /i
           || $s =~ m/^make.*\*\*\*/
           || $s =~ m/^error \(future\)/i
           || $s =~ m/^.*\.(h|i|inl|cpp|java): /) 
    {
        # Catch any other warnings
        $self->Output_Warning ($s);
    }
    elsif ($s =~ m/^.*\d+\-\d+:? \(W\)/) {
        # IBM's compilers don't say the word "warning" - check for their code
        $self->Output_Warning ($s);
    }
    else {
        # Must be normal
        $self->Output_Normal ($s);
    }
}

sub Test_Handler ($)
{
    my $self = shift;
    my $s = shift;

    # Check for the subsection indicator
    
    if ($s =~ m/auto_run_tests: (.*)/) {
        $self->Output_Subsection ($1);
        return;
    }

    if ($s =~ m/Error/
        || $s =~ m/ERROR/
        || $s =~ m/FAILED/
        || $s =~ m/EXCEPTION/
        || $s =~ m/pure virtual /i)
    {
        $self->Output_Error ($s);
    }
    else {
        $self->Output_Normal ($s);
    }
}

###############################################################################
# Exposed subroutines

sub Process ($)
{
    my $filename = shift;
    my $basename = $filename;
    $basename =~ s/\.txt$//;
    
    my $processor = new Prettify ($basename);
    
    my $input = new FileHandle ($filename, 'r');
    
    while (<$input>) {
        chomp;
        $processor->Process_Line ($_);
    }    
}

sub WriteLatest($)
{
    my $latest = shift;
    my $filename = basename ($latest, '.txt') . '.txt';
    my $directory = dirname ($latest);
    
    my $output = new FileHandle ($directory . '/latest.txt', 'w');
    
    print $output "Latest logfile = $filename\n";
}



1;
