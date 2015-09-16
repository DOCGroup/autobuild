#

package JBoss_Report;

use strict;
use warnings;

use DirHandle;
use File::Copy;
use FileHandle;
use POSIX;
use Time::Local;
use File::Path;

###############################################################################
# Forward Declarations

sub copy_log ();

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};

    bless ($self, $class);
    return $self;
}

##############################################################################

sub CheckRequirements ()
{
    my $self = shift;

    my $root = main::GetVariable ('root');
    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }

    my $project_root = main::GetVariable ('project_root');
    if (!defined $project_root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
        return 0;
    }

    my $log_root = main::GetVariable ('log_root');
    if (!defined $log_root) {
        print STDERR __FILE__, ": Requires \"log_root\" variable\n";
        return 0;
    }

    my $log_file = main::GetVariable ('log_file');
    if (!defined $log_file) {
        print STDERR __FILE__, ": Requires \"log_file\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $keep = 10;
    my $log_root = main::GetVariable ('log_root');
    my $root = main::GetVariable ('root');
    my $project_root = main::GetVariable ('project_root');

    if (!-r $log_root || !-d $log_root) {
        ## Due to weirdness from NFS, this directory may exist but not
        ## show up until we attempt to create the directory.  If it
        ## exists, we don't want to stop processing so catch the
        ## Carp::croak with an eval.
        eval { mkpath($log_root) };
    }

    if (!-r $root || !-d $root) {
        eval { mkpath($root) };
    }

    if (!-r $project_root || !-d $project_root) {
        eval { mkpath($project_root) };
    }

    if ($main::verbose == 1 ) {
        main::PrintStatus ('Processing Logs', '');
    }

    # Copy the logs
    if ($options =~ m/copy/) {
        if ($options =~ m/copy='([^']*)'/ ||
            $options =~ m/copy=([^\s]*)/) {
            $keep = $1;
        }
    }
    else {
        return 0;
    }

    if ($options =~ m/copy='([^']*)'/ || $options =~ m/copy=([^\s]*)/) {
        my $retval = $self->copy_log ($1);
        return 0 if ($retval == 0);
    }
    elsif ($options =~ m/copy/) {
        my $retval = $self->copy_log ($keep);
        return 0 if ($retval == 0);
    }

    return 1;
}

##############################################################################

