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

    @{ $self->{ERROR_TEXT} }= ();
    @{ $self->{BUILD_ERROR_COUNTER} }= ();

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
    push( @{$self->{ERROR_TEXT}}, $s );

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

    # In the case where there was no errors or warnings, output a note
    if ($self->{ERROR_COUNTER} == 0 && $self->{WARNING_COUNTER} == 0) {
        print {$self->{FH}} "No Errors or Warnings detected<br>\n";
    }

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

package Prettify::Totals_HTML;

use strict;
use warnings;
use integer;

use FileHandle;

###############################################################################

sub new ($)
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    my $basename = shift;
    my $filename = $basename . '_Totals.html';

    if ($basename =~ s/^(.*)\///) {
        $self->{LATEST_FILENAME} = $1 . '/latest.txt';
    }
    else {
        $self->{LATEST_FILENAME} = 'latest.txt';
    }

    $self->{BASENAME} = $basename;
    $self->{FULLHTML} = $basename . "_Full.html";
    $self->{BRIEFHTML} = $basename . "_Brief.html";
    $self->{ERROR_COUNTER} = 0;
    $self->{WARNING_COUNTER} = 0;
    $self->{SECTION_COUNTER} = 0;
    $self->{SUBSECTION_COUNTER} = 0;
    $self->{FH} = new FileHandle ($filename, 'w');
    $self->{LAST_SECTION} = "";

    $self->{SECTION_SUBSECTIONS} = 0;
    $self->{SECTION_ERRORS} = 0;
    $self->{SECTION_WARNINGS} = 0;
    $self->{SECTION_ERROR_SUBSECTIONS} = 0;
    $self->{SECTION_WARNING_SUBSECTIONS} = 0;

    $self->{SUBSECTION_ERROR_FOUND} = 0;
    $self->{SUBSECTION_WARNING_FOUND} = 0;

    $self->{SETUP_ERRORS} = 0;
    $self->{SETUP_WARNINGS} = 0;
    $self->{COMPILE_ERRORS} = 0;
    $self->{COMPILE_WARNINGS} = 0;
    $self->{TEST_ERRORS} = 0;
    $self->{TEST_WARNINGS} = 0;

    bless ($self, $class);
    return $self;
}

sub Header ()
{
    my $self = shift;
    print {$self->{FH}} "<html>\n";
    print {$self->{FH}} "<head>\n<title>Daily Build Log (Totals)</title>\n</head>\n";
    print {$self->{FH}} "<body bgcolor=\"white\">\n";
    print {$self->{FH}} "<h1>Daily Build Log (Totals)</h1>\n";
    print {$self->{FH}} "<hr>\n";
    print {$self->{FH}} "[<a href=\"$self->{BRIEFHTML}\">Brief Log</a>] ";
    print {$self->{FH}} "[<a href=\"$self->{FULLHTML}\">Full Log</a>] \n";
    print {$self->{FH}} "<hr>\n";
    print {$self->{FH}} "<table border=\"1\">\n";
    print {$self->{FH}} "  <tr>\n";
    print {$self->{FH}} "    <th>Section</th>\n";
    print {$self->{FH}} "    <th>Links</th>\n";
    print {$self->{FH}} "    <th>Total Subsections</th>\n";
    print {$self->{FH}} "    <th>Total Errors</th>\n";
    print {$self->{FH}} "    <th>Total Warnings</th>\n";
    print {$self->{FH}} "    <th>Subsections with Errors</th>\n";
    print {$self->{FH}} "    <th>Subsections with Warnings</th>\n";
    print {$self->{FH}} "  </tr>\n";
}

