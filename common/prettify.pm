#

###############################################################################
###############################################################################

package Prettify::Full_HTML;

use strict;
use warnings;

use FileHandle;
use Cwd;
our $path = "";

###############################################################################

sub new ($)
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    my $basename = shift;
    my $filename = $basename . "_Full.html";
    my $log_root = main::GetVariable('log_root');
    $path = ((defined $log_root) ? ($log_root . '/' . $filename) : $filename);
    $self->{ERROR_COUNTER} = 0;
    $self->{WARNING_COUNTER} = 0;
    $self->{SECTION_COUNTER} = 0;
    $self->{SUBSECTION_COUNTER} = 0;

    $self->{FH} = new FileHandle ($filename, 'w');
    unless ($self->{FH}) {
        print STDERR __FILE__, ": ERROR: Could not create file $filename $!\n";
        return undef;
    }

    $self->{FILENAME} = $filename;
    $self->{BUFFER_NON_ERRORS} = 0;

    @{ $self->{BUFFERED_NON_ERRORS} } = ();
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

    @{ $self->{BUFFERED_NON_ERRORS} } = ();
    if (defined $ENV{"VALGRIND_ERRORS_ONLY"})
    {
       $self->{BUFFER_NON_ERRORS} = 1;
    }
}

sub Description ($)
{
    my $self = shift;
    my $s = shift || '';

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

    @{ $self->{BUFFERED_NON_ERRORS} } = ();
    if (defined $ENV{"VALGRIND_ERRORS_ONLY"})
    {
       $self->{BUFFER_NON_ERRORS} = 1;
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
    push( @{$self->{ERROR_TEXT}}, $s );

    if ($self->{BUFFER_NON_ERRORS})
    {
       foreach my $output (@{$self->{BUFFERED_NON_ERRORS}}) {
           print {$self->{FH}} $output;
       }
       $self->{BUFFER_NON_ERRORS} = 0;
       @{ $self->{BUFFERED_NON_ERRORS} } = ();
    }

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

    if ($self->{BUFFER_NON_ERRORS})
    {
        push( @{$self->{BUFFERED_NON_ERRORS}}, "<a name=\"warning_$counter\"></a>\n" );
        push( @{$self->{BUFFERED_NON_ERRORS}}, "<font color=\"FF7700\"><tt>$s</tt></font><br>\n" );
    }
    else
    {
        print {$self->{FH}} "<a name=\"warning_$counter\"></a>\n";
        print {$self->{FH}} "<font color=\"FF7700\"><tt>$s</tt></font><br>\n";
    }
}

sub Normal ($)
{
    my $self = shift;
    my $s = shift;

    # Escape any '<' or '>' signs that are not html heading and referances
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/&lt;\s*(\/?\s*h\d|\/a|a\s*href\s*=\s*\s*"[^"]*")\s*&gt;/<$1>/g;

    if ($self->{BUFFER_NON_ERRORS})
    {
        push( @{$self->{BUFFERED_NON_ERRORS}}, "<tt>$s</tt><br>\n" );
    }
    else
    {
        print {$self->{FH}} "<tt>$s</tt><br>\n";
    }
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
    unless ($self->{FH}) {
        print STDERR __FILE__, ": ERROR: Could not create file $filename $!\n";
        return undef;
    }

    $self->{FILENAME} = $filename;

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
    my $s = shift;

    if ($Prettify::tsan_report ||
        $Prettify::asan_report ||
        $Prettify::leak_report ||
        $Prettify::stack_trace_report)
    {
        # Escape any '<' or '>' signs
        $s =~ s/</&lt;/g;
        $s =~ s/>/&gt;/g;

        print {$self->{FH}} "<tt>$s</tt><br>\n";
    }
}

###############################################################################
###############################################################################

package Prettify::Failed_Tests_HTML;

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
    my $buildname = shift;
    my $failed_tests = shift;
    my $rev_link = shift;
    my $log_prefix = shift;

    my $filename = $log_prefix . "_Failed_Tests_By_Build.html";

    $basename =~ s/^.*\///;

    $self->{FULLHTML} = "$buildname/$basename" . "_Full.html";
    $self->{ERROR_COUNTER} = 0;
    $self->{WARNING_COUNTER} = 0;
    $self->{SECTION_COUNTER} = 0;
    $self->{SUBSECTION_COUNTER} = 0;
    $self->{TITLE} = "Failed Test Brief Log By Build";
    $self->{GIT_CHECKEDOUT_OPENDDS} = "unknown";
    $self->{FAILED_TESTS} = $failed_tests;
    $self->{REV_LINK} = $rev_link;

    unless (-e $filename) {
        my $file_handle = new FileHandle ($filename, 'w');
        unless ($file_handle) {
            print STDERR __FILE__, ": ERROR: Could not create file $filename $!\n";
            return undef;
        }
        print {$file_handle} "<h1>$self->{TITLE}</h1>\n";
    }

    $self->{FH} = new FileHandle ($filename, '>>');
    unless ($self->{FH}) {
        print STDERR __FILE__, ": ERROR: Could not append to file $filename $!\n";
        return undef;
    }

    $self->{FILENAME} = $filename;
    $self->{BUILDNAME} = $buildname;
    $self->{USE_BUILDNAME} = '';
    $self->{CURRENT_SUBSECTION} = '';

    bless ($self, $class);
    return $self;
}

sub Header ()
{
    my $self = shift;
    if (defined $self->{LAST_SECTION} && $self->{LAST_SECTION} eq 'Test') {
        print {$self->{FH}} "<html>\n";
        print {$self->{FH}} "<body bgcolor=\"white\">\n";
    }
}