sub copy_log ()
{
    my $self = shift;
    my $keep = shift;
    my $root = main::GetVariable ('root');
    my $project_root = main::GetVariable ('project_root');
    my $log_root = main::GetVariable ('log_root');
    my $log_file = main::GetVariable ('log_file');
    my $jboss_reports_dir = main::GetVariable ('jboss_reports_dir');
    my $save_root;

    # chop off trailing slash
    if ($log_root =~ m/^(.*)\/$/) {
        $log_root = $1;
    }
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }
    if ($project_root =~ m/^(.*)\/$/) {
        $project_root = $1;
    }

    # Create name of save directory ( = name of build )
    if ($log_root =~ m/.*\/(.*)$/) {
        $save_root = $root . "/" . $1;
    }

    if (!-r $save_root || !-d $save_root) {
        mkpath($save_root);
    }
    my $oldlog_file = $root . "/" . $log_file;
    if (!defined $oldlog_file) {
        print STDERR __FILE__, ": Requires \"logfile\" variable\n";
        return 0;
    }
    if (!-r $oldlog_file) {
        print STDERR __FILE__, ": Cannot read logfile: $oldlog_file\n";
        return 0;
    }

    my $reports_html;
    my $newreportsdir;
    my $old_jboss_reports_dir;
    my $timestamp = POSIX::strftime("%Y_%m_%d_%H_%M", gmtime);
    if (defined $jboss_reports_dir) {
        $old_jboss_reports_dir = $project_root . "/" . $jboss_reports_dir;
        if (!-d $old_jboss_reports_dir) {
            print STDERR __FILE__, ": Cannot read directory: $old_jboss_reports_dir\n";
            return 0;
        }
        my $reportsdir = $timestamp . "_reports";
        $reports_html = $reportsdir . "/html";
        $newreportsdir = $log_root . "/" . $reportsdir;
    }

    my $newlogfile = $log_root . "/" . $timestamp . ".txt";
    my $savelogfile = $save_root . "/" . $timestamp . ".txt";
    my $savereportsdir = $save_root . "/" . $timestamp . "_reports";

    if ($main::verbose == 1) {
        print "Copying $oldlog_file to $newlogfile\n";
    }

    my $edited_log_file = $oldlog_file . ".tmp";
    edit_logfile ($oldlog_file, $edited_log_file, $reports_html);
    my $ret;
    ## copy returns the number of successfully copied files
    $ret = copy ($edited_log_file, $newlogfile);
    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem copying $oldlog_file to $newlogfile: $!\n";
        return 0;
    }

    # Make sure it has the correct permissions
    chmod (0644, $newlogfile);
   
    if (defined $old_jboss_reports_dir) {
        copy_dir($old_jboss_reports_dir, $newreportsdir);
    }
    # Touch a trigger file to tell the scoreboard that the log is complete
    my $triggerfile = $log_root . "/post";
    open(FH, ">$triggerfile");
    close(FH);

    if ($main::verbose == 1) {
        print "Saving $oldlog_file as $newlogfile\n";
    }

    # This should be a simple move, however, we  use copy/unlink instead
    # of move since on Windows the move fails if the file is open (like
    # a test that doesn't finish) whereas the copy and unlink succeed.
    $ret = copy ($oldlog_file, $savelogfile);
    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem copying $oldlog_file to $savelogfile: $!\n";
        return 0;
    }

    $ret = unlink ($oldlog_file);

    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem removing $oldlog_file: $!\n";
    }
    chmod (0644, $savelogfile);

    $ret = unlink ($edited_log_file);

    if ( $ret < 1 ) {
        print STDERR __FILE__, "Problem removing $edited_log_file: $!\n";
    }

    # Clean up old saved files
    my $dh = new DirHandle ($save_root);
    my @existing_local_logs;

    # Load the directory contents into the @existing array

    if (!defined $dh) {
        print STDERR __FILE__, ": Could not read directory $save_root\n";
        return 0;
    }

    while (defined($_ = $dh->read)) {
        if ($_ =~ m/^(...._.._.._.._..).txt$/) {
            push @existing_local_logs, $save_root . '/' . $1;
        }
    }
    undef $dh;

    $dh = new DirHandle ($log_root);
    my @existing_logs;
    my @existing_reports;

    # Load the directory contents into the @existing array

    if (!defined $dh) {
        print STDERR __FILE__, ": Could not read directory $save_root\n";
        return 0;
    }

    while (defined($_ = $dh->read)) {
        if ($_ =~ m/^(...._.._.._.._..).txt$/) {
            push @existing_logs, $log_root . '/' . $1;
        }
        elsif ($_ =~ m/^(...._.._.._.._.._reports)$/) {
            push @existing_reports, $log_root . '/' . $1;
        }
    }
    undef $dh;
   
    @existing_local_logs = reverse sort @existing_local_logs;
    @existing_logs = reverse sort @existing_logs;
    @existing_reports = reverse sort @existing_reports;

    # Remove the latest $keep logs from the list

    for (my $i = 0; $i < $keep; ++$i) {
        shift @existing_local_logs;
        shift @existing_logs;
    }

    my $reports_keep = $keep / 2;
    if ($reports_keep < 1) {
        $reports_keep = 1;
    }
   
    for (my $i = 0; $i < $reports_keep; ++$i) {
        shift @existing_reports;
    }
   
    # Delete anything left in the list

    foreach my $file (@existing_local_logs) {
        unlink $file . ".txt";
    }

    foreach my $file (@existing_logs) {
        unlink $file . ".txt";
    }

    foreach my $report_dir (@existing_reports) {
        File::Path::rmtree($report_dir);
    }

    return 1;
}