sub Section_Totals ()
{
    my $self = shift;

    # Bail out if there is no totals
    if ($self->{SECTION_COUNTER} == 0) {
        return;
    }

    my $percentage;
    my $color;
    my $counter = $self->{SECTION_COUNTER};

    print {$self->{FH}} "  <tr>\n";
    print {$self->{FH}} "    <td>$self->{LAST_SECTION}</td>";

    if($self->{LAST_SECTION} eq "Config") {
      print {$self->{FH}} "    <td>[<a href=\"$self->{BASENAME}_Config.html\">Full</a>] ";
    }
    else {
      print {$self->{FH}} "    <td>[<a href=\"$self->{FULLHTML}#section_$counter\">Full</a>] ";
    }

    if ($self->{SECTION_ERRORS} > 0 || $self->{SECTION_WARNINGS} > 0) {
        print {$self->{FH}} "[<a href=\"$self->{BRIEFHTML}#section_$counter\">Brief</a>] ";
    }
    print {$self->{FH}} "</td>\n";

    print {$self->{FH}} "    <td>$self->{SECTION_SUBSECTIONS}</td>";

    $color = 'white';
    $color = 'red' if ($self->{SECTION_ERRORS} > 0);

    print {$self->{FH}} "    <td bgcolor=\"$color\">$self->{SECTION_ERRORS}</td>";

    $color = 'white';
    $color = 'orange' if ($self->{SECTION_WARNINGS} > 0);

    print {$self->{FH}} "    <td bgcolor=\"$color\">$self->{SECTION_WARNINGS}</td>";

    $percentage = "--";
    if ($self->{SECTION_SUBSECTIONS} > 0) {
        $percentage = $self->{SECTION_ERROR_SUBSECTIONS} * 100 / $self->{SECTION_SUBSECTIONS};
    }

    $color = 'white';
    $color = 'red' if ($self->{SECTION_ERROR_SUBSECTIONS} > 0);

    print {$self->{FH}} "    <td bgcolor=\"$color\">$self->{SECTION_ERROR_SUBSECTIONS} ($percentage%)</td>";

    $percentage = "--";
    if ($self->{SECTION_SUBSECTIONS} > 0) {
        $percentage = $self->{SECTION_WARNING_SUBSECTIONS} * 100 / $self->{SECTION_SUBSECTIONS};
    }

    $color = 'white';
    $color = 'orange' if ($self->{SECTION_WARNING_SUBSECTIONS} > 0);

    print {$self->{FH}} "    <td bgcolor=\"$color\">$self->{SECTION_WARNING_SUBSECTIONS} ($percentage%)</td>";
    print {$self->{FH}} "\n  </tr>\n";

    if ($self->{LAST_SECTION} eq 'Config') {
        $self->{CONFIG_SECTION} = $self->{SECTION_COUNTER};
    }

    if ($self->{LAST_SECTION} eq 'Setup') {
        $self->{SETUP_SECTION} = $self->{SECTION_COUNTER} if (!defined $self->{SETUP_SECTION});
        $self->{SETUP_ERRORS} += $self->{SECTION_ERRORS};
        $self->{SETUP_WARNINGS} += $self->{SECTION_WARNINGS};
    }

    if ($self->{LAST_SECTION} eq 'Compile') {
        $self->{COMPILE_SECTION} = $self->{SECTION_COUNTER} if (!defined $self->{COMPILE_SECTION});
        $self->{COMPILE_ERRORS} += $self->{SECTION_ERRORS};
        $self->{COMPILE_WARNINGS} += $self->{SECTION_WARNINGS};
    }

    if ($self->{LAST_SECTION} eq 'Test') {
        $self->{TEST_SECTION} = $self->{SECTION_COUNTER} if (!defined $self->{TEST_SECTION});
        $self->{TEST_ERRORS} += $self->{SECTION_ERRORS};
        $self->{TEST_WARNINGS} += $self->{SECTION_WARNINGS};
    }

    $self->{SECTION_SUBSECTIONS} = 0;
    $self->{SECTION_ERRORS} = 0;
    $self->{SECTION_WARNINGS} = 0;
    $self->{SECTION_WARNING_SUBSECTIONS} = 0;
}

sub Footer ()
{
    my $self = shift;

    $self->Section_Totals ();

    print {$self->{FH}} "</table>\n";

    my $totals = '';

    if (defined $self->{CONFIG_SECTION}) {
        $totals .= " Config: $self->{CONFIG_SECTION}";
    }

    if (defined $self->{SETUP_SECTION}) {
        $totals .= " Setup: $self->{SETUP_SECTION}-$self->{SETUP_ERRORS}-$self->{SETUP_WARNINGS}";
    }


    if (defined $self->{COMPILE_SECTION}) {
        $totals .= " Compile: $self->{COMPILE_SECTION}-$self->{COMPILE_ERRORS}-$self->{COMPILE_WARNINGS}";
    }

    if (defined $self->{TEST_SECTION}) {
        $totals .= " Test: $self->{TEST_SECTION}-$self->{TEST_ERRORS}-$self->{TEST_WARNINGS}";
    }

    $totals .= " Failures: $self->{SECTION_ERROR_SUBSECTIONS}";

    $totals .= "\n";

    print {$self->{FH}} "<!-- BUILD_TOTALS: $totals -->\n";

    print {$self->{FH}} "</body>\n";
    print {$self->{FH}} "</html>\n";

    my $fh = new FileHandle ($self->{LATEST_FILENAME}, 'w');

    if (!defined $fh) {
        print STDERR __FILE__, ": Could not create file: $self->{LATEST_FILENAME}: $!\n";
        return;
    }

    print $fh $self->{BASENAME}, $totals;
}