sub Footer ()
{
    my $self = shift;

    if (defined $self->{LAST_SECTION} && $self->{LAST_SECTION} eq 'Test') {
        # In the case where there was no errors or warnings, output a note
        if ($self->{ERROR_COUNTER} == 0 && $self->{WARNING_COUNTER} == 0) {
            print {$self->{FH}} "No Errors or Warnings detected<br>\n";
        }

        print {$self->{FH}} "</body>\n";
        print {$self->{FH}} "</html>\n";
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
    my $rev = substr($self->{GIT_CHECKEDOUT_OPENDDS}, 0, 8);
    my $rev_line = "";
    if ($rev ne "unknown") {
        $rev_line = "Rev: ";
        if (length($self->{REV_LINK})) {
            $rev_line .= "<a href=$self->{REV_LINK}";
            $rev_line =~ s/\/$//g;
            $rev_line .= "/$rev>";
        }
        $rev_line .= $rev;
        if (length($self->{REV_LINK})) {
            $rev_line .= "</a>";
        }
    }

    if (defined $self->{LAST_SECTION} && defined $self->{LAST_SUBSECTION} && $self->{LAST_SECTION} eq 'Test') {
        if (defined $self->{USE_BUILDNAME}) {
            print {$self->{FH}} "<hr><h2>$self->{BUILDNAME}</h2>";
            if ($rev ne "unknown") {
                print {$self->{FH}} "$rev_line\n";
            }
            $self->{USE_BUILDNAME} = undef;
        }

        if (defined $self->{FAILED_TESTS}->{$self->{LAST_SUBSECTION}}) {
            $self->{FAILED_TESTS}->{$self->{LAST_SUBSECTION}} = $self->{FAILED_TESTS}->{$self->{LAST_SUBSECTION}} . "<h3>$self->{BUILDNAME}</h3>\n$rev_line<br><br>";
        }
        else {
            $self->{FAILED_TESTS}->{$self->{LAST_SUBSECTION}} = "<h3>$self->{BUILDNAME}</h3>\n$rev_line<br><br>";
        }

        print {$self->{FH}} "<a name=\"subsection_$self->{SUBSECTION_COUNTER}\"></a>";
        print {$self->{FH}} "<h3>$self->{LAST_SUBSECTION}</h3>";

        $self->{CURRENT_SUBSECTION} = $self->{LAST_SUBSECTION};

        $self->{LAST_SUBSECTION} = undef;
    }
}

sub Error ($)
{
    my $self = shift;
    my $s = shift;

    if (defined $self->{LAST_SECTION} && $self->{LAST_SECTION} eq 'Test') {
        # Escape any '<' or '>' signs
        $s =~ s/</&lt;/g;
        $s =~ s/>/&gt;/g;

        my $counter = ++$self->{ERROR_COUNTER};

        $self->Print_Sections ();

        my $Err1 = "<a name=\"error_$counter\"></a>\n";
        my $Err2 = "<tt>[<a href=\"$self->{FULLHTML}#error_$counter" . "\">Details</a>] </tt>";
        my $Err3 = "<font color=\"FF0000\"><tt>$s</tt></font><br>\n";

        print {$self->{FH}} $Err1;
        print {$self->{FH}} $Err2;
        print {$self->{FH}} $Err3;

        $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} = $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} . $Err1;
        $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} = $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} . $Err2;
        $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} = $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} . $Err3;
    }
}

sub Warning ($)
{
    my $self = shift;
    my $s = shift;

    if (defined $self->{LAST_SECTION} && $self->{LAST_SECTION} eq 'Test') {
        # Escape any '<' or '>' signs
        $s =~ s/</&lt;/g;
        $s =~ s/>/&gt;/g;

        my $counter = ++$self->{WARNING_COUNTER};

        $self->Print_Sections ();

        my $Warning1 = "<a name=\"warning_$counter\"></a>\n";
        my $Warning2 = "<tt>[<a href=\"$self->{FULLHTML}#warning_$counter\">Details</a>] </tt>";
        my $Warning3 = "<font color=\"FF7700\"><tt>$s</tt></font><br>\n";

        print {$self->{FH}} $Warning1;
        print {$self->{FH}} $Warning2;
        print {$self->{FH}} $Warning3;

        $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} = $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} . $Warning1;
        $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} = $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} . $Warning2;
        $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} = $self->{FAILED_TESTS}->{$self->{CURRENT_SUBSECTION}} . $Warning3;
    }
}

sub Normal ($)
{
    my $self = shift;

    # Ignore
}

###############################################################################
###############################################################################

package Prettify::JUnit;

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
    my $filename = $basename . '_JUnit.xml';
    $self->{FH} = new FileHandle ($filename, 'w');
    unless ($self->{FH}) {
        print STDERR __FILE__, ": ERROR: Could not create file $filename $!\n";
        return undef;
    }

    $self->{FILENAME} = $filename;
    $self->{CURRENT_SECTION} = '';
    $self->{FAILED} = 0;
    $self->{TESTS} = [];

    bless ($self, $class);
    return $self;
}

sub Header ()
{
    my $self = shift;
    my $out = $self->{FH};
    print $out '<?xml version="1.0" encoding="UTF-8"?>', "\n",
      '<testsuites xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"', "\n",
      '            xsi:noNamespaceSchemaLocation="JUnit.xsd">', "\n";
}