sub copy_dir ()
{
    my $from_dir = shift;
    my $to_dir = shift;

    my $dh = new DirHandle ($from_dir);
    mkdir($to_dir, 0755);
    my $ret;
    my @dir_contents = $dh->read();
    foreach my $content (@dir_contents) {
      unless ( ($content eq ".") || ($content eq "..") ) {
        my $from_content = $from_dir . "/" . $content;
        my $to_content = $to_dir . "/" . $content;
        if (-d $from_content) {
          $ret = &copy_dir($from_content, $to_content);
          if ( $ret < 1 ) {
              print STDERR __FILE__, "Problem copying directory $from_content to $to_content: $!\n";
              return 0;
          }
        }
        elsif (-e $from_content) {
          $ret = copy ($from_content, $to_content);
          if ( $ret < 1 ) {
              print STDERR __FILE__, "Problem copying $from_content to $to_content: $!\n";
              return 0;
          }
          chmod (0644, $to_content);
        }
      }
    }

    return 1;
}

sub find_targets()
{
    if ((/^_.*?\:\s*$/) ||
        ($_ !~ /^[[:alpha:]][[:alpha:]\-]+?\:\s*$/) ||
        (/-unit\:\s*$/))    {
        return "";
    }
    elsif ((/^(tomcat\-.*?\-tests)\:\s*$/) ||
           (/^(tests\-jacc\-.*?)\:\s*$/) ||
           (/^(tests\-jbossmessaging)\:\s*$/) ||
           (/^(tests\-jbossmessaging\-cluster)\:\s*$/) ||
           (/^(.*?\-invoker\-tests)\:\s*$/) ||
           (/^(.*?\-classloader\-leak)\:\s*$/) ||
           (/^(tests(?:\-.+?)?\-profile[^\-]*)\:\s*$/) ||
           (/^(jboss\-.+?\-tests)\:\s*$/) ||
           (/^(tests\-bootstrap\-dependencies)\:\s*$/) ||
           (/^(tests\-springdeployer)\:\s*$/) ||
           (/^(tests\-clustering\-all\-stacks)\:\s*$/) ||
           (/^(tests\-binding\-manager)\:\s*$/) ||
           (/^(tests\-compatibility)\:\s*$/) ||
           (/^(tests\-aop\-scoped)\:\s*$/) ||
           (/^(tests\-jts)\:\s*$/)) {
        return $1;
    }

    return "";
}

sub replace_error
{
    my $multiple = shift;
    $multiple = 0 if (!defined($multiple));

    my $replaced = 0;
    while (s/([E|e])rror/$1rr0r/ ||
           s/ERROR/ERR0R/) {
        $replaced = 1;

        last if !$multiple;
    }

    return $replaced;
}