sub Section ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    $self->Section_Totals ();

    ++$self->{SECTION_COUNTER};

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

    ++$self->{SUBSECTION_COUNTER};
    ++$self->{SECTION_SUBSECTIONS};

    $self->{SUBSECTION_ERROR_FOUND} = 0;
    $self->{SUBSECTION_WARNING_FOUND} = 0;
}

sub Error ($)
{
    my $self = shift;
    my $s = shift;

    ++$self->{ERROR_COUNTER};
    ++$self->{SECTION_ERRORS};

    if ($self->{SUBSECTION_ERROR_FOUND} == 0) {
        ++$self->{SECTION_ERROR_SUBSECTIONS};
        $self->{SUBSECTION_ERROR_FOUND} = 1;
    }
}

sub Warning ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    ++$self->{WARNING_COUNTER};
    ++$self->{SECTION_WARNINGS};

    if ($self->{SUBSECTION_WARNING_FOUND} == 0) {
        ++$self->{SECTION_WARNING_SUBSECTIONS};
        $self->{SUBSECTION_WARNING_FOUND} = 1;
    }

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
use FindBin;
use common::parse_compiler_output;
use base qw(common::parse_compiler_output);

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
            'begin'     => \&Normal_Handler,
            'setup'     => \&Setup_Handler,
            'config'    => \&Config_Handler,
            'configure' => \&Autoconf_Handler,
            'compile'   => \&Compile_Handler,
            'test'      => \&Test_Handler,
            'end'       => \&Normal_Handler
        );

    # Initialize the list of output classes

    @{$self->{OUTPUT}} =
        (
            new Prettify::Full_HTML ($basename),
            new Prettify::Brief_HTML ($basename),
            new Prettify::Totals_HTML ($basename),
            new Prettify::Config_HTML ($basename),
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
                $output->Description ($description, $section);
                $output->Timestamp ($timestamp);
            }

            return;
        }
        else {
            foreach my $output (@{$self->{OUTPUT}}) {
                $output->Section ($section);
                $output->Description ($description, $section) if defined ($description);
                $output->Timestamp ($timestamp);
            }
        }

        $self->{LAST_SECTION} = $section;

        $self->{STATE} = 'unknown';
        $self->{STATE} = 'begin'     if (lc $section eq 'begin');
        $self->{STATE} = 'setup'     if (lc $section eq 'setup');
        $self->{STATE} = 'config'    if (lc $section eq 'config');
        $self->{STATE} = 'configure' if (lc $section eq 'configure');
        $self->{STATE} = 'compile'   if (lc $section eq 'compile');
        $self->{STATE} = 'test'      if (lc $section eq 'test');
        $self->{STATE} = 'end'       if (lc $section eq 'end');

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
        $s =~ m/nothing known about/ ||
        $s =~ m/^ERROR/ ||
        $s =~ m/[^\w]+ERROR/ ||
        $s =~ m/no such file/i)
    {
        $self->Output_Error ($s);
    }
    elsif ($s =~ /^C /) {
        $self->Output_Error ($s);
    }
    elsif ($s =~ /^M / ||
           $s =~ m/WARNING/)
    {
        $self->Output_Warning ($s);
    }
    else {
        $self->Output_Normal ($s);
    }
}

sub Detected_Build_Error($) {
  my $self = shift;
  my $e = shift;

  push( @{$self->{OUTPUT}[0]->{BUILD_ERROR_COUNTER}}, $e );
}

sub Compile_Handler ($)
{
    my $self = shift;
    my $s = shift;

    $self->handle_compiler_output_line($s);
}

sub Config_Handler ($)
{
    my $self = shift;
    my $s = shift;
    my @outputs = @{$self->{OUTPUT}};
    my $state = $self->{STATE};

    # We only want to output config stuff to the Config_HTML class
    $outputs[3]->Normal($s, $state);
}

sub Autoconf_Handler ($)
{
    my $self = shift;
    my $s = shift;

    # For now, everything goes to the normal output. If we figure out
    # something that should be an error or warning, then add processing
    # like is done in the compile section.
    $self->Output_Normal ($s);
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
	|| $s =~ m/fatal/
        || $s =~ m/FAIL:/
        || $s =~ m/FAILED/
        || ($s =~ m/EXCEPTION/ && $s !~ m/NO_EXCEPTIONS/)
	|| $s =~ m/ACE_ASSERT/
	|| $s =~ m/Assertion/
        || $s =~ m/Mismatched free/
        || $s =~ m/are definitely lost in loss record/
        || $s =~ m/: parse error/
        || $s =~ m/Invalid write of size/
        || $s =~ m/Invalid read of size/
        || $s =~ m/pure virtual /i)
    {
        $self->Output_Error ($s);
    }
    else {
        $self->Output_Normal ($s);
    }
}