sub Footer ()
{
    my $self = shift;
    my $out = $self->{FH};
    my $indent = '  ';
    print $out $indent, "<testsuite name=\"Autobuild_Tests\" ";
    if (defined $self->{TIMESTAMP} and length $self->{TIMESTAMP})
    {
        print $out "timestamp=\"$self->{TIMESTAMP}\" ";
    }

    my $numtests = @{$self->{TESTS}};
    if ($numtests > 0) {
        print $out "tests=\"$numtests\" failures=\"$self->{FAILED}\" hostname=\"$Prettify::Config_HTML::host\">\n";
    }
    else { # Insert a dummy testcase so jenkins doesn't think there is a failure.
        print $out 'tests="1">', "\n", $indent x 2, '<testcase name="dummy_test"/>', "\n";
    }

    print $out $indent x 2, "<properties>\n";
    foreach my $k (keys %Prettify::commits) {
        print $out $indent x 3, "<property name=\"$k\" value=\"$Prettify::commits{$k}\"/>\n";
    }
    print $out $indent x 3, "<property name=\"log_file\" value=\"$Prettify::Full_HTML::path\"/>\n";
    print $out $indent x 2, "</properties>\n";

    foreach my $test (@{$self->{TESTS}}) {
        my $error = $test->{ERROR} || '';
        print $out $indent x 2,
            "<testcase name=\"$test->{NAME}\" status=\"$test->{RESULT}\" ",
            "time=\"$test->{TIME}\"", ($error eq "" ? "/>\n" : '>');

        if ($error ne "") {
          print $out "<failure>\n",
              $indent x 3, "<![CDATA[$error]]></failure><system-out>\n",
              $indent x 3, "<![CDATA[$test->{OUT}]]></system-out></testcase>\n";

          my $github_actions = main::GetVariable ('GITHUB_ACTIONS');
          if (defined $ENV{"GITHUB_ACTIONS"} && (!defined $github_actions || $github_actions ne "0")) {
            my $test_file = (split / /, $test->{NAME})[0];
            my $error_str = $error;
            $error_str =~ s/([%\r\n])/ sprintf "%%%02X", ord $1 /eg;
            print "::error title=$test->{NAME},file=$test_file,line=0,col=0::$error_str\n";
          }
        }
    }

    print $out $indent, "</testsuite>\n</testsuites>\n";
}

sub Section ($)
{
    my $self = shift;
    my $s = shift;
    $self->{CURRENT_SECTION} = $s;
}

sub Description ($)
{
}

sub Timestamp ($)
{
    my $self = shift;
    my $ts = shift;

    eval {
        require Time::Piece;

        # Grab the first valid timestamp from a test section and use that for our test suite

        if (!(defined $self->{CURRENT_SECTION} and length $self->{CURRENT_SECTION} and $self->{CURRENT_SECTION} =~ /test/i))
        {
            return;
        }

        if (defined $self->{TIMESTAMP} and length $self->{TIMESTAMP})
        {
            return;
        }

        # Unfortunately it looks like Time::Piece's strptime's %Z can't handle UTC as a timezone name
        $ts =~ s/ UTC$//;

        if (Time::Piece->can('use_locale')) {
            Time::Piece->use_locale();
        }
        my $tp = Time::Piece->strptime($ts, '%a %b %e %T %Y');

        $self->{TIMESTAMP} = $tp->datetime;
    }
}

sub Subsection ($)
{
    my $self = shift;
    my $s = shift;

    if ($self->{CURRENT_SECTION} =~ /test/i)
    {
        $s =~ s/ \(Bug currently UNFIXED.*\)//;
        push @{$self->{TESTS}}, {NAME => $s, RESULT => 0, TIME => 0};
    }
}

sub CurrentTest
{
    my $self = shift;
    my $last = $#{$self->{TESTS}};
    return ($last >= 0) ? $self->{TESTS}->[$last] : undef;
}

sub CleanCData
{
    my $strref = shift;
    $$strref =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f\x80-\xff]/?/g;
}

sub Error ($)
{
    my $self = shift;
    my $line = (shift) . "\n";
    my $test = $self->CurrentTest ();
    return unless defined $test;

    ++$self->{FAILED} unless defined $test->{ERROR};
    CleanCData (\$line);
    $test->{ERROR} .= $line;
    $test->{OUT} .= $line;
}

sub Warning ($)
{
    my $self = shift;
    my $line = (shift) . "\n";
    my $test = $self->CurrentTest ();
    return unless defined $test;
    CleanCData (\$line);
    $test->{OUT} .= $line;
}