sub replace_error_in_quote
{
    my $multiple = shift;
    $multiple = 0 if (!defined($multiple));

    my $replaced = 0;
    my @segments;
    my $string = $_;
    while ($string =~ s/^([^\"]*)(\"[^\"]*)(\")?//) {
        push(@segments, $1) if ($1 ne "");
        my $quote_str = $2;
        $quote_str .= $3 if (defined($3));
        push(@segments, $quote_str);
    }
    if ($string ne "") {
        push(@segments, $string);
    }
    my $ret_str = "";
    my $done = 0;
    for my $segment (@segments) {
        while (!$done &&
               ($segment =~ s/^(\"[^\"]*?[E|e])rror([^\"]*?\")$/$1rr0r$2/ ||
                $segment =~ s/^(\"[^\"]*?)ERROR([^\"]*?\")$/$1ERR0R$2/)) {
            $replaced = 1;
            $done = !$multiple;
        }
        $ret_str .= $segment;
    }
    $_ = $ret_str;

    return $replaced;
}

my $NO_SEQ = 0; my $FIND_TEST = 1; my $IN_RUN = 2; my $MAYBE_DONE = 3; my $RES_NEXT = 4;
my $line_num = 0;
sub end_test_section
{
    my $test_ref = shift;
    my $check_end = shift;

    my $size = scalar(@{$test_ref->{ind_test_lines}});
    if ($size == 0 ||
        (defined($check_end) && $check_end &&
         (($test_ref->{ind_test_run} +
           $test_ref->{ind_test_failures} +
           $test_ref->{ind_test_errors} +
           $test_ref->{ind_test_skipped}) == 0))) {
        print "ERROR: identified a Run, but no test results(line=$line_num," .
          " run=$test_ref->{run_name})\n" if ($test_ref->{run_name} ne "");
        return 0;
    }

    my $errors = $test_ref->{ind_test_failures} + $test_ref->{ind_test_errors};
    my $error_repl_str;
    my $num = 0;
    while ($errors > 0 && $num < $size) {
        if ($test_ref->{ind_test_lines}->[$num++] =~ /\b([E|e]rror|ERROR)\b/) {
            --$errors;
        }
    }

    if ($errors <= 0) {
        while ($num < $size) {
            while ($test_ref->{ind_test_lines}->[$num] =~ s/\b([E|e]rror|ERROR)\b/ERR0R(jboss7)/) {
            }
            ++$num;
        }
    }
    else {
        while ($errors-- > 0) {
            push(@{$test_ref->{ind_test_lines}}, "[JBoss7] ERROR (added for nightly build, see previous log output)\n");
        }
    }
    my $start = "";
    my $end = "";
    if ($test_ref->{ind_test_name} ne "") {
        $start = "\n\nauto_run_tests: $test_ref->{ind_test_name}\n";
        $end = "\nauto_run_tests_finished: $test_ref->{ind_test_name}\n\n";
    }
    $test_ref->{test_lines} .= $start;
    for my $ind_test_line (@{$test_ref->{ind_test_lines}}) {
        $test_ref->{test_lines} .= "$ind_test_line";
    }
    $test_ref->{test_lines} .= $end;
    $test_ref->{ind_test_lines} = [];

    $test_ref->{ind_test_run} = 0;
    $test_ref->{ind_test_failures} = 0;
    $test_ref->{ind_test_errors} = 0;
    $test_ref->{ind_test_skipped} = 0;
    $test_ref->{ind_test_name} = "";
    $test_ref->{run_name} = "";
    return 1;
}

sub inline_test
{
    my $test_ref = shift;
    my $newline_ref = shift;
    my $new_format = shift;
    $new_format = 0 if !defined($new_format);

    if ($test_ref->{test_seq} == $NO_SEQ) {
        if ($$newline_ref =~ /^\[INFO\] --- maven-\w+-plugin.*?\s(\S*)\s---\s*$/) {
            $test_ref->{ind_test_name} = $1;
        }

        if ($$newline_ref =~ /^$test_ref->{TEST_LINE}$/) {
            push(@{$test_ref->{delayed_lines}}, $$newline_ref);
            $test_ref->{test_seq} = $FIND_TEST;
            $$newline_ref = "";
        }
        return 0;
    }

    if ($test_ref->{test_seq} == $FIND_TEST) {
        if ($$newline_ref =~ s/^( T E S T S)$/$1 ($test_ref->{ind_test_name})/) {
            $test_ref->{test_seq} = $MAYBE_DONE;
            push(@{$test_ref->{ind_test_lines}}, @{$test_ref->{delayed_lines}});
        }
        else {
            my $delayed_lines = join("\n", @{$test_ref->{delayed_lines}});
            $$newline_ref = "$delayed_lines$$newline_ref";
        }
        $test_ref->{delayed_lines} = [];
    }
    elsif ($test_ref->{test_seq} && $$newline_ref =~ /^Running (\S+)\s*$/) {
        $test_ref->{run_name} = $1;
        $test_ref->{test_seq} = $IN_RUN;
    }
    elsif ($test_ref->{test_seq} && $$newline_ref =~ /Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: (\d+)/) {
        my $end_section = 0;
        if ($test_ref->{test_seq} == $RES_NEXT) {
            my $desc = ($test_ref->{ind_test_run} != $1) ?
                "Run total count=$test_ref->{ind_test_run}, but results indicates=$1;" : "";
            $desc .= ($test_ref->{ind_test_failures} != $2) ?
                "Failures total count=$test_ref->{ind_test_run}, but results indicates=$2;" : "";
            $desc .= ($test_ref->{ind_test_errors} != $3) ?
                "Errors total count=$test_ref->{ind_test_run}, but results indicates=$3;" : "";
            $desc .= ($test_ref->{ind_test_skipped} != $4) ?
                "Skipped total count=$test_ref->{ind_test_run}, but results indicates=$1" : "";
            if ($desc ne "") {
                print "ERROR: Total results don't match cummulative results(line=$line_num): $desc\n";
            }
            $end_section = 1;
        }
        else {
            $test_ref->{ind_test_run} += $1;
            $test_ref->{ind_test_failures} += $2;
            $test_ref->{ind_test_errors} += $3;
            $test_ref->{ind_test_skipped} += $4;
        }

        if ($$newline_ref =~ /^(.*)(Tests run: \d+, Failures: \d+, Errors: \d+, Skipped: .*)$/) {
            my $extra = $1;
            my $test_str = $2;
            if ($extra =~ /\S/) {
                push(@{$test_ref->{ind_test_lines}}, $extra);
                $$newline_ref = $test_str;
                print "Split <$extra> and <$test_str> (line=$line_num)\n";
            }
        }

        replace_test_errors($newline_ref, $new_format);
        $test_ref->{test_seq} = $MAYBE_DONE;
        push(@{$test_ref->{ind_test_lines}}, $$newline_ref);
        $$newline_ref = "";
        if ($end_section) {
            end_test_section($test_ref, 1);
        }
    }
    elsif ($test_ref->{test_seq} == $RES_NEXT) {
        if ($$newline_ref =~ /^\[INFO\]$/) {
            end_test_section($test_ref, 1);
            $test_ref->{test_seq} = $NO_SEQ;
        }
        $$newline_ref =~ s/^(Failed tests):/$1(jboss7 error):/;
    }
    elsif ($test_ref->{test_seq} == $MAYBE_DONE) {
        if ($$newline_ref =~ /^Results :\s*$/) {
            $test_ref->{test_seq} = $RES_NEXT;
        }
        elsif (!($$newline_ref =~ /^\s*$/) &&
               !($$newline_ref =~ /^$test_ref->{TEST_LINE}$/) &&
               !($$newline_ref =~ /^Concurrency/)) {
            end_test_section($test_ref, 1);
            $test_ref->{test_seq} = $NO_SEQ;
        }
    }

    if ($test_ref->{test_seq} == $NO_SEQ) {
        return 0;
    }

    push(@{$test_ref->{ind_test_lines}}, $$newline_ref);
    $$newline_ref = "";
   
    return 1;
}

sub edit_logfile()
{
    my $logfile = shift;
    my $new_logfile = shift;
    my $report_relative_location = shift;
    my $new_format = 0;
 
    open LOG, $logfile or die "ERROR: Can't open $logfile";
    open NEW_LOG, ">$new_logfile" or die "ERROR: Can't open $new_logfile";
    my $testfailed = 0;
    # indicates that we should not look for individual test targets
    my $no_ind_test_targets = 0;
    my $sub_test = "";
    my $testsection = 0;
    my $testsrun = 0;
    my $ind_test_name = "";
    my $ind_test_text = "";
    my $ind_test_errors = 0;
    my $temp = "";
    # identify Error matches within deprecated warnings
    my $deprecation_warning_seq = 0;
    my $in_audit = 0;
    my %test;
    $test{in_test} = 0;
    $test{test_seq} = $NO_SEQ;
    $test{test_lines} = "";
    $test{ind_test_lines} = [];
    $test{ind_test_run} = 0;
    $test{ind_test_failures} = 0;
    $test{ind_test_errors} = 0;
    $test{ind_test_skipped} = 0;
    $test{ind_test_name} = "";
    $test{run_name} = "";
    $test{delayed_lines} = [];
    $test{TEST_LINE} = "-------------------------------------------------------";
    my $endline;
    my $time_str;
    while (<LOG>) {
        chomp;
        if (m/jboss_7_/ || m/jboss_8_/ || m/wildfly/) {
            $new_format = 1;
        }
        if (defined($endline)) {
            # just tack on anything after and don't edit
            $endline .= "$_\n";
            next;
        }
        my $newline;
        ++$line_num;
        if (($deprecation_warning_seq > 0) &&
            (++$deprecation_warning_seq > 2)) {
            # only want to check one line after we identify the deprecated warning
            $deprecation_warning_seq = 0;
        }
       
        if (!defined($time_str) &&
            /^#################### [^\[]+ \[([^\]]+)\]/) {
            $time_str = $1;
        }

        if (/^\[INFO\] Starting audit\.\.\.\s*$/) {
            $in_audit = 1;
            $newline = "$_\n";
        }
        elsif ($in_audit && /^\s*Audit done.\s*/) {
            $in_audit = 0;
            $newline = "$_\n";
        }
        elsif ($in_audit &&
               /^.*:[0-9]+:\s/ &&
               !(/(?:[E|e]rror|ERROR)/) &&
               s/(^.*:[0-9]+:\s)/$1warning: /) {
            $newline = "$_\n";
        }
        elsif (/^#+\s+Test\s+\([^\)]*\)/) {
            # multiple Test sections are created, only use the first one
            if (++$testsection == 1) {
                $newline = "$_\n";
            }
        }
        elsif (($no_ind_test_targets == 0) && /^Running: \"build.(?:sh|cmd)\s+(\S+)\s*\" in /) {
            $sub_test = $1;
            if ($sub_test eq "tests") {
                $no_ind_test_targets = 1;
                $sub_test = "";
                $newline = "$_\n";
            }
            else {
                $newline = "auto_run_tests: $sub_test\n$_\n";
            }
        }
        elsif (/^Total time:(?: (\d+) minutes)? (\d+) seconds/) {
            my $teststime = 0;
            if (defined $1) {
                $teststime += 60 * $1;
            }
            if (defined $2) {
                $teststime += $2;
            }
            $newline = process_subtest_end(\$sub_test, \$testfailed, \$testsrun, $teststime);
            if ($newline eq "") {
                $newline = "$_\n";
            }
        }
        elsif (/^\s*\[junit\] Running (\S+)/) {
            if ($ind_test_name ne "") {
                $newline = edit_individual_test($ind_test_text, $ind_test_name, $ind_test_errors, $new_format);
                $ind_test_name = "";
            }
            $ind_test_text = "$_\n";
            $ind_test_name = $1;
        }
        elsif (/^\s*\[junit\] Tests (run\:.+)/) {
            $1 =~ /^run: (\d+), Failures: (\d+), Errors: (\d+), Time elapsed: \d+/;
            $testsrun += $1;
            $ind_test_errors = $2 + $3;
            $testfailed += $ind_test_errors;
            $ind_test_text .= "$_\n";
        }
        elsif (/^\s*\[junit\] Test .*? FAILED\s*$/) {
            $ind_test_text .= "$_\n";
        }
        elsif (/^\s*BUILD FAILED\s*$/) {
            $testfailed += 1;
            s/FAILED/FA1LED/;
            $newline = "$_\n";
        }
        elsif (/HeapDumpOnOutOfMemoryError/ && replace_error()) {
            $newline = "$_\n";
        }
        elsif (($no_ind_test_targets == 1) && (($temp = find_targets()) ne "")) {
            $newline = process_subtest_end(\$sub_test, \$testfailed, \$testsrun, "\<no time\>");
            $sub_test = $temp;
            $newline .= "auto_run_tests: $sub_test\n";
        }
        elsif (/warning\: \[deprecation\]/) {
            $deprecation_warning_seq = 1;
            $newline = "$_\n";
        }
        elsif (($deprecation_warning_seq > 0) &&
               (/\"[^\"]*?[E|e]rror[^\"]*?\"/) && replace_error_in_quote(1)) {
            # replace Error (reported in string after deprecated warning) with Err0r
            $newline = "$_\n";
        }
        elsif (/^\[WARNING\].*(?:[E|e]rror|ERROR)/ && replace_error(1)) {
            $newline = "$_\n";
        }
        elsif (/\"[^\"]*(?:[E|e]rror|ERROR)[^\"]*\"/ && replace_error_in_quote(1)) {
            # replace string with ERROR as ERR0R
            $newline = "$_\n";
        }
        elsif (/(error-context)/ ||
               /(?:[E|e]rror|ERROR) Context/) {
            replace_error(1);
            # replace string with ERROR as ERR0R
            $newline = "$_\n";
        }
        elsif (/#################### End \[/) {
            $endline = "$_\n";
            next;
        }
        else {
            if ($ind_test_name ne "") {
                $newline = edit_individual_test($ind_test_text, $ind_test_name, $ind_test_errors, $new_format);
                $ind_test_name = "";
            }
            $newline .= "$_\n";
        }

        if (!inline_test(\%test, \$newline, $new_format)) {
            print NEW_LOG "$newline";
        }
    }

    end_test_section(\%test);
    if ($test{test_lines} ne "") {
        if ($testsection == 0) {
            print NEW_LOG "#################### Test (testsuite) [$time_str]\n";
        }
        print NEW_LOG "$test{test_lines}";
    }
    if (defined($endline)) {
        print NEW_LOG "\n$endline\n";
    }

    if (defined($report_relative_location)) {
        print NEW_LOG "\[<a href=\"$report_relative_location\">JBoss Report Details</a>\]\n";
    }
    close LOG;
    close NEW_LOG;
}

sub replace_test_errors
{
    my $line_ref = shift;
    my $new_format = shift;
    $new_format = 0 if !defined($new_format);
    if (!$new_format || $$line_ref =~ m/Failures: 0, Errors: 0/) {
        $$line_ref =~ s/(Failures: \d+,) Errors: /$1 Err0rs: /;
    }
}

sub edit_individual_test()
{
    my $line = shift;
    my $test_name = shift;
    my $num_errors = shift;
    my $new_format = shift;
    $new_format = 0 if !defined($new_format);
    my $error_lines = 0;
   
    while ($line =~ m/\[junit\] Test $test_name FAILED/g) {
        ++$error_lines;
    }

    replace_test_errors(\$line, $new_format);

    while (++$error_lines <= $num_errors) {
        # add a psuedo-FAILED line, so it will be more obvious
        $line .= "    \[junit\] Test $test_name FAILED\*\n";
    }
   
    return $line;
}

sub process_subtest_end()
{
    my $ref_sub_test = shift;
    my $ref_testfailed = shift;
    my $ref_testsrun = shift;
    my $teststime = shift;
   
    if ($$ref_sub_test ne "") {
        # identifying this as a subsection for prettify.pm
        my $status = $$ref_testfailed;
        my $status_add_on = "";
        if ($$ref_testsrun > 0) {
            $status_add_on = "\(of $$ref_testsrun subtests\)";
        }
        $$ref_testfailed = 0;
        $$ref_testsrun = 0;
        return "\nauto_run_tests_finished: $$ref_sub_test Time:$teststime ".
            "Result:$status $status_add_on\n";
    }
   
    return "";
}

##############################################################################

main::RegisterCommand ("jboss_report", new JBoss_Report ());