sub BuildErrors ($)
{
     my $self = shift;
     return @{$self->{OUTPUT}[0]->{BUILD_ERROR_COUNTER}};
}

###############################################################################
# Exposed subroutines
#
# In this function we process the log file line by line,
# looking for errors.

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

    # When we finish processing each line of the log file,
    # if we detect any BUILD ERROR messages, send an e-mail
    # notification if MAIL_ADMIN was specified in the XML config
    # file.

    my @errors = $processor->BuildErrors();
    my $mail_admin = main::GetVariable ( 'MAIL_ADMIN' );
    if ( (scalar( @errors ) > 0) && (defined $mail_admin) )
    {
        $processor->SendEmailNotification();
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

sub SendEmailNotification($)
{
    my $self = shift;

    my $mail_admin = main::GetVariable ( 'MAIL_ADMIN' );
    my $scoreboard_url = main::GetVariable('SCOREBOARD_URL');
    my @errors = $self->BuildErrors();
    my @error_text = @{$self->{OUTPUT}[0]->{ERROR_TEXT}};

    # @error_text can be pretty huge.  Cut it down to 100 lines.
    if ($#error_text > 100 ) {
        splice (@error_text, 100, $#error_text);
    }

    ## Combine the array of errors into one string which we can put in an e-mail
    my $errors_string = join("\n", @errors );
    $errors_string .= "\n\nDisplaying first 100 lines from error log: \n";
    $errors_string .=
    "\n================================================================\n\n";

    $errors_string .= join("\n", @error_text);
    $errors_string .=
    "\n================================================================\n\n";

    my $root = main::GetVariable( 'root' );
    if ( -r $root."/ACE_wrappers/ChangeLog")
    {
       $errors_string .= "ACE changes in last 24 hours:\n\n";
       chdir("$root/ACE_wrappers");
       $errors_string .= `cvs diff -D \"24 hours ago\" ChangeLog`;
       $errors_string .= "\n\n";
       chdir("$root");
    }

    if ( -r $root."/ACE_wrappers/TAO/ChangeLog")
    {
       $errors_string .=
       "================================================================\n\n";
       $errors_string .= "TAO changes in last 24 hours:\n\n";
       chdir("$root/ACE_wrappers/TAO");
       $errors_string .= `cvs diff -D \"24 hours ago\" ChangeLog`;
       $errors_string .= "\n\n";
       chdir("$root");

    }

    if ( ! defined $scoreboard_url ) {
       $scoreboard_url = "";
    }

    Mail::send_message($mail_admin,
                       "[AUTOBUILD] ".main::GetVariable('BUILD_CONFIG_FILE')." has build errors" ,
                       "Errors detected while executing the build specified in ".main::GetVariable('BUILD_CONFIG_FILE').".\n".
                       "Please check the scoreboard for details.\n$scoreboard_url\n\n".
                        $errors_string
                      );

}

###############################################################################

package Prettify::Config_HTML;

use strict;
use warnings;

use FileHandle;

sub new ($)
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    my $basename = shift;
    my $filename = $basename . "_Config.html";

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
    print {$self->{FH}} "<head>\n<title>Daily Build Configuration</title>\n</head>\n";
    print {$self->{FH}} "<body bgcolor=\"white\">\n";
    print {$self->{FH}} "<h1>Daily Build Configuration</h1>\n";
    print {$self->{FH}} "<pre>\n";
}

sub Footer ()
{
    my $self = shift;
    print {$self->{FH}} "</pre>\n";
    print {$self->{FH}} "</body>\n";
    print {$self->{FH}} "</html>\n";
}

sub Normal ($)
{
    my $self = shift;
    my $s = shift;
    my $state = shift;
    $state = lc $state;

    if( defined $state && $state eq 'config' ) {
      print {$self->{FH}} "$s\n";
    }
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

sub Timestamp ($)
{
    my $self = shift;
    # Ignore
}

sub Subsection ($)
{
   my $self = shift;
   # Ignore
}

sub Description ($)
{
    my $self = shift;
    my $s = shift;
    my $state = shift;
    $state = lc $state;

    # Escape any '<' or '>' signs
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    if(defined $state && $state eq "config") {
      print {$self->{FH}} "<h3>$s</h3>\n";
    }
}

sub Error ($)
{
   my $self = shift;
   # Ignore
}

sub Warning ($)
{
   my $self = shift;
   # Ignore
}


1;