sub Normal ($)
{
    my $self = shift;
    my $line = (shift) . "\n";
    my $test = $self->CurrentTest ();
    return unless defined $test;
    my $separator = '=' x 78 . "\n";

    if ($line =~ /^auto_run_tests_finished: .*Time:(\d+)s\s+Result:([-\d]+)/)
    {
        $test->{TIME} = $1;
        $test->{RESULT} = $2;
    }
    elsif ($line ne $separator)
    {
        CleanCData (\$line);
        $test->{OUT} .= $line;
    }
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
    my $basename = shift;
    my $filename = $basename . '_Totals.html';
    my $self = {};

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
    unless ($self->{FH}) {
        print STDERR __FILE__, ": ERROR: Could not create file $filename $!\n";
        return undef;
    }

    $self->{FILENAME} = $filename;
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
    $self->{TOTAL_ERROR_SUBSECTIONS} = 0;

    $self->{CVS_TIMESTAMP} = 'None'; ## Prismtech still use some CVS please leave
    $self->{SUBVERSION_LAST_EXTERNAL}  = 'None';
    $self->{SUBVERSION_CHECKEDOUT_ACE} = 'None';
    $self->{SUBVERSION_CHECKEDOUT_MPC} = 'None';
    $self->{SUBVERSION_CHECKEDOUT_OPENDDS} = 'None';
    $self->{GIT_CHECKEDOUT_ACE} = 'None';
    $self->{GIT_CHECKEDOUT_OPENDDS} = 'None';
    $self->{SVN_REVISIONS} = ();
    $self->{GIT_REVISIONS} = ();

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
    $self->{TOTAL_ERROR_SUBSECTIONS} += $self->{SECTION_ERROR_SUBSECTIONS};
    $self->{SECTION_ERROR_SUBSECTIONS} = 0;
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

    $totals .= " Failures: $self->{TOTAL_ERROR_SUBSECTIONS}";
    if ($self->{GIT_CHECKEDOUT_ACE}) {
      my $sha = substr($self->{GIT_CHECKEDOUT_ACE}, 0, 8);
      $totals .= " ACE: $sha";
    } else {
      $totals .= " ACE: $self->{SUBVERSION_CHECKEDOUT_ACE}";
    }
    $totals .= " MPC: $self->{SUBVERSION_CHECKEDOUT_MPC}";
    $totals .= " CVS: \"$self->{CVS_TIMESTAMP}\""; ## Prismtech still use some CVS please leave
    if ($self->{GIT_CHECKEDOUT_OPENDDS}) {
      my $sha = substr($self->{GIT_CHECKEDOUT_OPENDDS}, 0, 8);
      $totals .= " OpenDDS: $sha";
    } else {
      $totals .= " OpenDDS: $self->{SUBVERSION_CHECKEDOUT_OPENDDS}";
    }
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
    $self->{CVS_TIMESTAMP} = shift if ($self->{CVS_TIMESTAMP} eq 'Yes'); ## Prismtech still use some CVS please leave
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
our %commits = ();
our $tsan_report = 0;
our $asan_report = 0;
our $leak_report = 0;
our $stack_trace_report = 0;

###############################################################################

sub new ($$$$$$$$)
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    my $basename = shift;
    my $buildname = shift;
    my $failed_tests_ref = shift;
    my $skip_failed_test_logs = shift;
    my $rev_link = shift;
    my $log_prefix = shift;
    my $failed_tests_only = shift;

    # Initialize some variables
    $self->{STATE} = '';
    $self->{LAST_SECTION} = '';
    $self->{LAST_DESCRIPTION} = '';
    $self->{FAILED_TESTS} = $failed_tests_ref;
    $self->{FAILED_TESTS_ONLY} = $failed_tests_only;

    if (!$failed_tests_only) {
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
                new Prettify::Full_HTML ($basename),   #Must be at 0
                new Prettify::Brief_HTML ($basename),
                new Prettify::Totals_HTML ($basename), #Must be at 2
                new Prettify::Config_HTML ($basename), #Must be at 3
            );

        if (!$skip_failed_test_logs) {
            push @{$self->{OUTPUT}}, new Prettify::Failed_Tests_HTML($basename, $buildname, $self->{FAILED_TESTS}, $rev_link, $log_prefix); #Must be at 4, if used with other reports
        }
    } else { # $failed_tests_only
        my $total_html = new Prettify::Totals_HTML($basename);
        $self->{TOTALS} = $total_html;
        @{$self->{OUTPUT}} = ($total_html);
        if (!$skip_failed_test_logs) {
            %{$self->{HANDLERS}} = (
                'begin'     => \&Normal_Handler,
                'setup'     => \&Setup_Handler,
                'config'    => \&Config_Handler,
                'configure' => \&Autoconf_Handler,
                'compile'   => \&Compile_Handler,
                'test'      => \&Test_Handler,
                'end'       => \&Normal_Handler
            );
            push @{$self->{OUTPUT}}, new Prettify::Failed_Tests_HTML($basename, $buildname, $self->{FAILED_TESTS}, $rev_link, $log_prefix);
        }
    }

    my $junit = main::GetVariable ('junit_xml_output');
    if (defined $junit) {
        if ($junit eq '1') {
            $junit = $basename;
        }
        else {
            $basename =~ /^(.*[\/\\])/;
            $junit = ((defined $1) ? $1 : '') . $junit;
        }
        push @{$self->{OUTPUT}}, new Prettify::JUnit ($junit);
    }

    # Output the header for the files
    foreach my $output (@{$self->{OUTPUT}}) {
        unless ($output) {
            print STDERR __FILE__, ": ERROR: Output failed initialization\n";
            return undef;
        }
        $output->Header ();
    }

    %{$self->{UNFIXED_BUGS}} = ();
    my $current_dir = Cwd::getcwd ();
    my $root = main::GetVariable ('root');
    chdir ($root) if (defined $root);
    my $project = main::GetVariable ('project_root');
    if (!defined $project) {
        $project = 'ACE_wrappers';
    }
    my @files;
    chdir ($project);
    if (defined $ENV{ACE_ROOT}) {
        push @files, "$ENV{ACE_ROOT}/bin/ace_tests.lst",
                     "$ENV{ACE_ROOT}/tests/run_test.lst";
    }
    if (defined $ENV{TAO_ROOT}) {
        push @files, "$ENV{TAO_ROOT}/bin/tao_orb_tests.lst",
                     "$ENV{TAO_ROOT}/bin/tao_other_tests.lst";
    }
    if (defined $ENV{CIAO_ROOT}) {
        push @files, "$ENV{CIAO_ROOT}/bin/ciao_tests.lst";
    }
    if (defined $ENV{DANCE_ROOT}) {
        push @files, "$ENV{DANCE_ROOT}/bin/dance_tests.lst";
    }
    foreach my $file (@files) {
      if (-r $file) {
        my $fileinput = new FileHandle ($file, 'r');
        while (<$fileinput>) {
          if (/\!FIXED_BUGS_ONLY/) {
            if (/^\s*([^\:]*)/) {
              my $TestName = $1;
              $TestName =~ s/\s+$//;
              $self->{UNFIXED_BUGS}{$TestName} = 1;
            }
          }
        }
      }
    }
    if (-r 'tests/run_test.lst') {
      my $fileinput = new FileHandle ('tests/run_test.lst', 'r');
      while (<$fileinput>) {
        if (/\!FIXED_BUGS_ONLY/) {
          if (/^\s*([^\:]*)/) {
            my $TestName = "tests/$1";
            $TestName =~ s/\s+$//;
            $self->{UNFIXED_BUGS}{$TestName} = 1;
          }
        }
      }
    }
    if (-r 'ACE/tests/run_test.lst') {
      my $fileinput = new FileHandle ('ACE/tests/run_test.lst', 'r');
      while (<$fileinput>) {
        if (/\!FIXED_BUGS_ONLY/) {
          if (/^\s*([^\:]*)/) {
            my $TestName = "tests/$1";
            $TestName =~ s/\s+$//;
            $self->{UNFIXED_BUGS}{$TestName} = 1;
          }
        }
      }
    }
    chdir ($current_dir);

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
        if ($section =~ m/([^(]*) \((.*)\)/) {
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
    if (!defined $s)
    {
        $self->Output_Normal (" ");
        return;
    }

    my $totals= $self->{FAILED_TESTS_ONLY} ? $self->{TOTALS} : (@{$self->{OUTPUT}})[2];

    if ($s =~ m/Executing: (?:.*\/)?cvs(?:.exe)? /i) ## Prismtech still use some CVS please leave
    {
        $self->Output_Normal ($s);
        $totals->{CVS_TIMESTAMP} = 'Yes';
    }
    elsif ($s =~ m/Change (\d+) on \d+\/\d+\/\d+ by/i) ## This is for Perforce please leave
    {
        $self->Output_Normal ($s);

        my $revision = $1;
        $totals->{SUBVERSION_CHECKEDOUT_ACE} = $revision;
    }
    elsif ($s =~ m/Fetching external item into '([^']+)'/i)
    {
        $self->Output_Normal ($s);
        $totals->{SUBVERSION_LAST_EXTERNAL} = $1;
    }
    elsif ($s =~ m/git-svn-id: svn:\/\/svn.dre.vanderbilt.edu\/DOC\/Middleware\/trunk\@(\d+) /i)
    {
        my $revision = $1;
        $totals->{SUBVERSION_CHECKEDOUT_ACE} = $1;
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/git-svn-id: svn:\/\/svn.dre.vanderbilt.edu\/DOC\/MPC\/trunk\@(\d+) /i)
    {
        my $revision = $1;
        $totals->{SUBVERSION_CHECKEDOUT_MPC} = $1;
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/git-svn-id: svn:\/\/svn.dre.vanderbilt.edu\/DOC\/DDS\/trunk\@(\d+) /i)
    {
        my $revision = $1;
        $totals->{SUBVERSION_CHECKEDOUT_OPENDDS} = $1;
        $self->Output_Normal ($s);
    }
    elsif ($s =~ m/(?:Checked out|Updated) external (?:at|to) revision (\d+)\./i)
    {
        my $revision = $1;
        my $external= $totals->{SUBVERSION_LAST_EXTERNAL};

        $self->Output_Normal ($s);
        if ($external =~ m/MPC$/)
        {
            $totals->{SUBVERSION_CHECKEDOUT_MPC} = $revision;
        }
        elsif ($external =~ m/ACE_wrappers(?:\/TAO(?:\/CIAO)?)?$/)
        {
            if ('None' eq $totals->{SUBVERSION_CHECKEDOUT_ACE})
            {
                $totals->{SUBVERSION_CHECKEDOUT_ACE} = $revision;
            }
            elsif ($revision ne $totals->{SUBVERSION_CHECKEDOUT_ACE})
            {
                $totals->{SUBVERSION_CHECKEDOUT_ACE} = 'Mixed';
            }

            ## Prismtech still use some CVS please leave
            if ($totals->{CVS_TIMESTAMP} =~ m/^None$|^SVN Rev/)
            {
                $totals->{CVS_TIMESTAMP} = "SVN Rev: $totals->{SUBVERSION_CHECKEDOUT_ACE}";
            }
        }
    }
    elsif ($s =~ m/(?:Checked out|Updated to|At) revision (\d+)\./i)
    {
        my $revision = $1;
        my $external= $totals->{SUBVERSION_LAST_EXTERNAL};

        $self->Output_Normal ($s);
        if ('None' ne $external)
        {
            # This is the tail end of a set, it has already been dealt with.
            $totals->{SUBVERSION_LAST_EXTERNAL}  = 'None';
        }
        # Since we don't know what is being checked out or updated, we have to guess
        # (unlike when sets are used, these are accurately handled above).
        elsif ($revision < 70000)
        {
            $totals->{SUBVERSION_CHECKEDOUT_MPC} = $revision;
        }
        else
        {
            if ('None' eq $totals->{SUBVERSION_CHECKEDOUT_ACE})
            {
                $totals->{SUBVERSION_CHECKEDOUT_ACE} = $revision;
            }
            elsif ($revision != $totals->{SUBVERSION_CHECKEDOUT_ACE})
            {
                $totals->{SUBVERSION_CHECKEDOUT_ACE} = 'Mixed';
            }

            ## Prismtech still use some CVS please leave
            if ($totals->{CVS_TIMESTAMP} =~ m/^None$|^SVN Rev/)
            {
                $totals->{CVS_TIMESTAMP} = "SVN Rev: $totals->{SUBVERSION_CHECKEDOUT_ACE}";
            }

            ## Some OpenDDS builds are using old build system, rather than jenkins
            if ('None' eq $totals->{SUBVERSION_CHECKEDOUT_OPENDDS})
            {
                $totals->{SUBVERSION_CHECKEDOUT_OPENDDS} = $revision;
            }
        }
    }
    elsif (($s =~ m/git clone.*(git|https):\/\/.*atcd\.git/i) ||
           ($s =~ m/origin.*(git|https):\/\/.*atcd\.git/i) ||
           ($s =~ m/git clone.*(git|https):\/\/.*ace_tao\.git/i) ||
           ($s =~ m/origin.*(git|https):\/\/.*ace_tao\.git/i))
    {
      # Add git remote -v to config before git log -1 to guarantee url
      $totals->{GIT_CHECKEDOUT_ACE} = "Matched";
      $self->Output_Normal ($s);
    }
    elsif (($s =~ m/git clone.*(git|https):\/\/.*OpenDDS\.git/i) ||
           ($s =~ m/origin.*(git|https):\/\/.*OpenDDS\.git/i))
    {
      # Add git remote -v to config before git log -1 to guarantee url
      $totals->{GIT_CHECKEDOUT_OPENDDS} = "Matched";
      $self->Output_Normal ($s);
    }
    elsif ($s =~ m/^commit (.*)$/)
    {
      my $sha = $1;
      if ("$totals->{GIT_CHECKEDOUT_ACE}" eq "Matched")
      {
        $totals->{GIT_CHECKEDOUT_ACE} = $sha;
      }
      elsif ("$totals->{GIT_CHECKEDOUT_OPENDDS}" eq "Matched")
      {
        $totals->{GIT_CHECKEDOUT_OPENDDS} = $sha;
        if (exists ($self->{OUTPUT}[$self->{FAILED_TESTS_ONLY} ? 0 : 4]))
        {
            (@{$self->{OUTPUT}})[$self->{FAILED_TESTS_ONLY} ? 0 : 4]->{GIT_CHECKEDOUT_OPENDDS} = $sha;
        }
      }
      $self->Output_Normal ($s);
    }
    elsif ($s =~ m/aborted/i ||
        $s =~ m/cannot access/i ||
        $s =~ m/nothing known about/ ||
        $s =~ m/processing is incomplete/ ||
        $s =~ m/syntax error near unexpected token/ ||
        $s =~ m/Error processing command/ ||
        $s =~ m/is not a working copy/ ||
        $s =~ m/svn help cleanup/ ||
        $s =~ m/t connect to host/ ||
        $s =~ m/Checksum mismatch for/ ||
        $s =~ m/unknown user/ ||
        $s =~ m/not found in upstream origin, using HEAD instead/ ||
        $s =~ m/Could not find remote branch/ ||
        $s =~ m/Failed to add file/ ||
        $s =~ m/Failed to add directory/ ||
        $s =~ m/error: Autoconf version/ ||
        $s =~ m/m4 failed with/ ||
        $s =~ m/^ERROR/ ||
        $s =~ m/[^\w]+ERROR/ ||
        $s =~ m/no such file/i ||
        $s =~ m/BUILD FAILED/ ||
        $s =~ m/Error: Another instance of MPC is using/ ||
        $s =~ m/The following error occurred while executing this line/ ||
        $s =~ m/No commands are being checked/ ||
        $s =~ m/When Checking \"/ ||
        $s =~ m/command not found\"/ ||
        $s =~ m/No commands are being executed/)
    {
        $self->Output_Error ($s);
    }
    elsif ($s =~ /^M / ||
           $s =~ m/WARNING/ ||
           $s =~ m/IGNORING/ ||
           $s =~ m/svn: warning:/ ||
           $s =~ m/has not been defined/ )
    {
        $self->Output_Warning ($s);
    }
    else
    {
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

    # We only want to output config stuff to the Config_HTML class (and FULL)
    if (!$self->{FAILED_TESTS_ONLY}){
        $outputs[0]->Normal($s, $state);
        $outputs[3]->Normal($s, $state);
    }

    my $totals= $self->{FAILED_TESTS_ONLY} ? $self->{TOTALS} : (@{$self->{OUTPUT}})[2];

    if ($s =~ m/SVN_REVISION(_(\d))?=(\d+)/)
    {
        my $index = $2;
        $index ||= 0;
        $totals->{SVN_REVISIONS}[$index] = $3;
    }
    elsif ($s =~ m/SVN_URL(_(\d))?=(.+)/)
    {
        my $index = $2;
        $index ||= 0;

        my $revision = $totals->{SVN_REVISIONS}[$index];
        my $url = $3;

        if ($url =~ m/svn:\/\/svn.dre.vanderbilt.edu\/DOC\/Middleware/i)
        {
            $totals->{SUBVERSION_CHECKEDOUT_ACE} = $revision;
        }
        elsif ($url =~ m/svn\+ssh:\/\/svn.ociweb.com\/ocitao/i)
        {
            $totals->{SUBVERSION_CHECKEDOUT_ACE} = $revision;
        }
        elsif ($url =~ m/svn:\/\/svn.dre.vanderbilt.edu\/DOC\/DDS\/trunk/i)
        {
            print "matched\n";
            $totals->{SUBVERSION_CHECKEDOUT_OPENDDS} = $revision;
        }
        elsif ($url =~ m/svn:\/\/svn.dre.vanderbilt.edu\/DOC\/DDS\/branches/i)
        {
            print "matched\n";
            $totals->{SUBVERSION_CHECKEDOUT_OPENDDS} = $revision;
        }
        elsif ($url =~ m/svn:\/\/svn.dre.vanderbilt.edu\/DOC\/MPC\/trunk/i)
        {
            $totals->{SUBVERSION_CHECKEDOUT_MPC} = $revision;
        }
    }
    elsif ($s =~ m/GIT_URL=(.+)/)
    {
        # Jenkins environment
        my $url = $1;
        if (($url =~ m/(git|https):\/\/.*\/ACE_TAO\.git/i) ||
            ($url =~ m/(git|https):\/\/.*\/ATCD\.git/i))
        {
            print "Matched GIT url $url\n";
            my $revision = $totals->{GIT_REVISIONS}[0];
            print "Matched GIT url to revision $revision\n";
            $totals->{GIT_CHECKEDOUT_ACE} = $revision;
            $commits{'GIT_COMMIT_ACE'} = $revision;
        }
        elsif ($url =~ m/(git@|(git|https):\/\/).*\/OpenDDS\.git/i)
        {
            print "Matched GIT url $url\n";
            my $revision = $totals->{GIT_REVISIONS}[0];
            print "Matched GIT url to revision $revision\n";
            $totals->{GIT_CHECKEDOUT_OPENDDS} = $revision;
            $commits{'GIT_COMMIT_OPENDDS'} = $revision;
            if (exists ($self->{OUTPUT}[$self->{FAILED_TESTS_ONLY} ? 0 : 4]))
            {
                (@{$self->{OUTPUT}})[$self->{FAILED_TESTS_ONLY} ? 0 : 4]->{GIT_CHECKEDOUT_OPENDDS} = $revision;
            }
        }
    }
    elsif ($s =~ m/GIT_COMMIT=(.+)/)
    {
        print "Matched GIT revision $1\n";
        $totals->{GIT_REVISIONS}[0] = $1;
    }
}

sub Autoconf_Handler ($)
{
    my $self = shift;
    my $s = shift;

    if ($s =~ m/syntax error near unexpected token/
        || $s =~ m/Syntax error at line/) {
        $self->Output_Error ($s);
    }
    elsif ($s =~ m/configure: WARNING:/) {
        $self->Output_Warning ($s);
    }
    else {
        $self->Output_Normal ($s);
    }
}

# If you update this method also update prettify.rb in the same directory
sub Test_Handler ($)
{
    my $self = shift;
    my $s = shift;

    # Check for the subsection indicator

    if ($s =~ m/auto_run_tests:\s*(.*)/) {
        my $testname = $1;
        $testname =~ s/\s+$//;
        if (defined $self->{UNFIXED_BUGS}{$testname}) {
          $testname .= ' (Bug currently UNFIXED, This test may fail)';
        }
        $self->Output_Subsection ($testname);
        return;
    }

    if ($s =~ m/gethostbyname: getaddrinfo returned ERROR/
     || $s =~ m/==\d+==.*XML::XML_Error_Handler/) # valgrind stack trace
    {
      $self->Output_Normal ($s);
    }
    elsif ($s =~ m/Mismatched free/
        || $s =~ m/are definitely lost in loss record/
        || $s =~ m/: UNIMPLEMENTED FUNCTION:/
        || $s =~ m/: parse error/
        || $s =~ m/Invalid write of size/
        || $s =~ m/Invalid read of size/
        || $s =~ m/invalid string:/
        || $s =~ m/Conditional jump or move depends on uninitialised value/
        || $s =~ m/free\(\): invalid pointer:/
        || $s =~ m/Use of uninitialised value of size/
        || $s =~ m/compilation aborted at/
        || $s =~ m/RbX-ERR:/
        || $s =~ m/RILL-ERR:/
        || $s =~ m/memPartAlloc: block too big/
        || $s =~ m/C interp: token/
        || $s =~ m/ld error: error loading file/
        || $s =~ m/Stale NFS file handle/
        || $s =~ m/exception resulted in call to terminate/
        || $s =~ m/terminate called after throwing an instance of/
        || $s =~ m/symbol lookup error/
        || $s =~ m/aborted due to compilation errors/
        || $s =~ m/Segmentation fault/
        || $s =~ m/Can't open perl script/
        || $s =~ m/Write failed: Broken pipe/
        || $s =~ m/exec request failed on channel/
        || $s =~ m/Don't know how to make check/
        || $s =~ m/Could not open/
        || $s =~ m/Errno::ENOENT/
        || ($s =~ m/No such file or directory/ && $s !~ m/LLVMSymbolizer: error reading file:/)
        || $s =~ m/C interp: unable to open/
        || $s =~ m/glibc detected/
        || $s =~ m/holds reference to undefined symbol/
        || $s =~ m/service name too long/
        || $s =~ m/unknown symbol name/
        || $s =~ m/is not recognized as an internal or external command/
        || $s =~ m/can't open input/
        || $s =~ m/ACE_SSL .+ error code\: [0-9]+ - error\:[0-9]+\:SSL routines\:SSL3_READ_BYTES\:sslv3 alert certificate expired/
        || $s =~ m/memPartFree: invalid block/ )
    {
        $self->Output_Error ($s);
    }
    elsif ($s =~ m/: ThreadSanitizer:/)
    {
        if (!$tsan_report)
        {
            $tsan_report = 1;
            $self->Output_Error ($s);
        }
        else
        {
            $self->Output_Normal ($s);
            $tsan_report = 0;
        }
    }
    elsif ($s =~ m/LeakSanitizer:/)
    {
        # Indicating the beginning of a memory leak sanitizer report.
        $leak_report = 1;
        $self->Output_Error ($s);
    }
    elsif ($s =~ m/AddressSanitizer:/)
    {
        # Can appear at the end of a leak report or before memory contents are laid out
        # in the other types of address sanitizer report.
        if ($leak_report)
        {
            $self->Output_Normal ($s);
            $leak_report = 0;
        }
        elsif (!$asan_report)
        {
            $asan_report = 1;
            $self->Output_Error ($s);
        }
        else
        {
            $self->Output_Normal ($s);
        }
    }
    elsif ($s =~ m/==\d+==ABORTING/)
    {
        # End of an address sanitizer report that is not a leak report.
        $self->Output_Normal ($s);
        $asan_report = 0;
    }
    elsif ($s =~ m/Begin stack trace/)
    {
        $stack_trace_report = 1;
        $self->Output_Normal ($s);
    }
    elsif ($s =~ /End stack trace/)
    {
        $self->Output_Normal ($s);
        $stack_trace_report = 0;
    }
    elsif (!defined $ENV{"VALGRIND_ERRORS_ONLY"} &&
            ## We want to catch things like "Error:", "WSAGetLastError",
            ## "Errors Detected" and "Error ", but not things like
            ## -ORBAcceptErrorDelay.
            ($s =~ m/Error[s]?[^A-Za-z]/
          || $s =~ m/ERROR/
          || $s =~ m/fatal/
          || $s =~ m/FAIL:/
          || $s =~ m/FAILED/
          || ($s =~ m/EXCEPTION/ && $s !~ m/NO_EXCEPTIONS/
              && $s !~ m/DACE_HAS_EXCEPTIONS/)
          || $s =~ m/ACE_ASSERT/
          || $s =~ m/Assertion/
          || $s =~ m/Source and destination overlap/
          || $s =~ m/error while loading shared libraries/
          || $s =~ m/Compilation failed in require at/
          || $s =~ m/pure virtual /i) )
    {
        $self->Output_Error ($s);
    }
    elsif ($s =~ m/the ACE tests _may_ have leaked OS resources!/)
    {
        $self->Output_Warning ($s);
    }
    else
    {
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

sub Process
{
    my $filename = shift;
    my $buildname = shift;
    my $failed_tests_ref = shift;
    my $skip_failed_test_logs = shift;
    my $rev_link = shift;
    my $log_prefix = shift;
    my $failed_tests_only = shift;

    $buildname = "" if ! defined $buildname;
    $failed_tests_ref = {} if ! defined $failed_tests_ref;
    $skip_failed_test_logs = 1 if ! defined $skip_failed_test_logs;
    $rev_link = "" if ! defined $rev_link;
    $log_prefix = "" if ! defined $log_prefix;
    $failed_tests_only = 0 if ! defined $failed_tests_only;

    my $basename = $filename;
    $basename =~ s/\.txt$//;

    my $processor = new Prettify ($basename, $buildname, $failed_tests_ref, $skip_failed_test_logs, $rev_link, $log_prefix, $failed_tests_only);
    unless ($processor) {
        return undef; # error reported in Prettify::new
    }

    my $input = new FileHandle ($filename, 'r');
    while (<$input>) {
        chomp;
        $processor->Process_Line ($_);
    }

    # When we finish processing each line of the log file,
    # if we detect any BUILD ERROR messages, send an e-mail
    # notification if MAIL_ADMIN was specified in the XML config
    # file.
    if (!$failed_tests_only) {
        my @errors = $processor->BuildErrors();
        my $mail_admin = main::GetVariable ( 'MAIL_ADMIN' );
        my $mail_admin_file = main::GetVariable ( 'MAIL_ADMIN_FILE' );
        if ((scalar(@errors) > 0) && ((defined $mail_admin) || (defined $mail_admin_file))) {
            $processor->SendEmailNotification();
        }
    }

    return $processor;
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

    my $subject = "[AUTOBUILD] ".main::GetVariable('BUILD_CONFIG_FILE')." has build errors";
    my $message = "Errors detected while executing the build specified in ".main::GetVariable('BUILD_CONFIG_FILE').".\n".
                  "Please check the scoreboard for details.\n$scoreboard_url\n\n".
                  $errors_string;

    if (defined $mail_admin) {
       Mail::send_message($mail_admin, $subject, $message);
    }

    my $mail_admin_file = main::GetVariable ( 'MAIL_ADMIN_FILE' );

    if (defined $mail_admin_file) {
       if (open(MAIL_ADDRESS, "<$mail_admin_file")) {
          while(<MAIL_ADDRESS>) {
             Mail::send_message($_, $subject, $message);
          }
       }
       else {
          print STDERR __FILE__,
                       ": ERROR: Unable to open the MAIL_ADMIN_FILE: $mail_admin_file\n";
          return 0;
       }
    }
}

###############################################################################

package Prettify::Config_HTML;

use strict;
use warnings;

use FileHandle;
our $host = 'localhost';
my $host_next = 0;

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
    unless ($self->{FH}) {
        print STDERR __FILE__, ": ERROR: Could not create file $filename $!\n";
        return undef;
    }

    $self->{FILENAME} = $filename;

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
    if (defined $state) {
        $state = lc($state);
    }
    if (defined $state && $state eq 'config') {
        if ($host eq 'localhost') {
            if ($host_next == 1) {
                $host = $s;
            }
            elsif ($s eq "<h3>Hostname</h3>") {
                $host_next = 1;
            }
        }
        $s =~ s/</&lt;/g;
        $s =~ s/>/&gt;/g;
        $s =~ s/&lt;\s*(\/?\s*h\d|\/a|a\s*href\s*=\s*\s*"[^"]*")\s*&gt;/<$1>/g;
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
    my $s = shift || '';
    my $state = shift;
    $state = lc ($state);

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
