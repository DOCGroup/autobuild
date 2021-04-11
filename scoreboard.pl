eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

#

use FindBin;
use lib $FindBin::Bin;
use strict;
use warnings;
use diagnostics;
use common::prettify;
use common::scoreparser;
use common::indexparser;
use common::integratedparser;
use common::utility;
use DirHandle;
use English;
use FileHandle;
use File::Path;
use File::Basename;
use Getopt::Std;
use LWP::UserAgent;
use Time::Local;

###############################################################################
# Big bad variables

# %builds->{$name}->{GROUP}            <- Group this build is in
#                 ->{URL}              <- Link to use for directing to all logs
#                 ->{DIFFROOT}         <- URL to append GIT sha to, for diffs
#                 ->{MANUAL_LINK}      <- Link to use to manually start a build
#                 ->{ORANGE_TIME}      <- Number of hours before build turns orange
#                 ->{RED_TIME}         <- Number of hours before build turns red
#                 ->{STATUS}           <- Results of query of status link
#                 ->{BASENAME}         <- The basename of the latest build
#                 ->{CONFIG_SECTION}   <- Section number for the Config section
#                 ->{SETUP_SECTION}    <- Section number for the Setup section
#                 ->{SETUP_ERRORS}     <- Number of Setup Errors
#                 ->{SETUP_WARNINGS}   <- Number of Setup Warnings
#                 ->{COMPILE_SECTION}  <- Section number for the Compile section
#                 ->{COMPILE_ERRORS}   <- Number of Compile Errors
#                 ->{COMPILE_WARNINGS} <- Number of Compile Warnings
#                 ->{TEST_SECTION}     <- Section number for the Test section
#                 ->{TEST_ERRORS}      <- Number of Test Errors
#                 ->{TEST_WARNINGS}    <- Number of Test Warnings
#                 ->{SECTION_ERROR_SUBSECTIONS} <- Number of subsections with errors
#                 ->{FULL_HISTORY}     <- Link with full history information
#                 ->{CLEAN_HISTORY}    <- Link with clean history information
#                 ->{SUBVERSION_CHECKEDOUT_ACE}  <- SVN Revision of ACE_wrappers checked out
#                 ->{SUBVERSION_CHECKEDOUT_MPC}  <- SVN Revision of MPC checked out
#                 ->{SUBVERSION_CHECKEDOUT_OPENDDS}  <- SVN Revision of OpenDDS checked out
#                 ->{CVS_TIMESTAMP}    <- The time AFTER the last cvs operation (PRISMTECH still use some cvs, please leave)

my %builds;

# %groups->{$name} <- list of builds for $name

my %groups;

my @ordered;

my @nogroup;

my $orange_default = 24; # 1 day old before orange coloured build.
my $red_default = 48;    # 2 days old before red coloured build.
my $keep_default = 2;    # Scoreboard only uses the most recent build anyway (and possably
                         # the previous oldest copy during the scoreboard update time), for more
                         # consult the actual build machine where we store multiple builds.
my $sched_file = "";
my @days = ( "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" );

# Do not set the value of this variable here.  Instead, edit the
# XML file for the scoreboard, and put the text in between the
# <preamble> </preamble> tags.
our $preamble = "";

our $verbose = 0;
our $scoreboard_title = 'Scoreboard';
our $use_local = 0;

our $use_build_logs = 0;
our $junit_xml_output = 0;

our $custom_css = "";

our $log_prefix = "";

my $build_instructions = "<br><p>Instructions for setting up your
own scoreboard are
<A HREF=\"https://github.com/DOCGroup/autobuild/blob/master/README.md\">
here</A>.\n";

###############################################################################
#
# load_build_list
#
# Reads the list of builds from a file
#
# Arguments:  $ - file to read
#
# Returns:    Nothing
#
###############################################################################
sub load_build_list ($)
{
    my $file = shift;

    print "Loading Build List\n" if ($verbose);

    my $parser = new ScoreboardParser;
    $parser->Parse ($file, \%builds, \@ordered);
}

###############################################################################
#
# build_index_page
#
# Reads and develops an index page
#
# Arguments:  $ - dir to read
# Arguments:  $ - file to read
#
# Returns:    Nothing
#
###############################################################################
sub build_index_page ($$)
{
    my $dir = shift;
    my $index = shift;
    my $filename = "$dir/index.html";

    my $indexhtml = new FileHandle;

    print "Generating index page\n" if ($verbose);

    unless ($indexhtml->open (">$filename")) {
        warn 'Could not create file: '.$filename." ".$_;
        return;
    }

    ### Print Header
    print $indexhtml "<!DOCTYPE html>\n";
    print $indexhtml "<html>\n<head>\n<title>Welcome to DOCGroup Distributed Scoreboard</title>\n";
    print $indexhtml "</head>\n";

    ### Start body

    print $indexhtml "<body bgcolor=white><center><h1>Welcome to DOCGroup Distributed Scoreboard\n</h1></center>\n<hr>\n";
    my $parser = new IndexParser;
    $parser->Parse ($index, \%builds);
    print $indexhtml "$preamble\n";
    print $indexhtml "\n<hr>\n";

    ### Failed Test Reports

    if (!$use_build_logs) {
        my $failed_tests = $dir . "/" . $log_prefix . "_Failed_Tests_By_Build.html";
        if (-e $failed_tests) {
            print $indexhtml "<br><a href=\"" . $log_prefix . "_Failed_Tests_By_Build.html\">Failed Test Brief Log By Build</a><br>\n";
        }

        $failed_tests = $dir . "/" . $log_prefix . "_Failed_Tests_By_Test.html";
        if (-e $failed_tests) {
            print $indexhtml "<br><a href=\"" . $log_prefix . "_Failed_Tests_By_Test.html\">Failed Test Brief Log By Test</a><br>\n";
        }
    }

    ### Print timestamp

    print $indexhtml '<br>Last updated at ' . get_time_str() . "<br>\n";

    ### Print the Footer

    print $indexhtml "</body>\n</html>\n";

    $indexhtml->close ();

    my $file = shift;

    print "Creating index page\n" if ($verbose);
}

###############################################################################
#
# build_group_hash
#
# Looks at all the groups specified and collects the builds together
#
# Arguments:  Nothing
#
# Returns:    Nothing
#
###############################################################################
sub build_group_hash ()
{
    print "Grouping builds\n" if ($verbose);

    foreach my $buildname (keys %builds) {
        if (defined $builds{$buildname}->{GROUP}) {
            push @{$groups{$builds{$buildname}{GROUP}}}, $buildname;
        }
        else {
            push @nogroup, $buildname;
        }
    }
}

###############################################################################
#
# query_latest
#
# Queries the web servers to figure out the latest build available and saves
# the list in LATEST_FILE and LATEST_TIME
#
# Arguments:  Nothing
#
# Returns:    Nothing
#
###############################################################################
sub query_latest ()
{
    print "Getting latest files\n" if ($verbose);

    foreach my $buildname (keys %builds) {
        my $latest = load_web_latest ($builds{$buildname}{URL});

        if (defined $latest && $latest =~ m/(...._.._.._.._..) /)
        {
            $builds{$buildname}{BASENAME} = $1;
        }
        else {
            print STDERR "    Error: Could not find latest.txt for $buildname\n";
            next;
        }

        if ($latest =~ m/Config: (\d+)/) {
            $builds{$buildname}{CONFIG_SECTION} = $1;
        }

        if ($latest =~ m/Setup: (\d+)-(\d+)-(\d+)/) {
            $builds{$buildname}{SETUP_SECTION} = $1;
            $builds{$buildname}{SETUP_ERRORS} = $2;
            $builds{$buildname}{SETUP_WARNINGS} = $3;
        }

        if ($latest =~ m/Compile: (\d+)-(\d+)-(\d+)/) {
            $builds{$buildname}{COMPILE_SECTION} = $1;
            $builds{$buildname}{COMPILE_ERRORS} = $2;
            $builds{$buildname}{COMPILE_WARNINGS} = $3;
        }

        if ($latest =~ m/Test: (\d+)-(\d+)-(\d+)/) {
            $builds{$buildname}{TEST_SECTION} = $1;
            $builds{$buildname}{TEST_ERRORS} = $2;
            $builds{$buildname}{TEST_WARNINGS} = $3;
        }

        if ($latest =~ m/Failures: (\d+)/) {
            $builds{$buildname}{SECTION_ERROR_SUBSECTIONS} = $1;
        }

        if ($latest =~ m/ACE: ([^ ]+)/) {
            $builds{$buildname}{SUBVERSION_CHECKEDOUT_ACE} = $1;
        }
        if ($latest =~ m/MPC: ([^ ]+)/) {
            $builds{$buildname}{SUBVERSION_CHECKEDOUT_MPC} = $1;
        }
        if ($latest =~ m/OpenDDS: ([^ ]+)/) {
            $builds{$buildname}{SUBVERSION_CHECKEDOUT_OPENDDS} = $1;
        }
        if ($latest =~ m/CVS: \"([^\"]+)\"/) {
            $builds{$buildname}{CVS_TIMESTAMP} = $1; ## PRISMTECH still use some cvs, please leave
        }
    }
}

###############################################################################
#
# query_status
#
# Queries the status links to figure out the latest status and stores in
# STATUS
#
# Arguments:  Nothing
#
# Returns:    Nothing
#
###############################################################################
sub query_status ()
{
    print "Getting status messages\n" if ($verbose);

    foreach my $buildname (keys %builds) {
        my $link = $builds{$buildname}{URL} . '/status.txt';
        if (defined $link) {
            print "    Status [$buildname] from $link\n" if ($verbose);

            my $ua = LWP::UserAgent->new;

            ### We are impatient, so don't wait more than 20 seconds for a
            ### response (the default was 180 seconds)
            $ua->timeout(20);

            my $request = HTTP::Request->new('GET', $link);
            my $response = $ua->request($request);

            if (!$response->is_success ()) {
                print "        No status for $buildname\n" if ($verbose);
                next;
            }

            my @contents = split /\n/, $response->content ();

            ### Now look for files

            foreach my $line (@contents) {
                if ($line =~ m/SCOREBOARD_STATUS\:(.*)$/) {
                    $builds{$buildname}{STATUS} = $1;
                }
            }
        }
    }
}

###############################################################################
#
# local_query_status
#
# Queries the status links to figure out the latest status and stores in
# STATUS
#
# Arguments:  Nothing
#
# Returns:    Nothing
#
###############################################################################
sub local_query_status ($)
{
    my $directory = shift;

    print "Getting status messages\n" if ($verbose);

    if (!-w $directory) {
        warn "Cannot write to $directory";
        return;
    }

    foreach my $buildname (keys %builds) {
        my $file_name = "$directory/$buildname/status.txt";
        my $file_handle = new FileHandle ($file_name, 'r');
        if (defined $file_handle) {

            print "    Status [$buildname] from $file_name\n" if ($verbose);

            while (<$file_handle>) {
                if ($_ =~ m/SCOREBOARD_STATUS\:(.*)$/) {
                    $builds{$buildname}{STATUS} = $1;
                }
            }
        }
else {
print STDERR "Error: Could not open file <$file_name>: $!\n";
}
    }
}

###############################################################################
#
# query_history
#
# Queries the history information and store it in
# FULL_HISTORY and CLEAN_HISTORY
#
# Arguments:  Nothing
#
# Returns:    Nothing
#
###############################################################################
sub query_history ()
{
    print "Getting history information\n" if ($verbose);

    foreach my $buildname (keys %builds) {
        my $full_link = 'http://teststat.remedy.nl/teststat/builds/' . $buildname . '.html';
        my $clean_link = 'http://teststat.remedy.nl/teststat/builds/clean_' . $buildname . '.html';
        if (defined $clean_link) {
            print "    Clean history [$buildname] from $full_link\n" if ($verbose);

            my $ua = LWP::UserAgent->new;

            ### We are impatient, so don't wait more than 20 seconds for a
            ### response (the default was 180 seconds)
            $ua->timeout(20);

            my $request = HTTP::Request->new('GET', $clean_link);
            my $response = $ua->request($request);

            if ($response->is_success ()) {
                $builds{$buildname}{CLEAN_HISTORY} = 1;
                # Assume we also have a full log when there is a clean one
                $builds{$buildname}{FULL_HISTORY} = 1;
            }
        }
        if (defined $full_link && !defined $builds{$buildname}{CLEAN_HISTORY}) {
            print "    Full history [$buildname] from $full_link\n" if ($verbose);

            my $ua = LWP::UserAgent->new;

            ### We are impatient, so don't wait more than 20 seconds for a
            ### response (the default was 180 seconds)
            $ua->timeout(20);

            my $request = HTTP::Request->new('GET', $full_link);
            my $response = $ua->request($request);

            if ($response->is_success ()) {
                $builds{$buildname}{FULL_HISTORY} = 1;
            }

        }
    }
}



###############################################################################
#
# load_web_latest
#
# Loads the latest.txt file from a web site.
#
# Arguments:  $ - The URI of the directory on the web
#
# Returns:    @ - Listing of the files in that directory
#
###############################################################################
sub load_web_latest ($)
{
    my $address = shift;

    print "    Loading latest from $address/latest.txt\n" if ($verbose);

    ### Check the address

    if ($address =~ m/^(http|https):\/\/[\w.]*(.*)/) {
        $address .= '/latest.txt';
    }
    else {
        warn "load_web_dir (): Badly formed http address";
        return '';
    }


    ### Request the web dir page

    my $ua = LWP::UserAgent->new;

    ### We are impatient, so don't wait more than 20 seconds for a
    ### response (the default was 180 seconds)
    $ua->timeout(20);

    my $request = HTTP::Request->new('GET', $address);
    my $response = $ua->request($request);

    if (!$response->is_success ()) {
        print "        ERROR: Could not retrieve latest.txt\n";
        return ();
    }

    ### Pull out the latest text

    return $response->content ();
}


###############################################################################
#
# decode_timestamp
#
# Decodes a YYYYMMDDHHMM timestamp
#
# Arguments:  $ - encoded timestamp
#
# Returns:    $ - timestamp description
#
###############################################################################
sub decode_timestamp ($)
{
    my $timestamp = shift;
    my $description = '';

    if ($timestamp =~ m/(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)_(\d\d)/) {

  my $buildtime = timegm (0, $5, $4, $3, $2 - 1, $1);
  $description = format_time($buildtime);
    }
    else {
        warn 'Unable to decode time';
        $description = 'Unknown Time';
    }

    return $description;
}

###############################################################################
#
# update_cache
#
# Updates the local cache
#
# Arguments:  $ - directory to place files in
#
# Returns:    Nothing
#
###############################################################################
sub update_cache ($)
{
    my $directory = shift;
    my %failed_tests_by_test;
    my $failed_tests_by_test_ref = \%failed_tests_by_test;


    print "Updating Local Cache\n" if ($verbose);

    if (!-w $directory) {
        warn "Cannot write to $directory";
        return;
    }

    foreach my $buildname (keys %builds) {
        ### Check to see if we had problems.  If there is no basename,
        ### we had problems downloading.
        if (!defined $builds{$buildname}{BASENAME}) {
            next;
        }

        ### Do we need to update the local cache or do we work
        ### with the storage of the build itself?
        if ((!$use_build_logs) || (defined $builds{$buildname}{CACHE})) {
            my $basename = $builds{$buildname}{BASENAME};
            my $address = $builds{$buildname}{URL} . "/" . $builds{$buildname}{BASENAME} . ".txt";

            my $filename = $builds{$buildname}{BASENAME} . '.txt';

            print "    Looking at $buildname\n" if ($verbose);

            mkpath "$directory/$buildname";

            if (! -r "$directory/$buildname/$filename") {
                print "        Downloading\n" if ($verbose);
                my $ua = LWP::UserAgent->new;
                my $request = HTTP::Request->new('GET', $address);
                my $response = $ua->request($request, "$directory/$buildname/$filename");

                if (!$response->is_success ()) {
                    warn "WARNING: Unable to download $address\n";
                    next;
                }

                print "        Prettifying\n" if($verbose);
                Prettify::Process ("$directory/$buildname/$filename", $buildname, $failed_tests_by_test_ref, $use_build_logs, $builds{$buildname}->{DIFFROOT}, "$directory/$log_prefix");
            }
        }
    }

    my $failed_tests_by_test_file_name = $directory  . "/" . $log_prefix .  "_Failed_Tests_By_Test.html";
    my $failed_tests_by_test_file = new FileHandle ($failed_tests_by_test_file_name, 'w');
    my $title = "Failed Test Brief Log By Test";
    print {$failed_tests_by_test_file} "<h1>$title</h1>\n";

    while (my ($k, $v) = each %failed_tests_by_test) {
        print {$failed_tests_by_test_file} "<hr><h2>$k</h2><hr>\n";
        print {$failed_tests_by_test_file} "$v<br>\n";
    }
}

###############################################################################
#
# local_update_cache
#
# Updates the local cache
#
# Arguments:  $ - directory to place files in
#
# Returns:    Nothing
#
###############################################################################
sub local_update_cache ($)
{
    my $directory = shift;
    my %failed_tests_by_test;
    my $failed_tests_by_test_ref = \%failed_tests_by_test;

    print "Updating Local Cache\n" if ($verbose);

    if (!-w $directory) {
        warn "Cannot write to $directory";
        return;
    }

    my $failed_tests = $directory  . "/" . $log_prefix . "_Failed_Tests_By_Build.html";
    if (-e $failed_tests) {
        unlink $failed_tests;
    }

    $failed_tests = $directory . "/" . $log_prefix . "_Failed_Tests_By_Test.html";
    if (-e $failed_tests) {
        unlink $failed_tests;
    }

    foreach my $buildname (keys %builds) {
        my $keep = $keep_default;
        my @existing;

        print "    Looking at $buildname\n" if ($verbose);

        # Check if URL was given
        if (defined $builds{$buildname}->{URL}) {
            #Pull remote build into local cache
            #This will only pull the "latest", under the assumption that
            #scoreboard.pl is running often enough to pick up all the desired
            #builds.
            mkpath ("$directory/$buildname") unless -d "$directory/$buildname";
            my $ua = LWP::UserAgent->new;
            my $address = "$builds{$buildname}->{URL}/status.txt";
            $ua->timeout(20);
            my $request = HTTP::Request->new('GET', $address);
            my $response = $ua->request($request,
                                        "$directory/$buildname/status.txt");
            if (!$response->is_success ()) {
                print "        No status for $buildname\n" if ($verbose);
            }
            my $latest = load_web_latest ($builds{$buildname}->{URL});
            if (defined $latest && $latest =~ /^(...._.._.._.._..) /) {
                my $basename = $1;
                my $fn = "$directory/$buildname/$basename.txt";
                if (! -r $fn) {
                    print "        Downloading\n" if ($verbose);
                    $address = "$builds{$buildname}->{URL}/$basename.txt";
                    $request = HTTP::Request->new('GET', $address);
                    $response = $ua->request($request, $fn);
                    if (!$response->is_success ()) {
                        warn "WARNING: Unable to download $address\n";
                        next;
                    }
                    open (POST, ">$directory/$buildname/post");
                    close POST;
                }
            }
        } else {
            $builds{$buildname}{URL} = $buildname;
        }

        # Check for new logs

        my $cache_dir = $directory . "/" . $buildname;
        my $dh = new DirHandle ($cache_dir);

        # Load the directory contents into the @existing array

        if (!defined $dh) {
            print STDERR "Error: Could not read $cache_dir\n";
            next;
        }

        while (defined($_ = $dh->read)) {
            if ($_ =~ m/^(...._.._.._.._..)\.txt/) {
                push @existing, "$cache_dir/$1";
            }
        }
        undef $dh;

        # Find any new logs to make pretty
        # We do this in oldest to newest order since the
        # Prettify Process will update the latest.txt file
        @existing = sort @existing;
        my $updated = 0;

        # A trigger file to tells the scoreboard that the log is complete
        # The reason for this that that there is a race condition where the
        # .txt file exist but not be competely copied.  There is a new
        # copy subcommand to process_logs that creates this trigger file
        # after the copy is complete, but doing it here works even if
        # the autobuild uses move, just delayed one iteration.
        my $triggerfile = "$directory/$buildname/post";
        my $post = 0;
        if ( -e $triggerfile ) {
            $post = 1;
            unlink $triggerfile;
        }
        print "        in local_update_cache, post=$post\n" if $verbose;

        # Get info from the latest build
        my $file_name1 = "$directory/$buildname/latest.txt";
        my $file_handle1 = new FileHandle ($file_name1, 'r');
        my $latest_basename = "";
        if (defined $file_handle1) {
            while (<$file_handle1>) {
                if ($_ =~ m/(...._.._.._.._..) /) {
                     $latest_basename = $1;
                }
            }
        }
        undef $file_handle1;

        foreach my $file (@existing) {
            if ( -e $file . "_Totals.html" || $post == 1 ) {
                # skip scenario when Failed Test Log is not needed, and all other logs already exist
                if (!($use_build_logs && (-e $file . "_Totals.html"))) {
                    # process only the latest text file if logs already exist
                    next if ((-e $file . "_Totals.html") && !($latest_basename eq substr($file, -length($latest_basename))));
                    print "        Prettifying $file.txt\n" if($verbose);
                    Prettify::Process ("$file.txt", $buildname, $failed_tests_by_test_ref, $use_build_logs, $builds{$buildname}->{DIFFROOT}, "$directory/$log_prefix", (-e $file . "_Totals.html"));
                    $updated++;
                }
            } else {
                # Create the triggerfile for the next time we run
                open(FH, ">$triggerfile");
                close(FH);
                last;
            }
        }

        # Remove the latest $keep logs from the list
        @existing = reverse sort @existing;
        if (defined $builds{$buildname}->{KEEP}) {
            $keep = $builds{$buildname}->{KEEP};
        }

        for (my $i = 0; $i < $keep; ++$i) {
            shift @existing;
        }

        # Delete anything left in the list

        foreach my $file (@existing) {
            print "        Removing $file files\n" if ($verbose);
            unlink $file . ".txt";
            unlink $file . "_Full.html";
            unlink $file . "_Brief.html";
            unlink $file . "_Totals.html";
            unlink $file . "_Config.html";
            $updated++;
        }

        # Update the index file, since it may have changed
        if ($updated || $post) {
            print "        Creating new index\n" if ($verbose);
            my $diffRoot = $builds{$buildname}->{DIFFROOT};
            utility::index_logs ("$directory/$buildname", $buildname, $diffRoot);
        }

        # Get info from the latest build
        my $file_name = "$directory/$buildname/latest.txt";
        my $file_handle = new FileHandle ($file_name, 'r');

        my $latest;
        if (defined $file_handle) {

            print "        Loading latest from $file_name\n" if ($verbose);

            while (<$file_handle>) {
                if ($_ =~ m/(...._.._.._.._..) /) {
                     $builds{$buildname}{BASENAME} = $1;
                    $latest = $_;
                }
            }
        }
        undef $file_handle;

        if (!defined $latest) {
            print STDERR "    Error: Could not find latest.txt for $buildname\n";
            next;
        }

        if ($latest =~ m/Config: (\d+)/) {
            $builds{$buildname}{CONFIG_SECTION} = $1;
        }

        if ($latest =~ m/Setup: (\d+)-(\d+)-(\d+)/) {
            $builds{$buildname}{SETUP_SECTION} = $1;
            $builds{$buildname}{SETUP_ERRORS} = $2;
            $builds{$buildname}{SETUP_WARNINGS} = $3;
        }

        if ($latest =~ m/Compile: (\d+)-(\d+)-(\d+)/) {
            $builds{$buildname}{COMPILE_SECTION} = $1;
            $builds{$buildname}{COMPILE_ERRORS} = $2;
            $builds{$buildname}{COMPILE_WARNINGS} = $3;
        }

        if ($latest =~ m/Test: (\d+)-(\d+)-(\d+)/) {
            $builds{$buildname}{TEST_SECTION} = $1;
            $builds{$buildname}{TEST_ERRORS} = $2;
            $builds{$buildname}{TEST_WARNINGS} = $3;
        }

        if ($latest =~ m/Failures: (\d+)/) {
            $builds{$buildname}{SECTION_ERROR_SUBSECTIONS} = $1;
        }

        if ($latest =~ m/ACE: ([^ ]+)/) {
            $builds{$buildname}{SUBVERSION_CHECKEDOUT_ACE} = $1;
        }
        if ($latest =~ m/MPC: ([^ ]+)/) {
            $builds{$buildname}{SUBVERSION_CHECKEDOUT_MPC} = $1;
        }
        if ($latest =~ m/OpenDDS: ([^ ]+)/) {
            $builds{$buildname}{SUBVERSION_CHECKEDOUT_OPENDDS} = $1;
        }
        if ($latest =~ m/CVS: \"([^\"]+)\"/) {
            $builds{$buildname}{CVS_TIMESTAMP} = $1; ## PRISMTECH still use some cvs, please leave
        }
    }

    my $size = keys %failed_tests_by_test;
    my $failed_tests_by_test_file;
    if ($size > 0) {
        my $failed_tests_by_test_file_name = $directory  . "/" . $log_prefix .  "_Failed_Tests_By_Test.html";
        $failed_tests_by_test_file = new FileHandle ($failed_tests_by_test_file_name, 'w');
        my $title = "Failed Test Brief Log By Test";
        print {$failed_tests_by_test_file} "<h1>$title</h1>\n";
    }

    while (my ($k, $v) = each %failed_tests_by_test) {
        print {$failed_tests_by_test_file} "<hr><h2>$k</h2>\n";
        print {$failed_tests_by_test_file} "$v<br>\n";
    }
}


###############################################################################
#
# clean_cache
#
# Cleans the local cache
#
# Arguments:  $ - directory to clean
#
# Returns:    Nothing
#
###############################################################################
sub clean_cache ($)
{
    my $directory = shift;

    print "Cleaning Local Cache\n" if ($verbose);

    if (!-w $directory) {
        warn "Cannot write to $directory";
        return;
    }

    my $failed_tests = $directory . "/" . $log_prefix . "_Failed_Tests_By_Build.html";
    if (-e $failed_tests) {
        unlink $failed_tests;
    }

    $failed_tests = $directory . "/" . $log_prefix . "_Failed_Tests_By_Test.html";
    if (-e $failed_tests) {
        unlink $failed_tests;
    }

    foreach my $buildname (keys %builds) {
        ### Do we use the local cache or do we work
        ### with the storage of the build itself?
        if ((!$use_build_logs) || (defined $builds{$buildname}{CACHE})) {
            my $keep = $keep_default;
            my @existing;

            print "    Looking at $buildname\n" if ($verbose);

            my $cache_dir = $directory . "/" . $buildname;
            my $dh = new DirHandle ($cache_dir);

            # Load the directory contents into the @existing array

            if (!defined $dh) {
                print STDERR "Error: Could not read $directory\n";
                return 0;
            }

            while (defined($_ = $dh->read)) {
                if ($_ =~ m/^(...._.._.._.._..)\.txt/) {
                    push @existing, "$cache_dir/$1";
                }
            }
            undef $dh;

            @existing = reverse sort @existing;

            # Remove the latest $keep logs from the list
            if (defined $builds{$buildname}->{KEEP}) {
                $keep = $builds{$buildname}->{KEEP};
            }

            for (my $i = 0; $i < $keep; ++$i) {
                shift @existing;
            }

            # Delete anything left in the list

            foreach my $file (@existing) {
                print "        Removing $file files\n" if ($verbose);
                unlink $file . ".txt";
                unlink $file . "_Full.html";
                unlink $file . "_Brief.html";
                unlink $file . "_Totals.html";
                unlink $file . "_Config.html";
            }
        }
    }
}

sub numerically { $a <=> $b }

###############################################################################
#
# timestamp_class
#
# Decodes a YYYYMMDDHHMM timestamp and figures out the class
#
# Arguments:  $ - encoded timestamp
#             $ - orange hours
#             $ - red hours
#             $ - build name
#
# Returns:    $ - class
#
###############################################################################
sub timestamp_class ($$$$)
{
    my $timestamp = shift;
    my $warning = shift;
    my $late = shift;
    my $buildname = shift;

    if ($timestamp =~ m/(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)_(\d\d)/) {
        my $buildtime = timegm (0, $5, $4, $3, $2 - 1, $1);

        my $nowtime = timegm (gmtime());

        if ($sched_file ne "") {
            my $file_handle = new FileHandle ($sched_file, 'r');
            if (!defined $file_handle) {
                print STDERR "Error: Could not open file <$sched_file>: $!\n";
                return 0;
            }

            my @daylist;
            my $acceptit=0;
            while (<$file_handle>) {
                if ( $_ =~ /\[$buildname\]/ ) {
                    $acceptit = 1;
                    next;
                }
                if ( $_ =~ /^\s*\[/ ) {
                    $acceptit = 0;
                }
                if ( $acceptit ) {
                    my @cmd = split;
                    my $len = @cmd;
                    if ( $len > 0 && $cmd[0] eq "runon" ) {
                        my $arg;
                        my $day;
                        foreach $arg (@cmd[1..($len-1)]) {
                            foreach $day (0..6) {
                                if ( $arg eq $days[$day] ) {
                                    push (@daylist, $day);
                                    push (@daylist, $day + 7);
                                    push (@daylist, $day + 14);
                                }
                            }
                        }
                    }
                }
            }
            @daylist = sort numerically @daylist;

            if ( @daylist > 0 ) {
                my $dow;
                $dow = (gmtime($buildtime))[6] + 7;
                my $next_day;
                my $prev_day;
                my $i;
                foreach $i (@daylist) {
                    $next_day = $i;
                    if ( $next_day > $dow ) { last; }
                    $prev_day = $next_day;
                }
                my $addhours = ($next_day - $prev_day - 1) * 24;
                $late += $addhours;
                $warning += $addhours;
            }
        }

        if ($nowtime - $buildtime > (60 * 60 * $late)) {
            return 'late';
        }

        if ($nowtime - $buildtime > (60 * 60 * $warning)) {
            return 'warning';
        }

        if ($nowtime - $buildtime < (60 * 30)) {
            return 'new';
        }

        return 'normal'
    }

    warn 'Unable to decode time';

    return 'gray';
}

###############################################################################
#
# timestamp_color
#
# Decodes a YYYYMMDDHHMM timestamp and figures out the color
#
# Arguments:  $ - encoded timestamp
#             $ - orange hours
#             $ - red hours
#             $ - build name
#
# Returns:    $ - color
#
###############################################################################
sub timestamp_color ($$$$)
{
    my $timestamp = shift;
    my $orange = shift;
    my $red = shift;
    my $buildname = shift;

    if ($timestamp =~ m/(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)_(\d\d)/) {
        my $buildtime = timegm (0, $5, $4, $3, $2 - 1, $1);

        my $nowtime = timegm (gmtime());

        if ($sched_file ne "") {
            my $file_handle = new FileHandle ($sched_file, 'r');
            if (!defined $file_handle) {
                print STDERR "Error: Could not open file <$sched_file>: $!\n";
                return 0;
            }

            my @daylist;
            my $acceptit=0;
            while (<$file_handle>) {
                if ( $_ =~ /\[$buildname\]/ ) {
                    $acceptit = 1;
                    next;
                }
                if ( $_ =~ /^\s*\[/ ) {
                    $acceptit = 0;
                }
                if ( $acceptit ) {
                    my @cmd = split;
                    my $len = @cmd;
                    if ( $len > 0 && $cmd[0] eq "runon" ) {
                        my $arg;
                        my $day;
                        foreach $arg (@cmd[1..($len-1)]) {
                            foreach $day (0..6) {
                                if ( $arg eq $days[$day] ) {
                                    push (@daylist, $day);
                                    push (@daylist, $day + 7);
                                    push (@daylist, $day + 14);
                                }
                            }
                        }
                    }
                }
            }
            @daylist = sort numerically @daylist;

            if ( @daylist > 0 ) {
                my $dow;
                $dow = (gmtime($buildtime))[6] + 7;
                my $next_day;
                my $prev_day;
                my $i;
                foreach $i (@daylist) {
                    $next_day = $i;
                    if ( $next_day > $dow ) { last; }
                    $prev_day = $next_day;
                }
                my $addhours = ($next_day - $prev_day - 1) * 24;
                $red += $addhours;
                $orange += $addhours;
            }
        }

        if ($nowtime - $buildtime > (60 * 60 * $red)) {
            return 'red';
        }

        if ($nowtime - $buildtime > (60 * 60 * $orange)) {
            return 'orange';
        }

        return 'white'
    }

    warn 'Unable to decode time';

    return 'gray';
}


###############################################################################
#
# found_section
#
# Returns 1 if the file contains a section
#
# Arguments:  $ - input file
#             $ - type (config)
#
# Returns:    Nothing
#
###############################################################################
sub found_section ($$)
{
    my $file = shift;
    my $type = shift;

    my $found = 0;

    my $results = new FileHandle;

    unless ($results->open ("<$file")) {
        print STDERR 'Error: Could not open '.$file.": $!\n";
        return 0;
    }

    while (<$results>) {
        if ($type eq 'config') {
            if (m/#config/) {
                $found = 1;
                last;
            }
        }
    }
    $results->close ();

    return $found;
}



###############################################################################
#
# update_html
#
# Runs make_pretty on a bunch of files and creates an html file.
#
# Arguments:  $ - directory
#             $ - outside html file name
# Returns:    Nothing
#
###############################################################################
sub update_html ($$$)
{
    my $dir = shift;
    my $out_file = shift;
    my $rss_file = shift;

    my $indexhtml = new FileHandle;

    print "Generating Scoreboard\n" if ($verbose);

    unless ($indexhtml->open (">$out_file")) {
        warn 'Could not create file: '.$out_file." ".$_;
        return;
    }

    ### Print Header
    print $indexhtml "<!DOCTYPE html>\n";
    print $indexhtml "<html>\n<head>\n<title>$scoreboard_title</title>\n";
    print $indexhtml "<style>\n";
    if (defined $main::opt_y) {
        print $indexhtml $custom_css;
    } else {
        print $indexhtml "table { border-collapse: collapse; }\n";
        print $indexhtml "th { background: #ddd; }\n";
        print $indexhtml "td { padding: inherit 5px; }\n";
        print $indexhtml ".name { min-width: 400px; }\n";
        print $indexhtml ".time { min-width: 105px; }\n";
        print $indexhtml ".rev { min-width: 70px; }\n";
        print $indexhtml ".fullbrief { min-width: 85px; }\n";
        print $indexhtml ".status { min-width: 50px; }\n";
        print $indexhtml ".new { font-weight: bold; }\n";
        print $indexhtml ".normal { background: white; }\n";
        print $indexhtml ".warning { background: orange; }\n";
        print $indexhtml ".late { background: red; }\n";
        print $indexhtml ".disabled { background: gray; }\n";
    }
    print $indexhtml "</style>\n";

    if ($rss_file ne "") {
        print $indexhtml "<link rel=\"alternate\" title=\"$scoreboard_title RSS\" href=\"$rss_file\" type=\"application/rss+xml\">\n";
    }

    print $indexhtml "</head>\n";

    ### Start body
    print $indexhtml "<body bgcolor=white>\n";
    print $indexhtml "$preamble\n";

    ### Print tables (first the empty one)

    update_html_table ($dir, $indexhtml, undef) if ($#nogroup >= 0);
    foreach my $group (sort keys %groups) {
        update_html_table ($dir, $indexhtml, $group);
    }

    ### Failed Test Reports

    if (!$use_build_logs) {
        my $failed_tests = $dir . "/" . $log_prefix . "_Failed_Tests_By_Build.html";
        if (-e $failed_tests) {
            print $indexhtml "<br><a href=\"" . $log_prefix . "_Failed_Tests_By_Build.html\">Failed Test Brief Log By Build</a><br>\n";
        }

        $failed_tests = $dir . "/" . $log_prefix . "_Failed_Tests_By_Test.html";
        if (-e $failed_tests) {
            print $indexhtml "<br><a href=\"" . $log_prefix . "_Failed_Tests_By_Test.html\">Failed Test Brief Log By Test</a><br>\n";
        }
    }

    ### Print timestamp

    print $indexhtml '<br>Last updated at ' . get_time_str() . "<br>\n";

    ### Print the Footer

    print $indexhtml "</body>\n</html>\n";

    $indexhtml->close ();
}


###############################################################################
#
# update_html_table
#
# helper for update_html that prints a single table
#
# Arguments:  $ - directory
#             $ - output file handle
#             $ - group name
#
# Returns:    Nothing
#
###############################################################################
sub update_html_table ($$@)
{
    my $dir = shift;
    my $indexhtml = shift;
    my $name = shift;
    my $havestatus = 0;
    my $havemanual = 0;
    my $havepdf = 0;
    my $haveps = 0;
    my $havehtml = 0;
    my $havesnapshot = 0;
    my $havehistory = 0;
    my $havesponsor = 0;
    my $linktarget = "";
    my @builds;

    ### Table

    # check to see if we are doing the "NONE" group
    if (!defined $name) {
        print "    Building table for ungrouped\n" if ($verbose);
        my %temp;
        @temp{@nogroup} = ();
        foreach my $build (@ordered) {
            if(exists $temp{$build}) {
                push(@builds, $build);
            }
        }
    }
    else {
        print "    Building table for group $name\n" if ($verbose);
        @builds = sort @{$groups{$name}};
        print $indexhtml "<h2><a name=\"$name\">$name</a></h2>\n";
    }

    foreach my $buildname (@builds) {
        if (defined $builds{$buildname}->{STATUS}) {
            $havestatus = 1;
        }
        if (defined $builds{$buildname}->{MANUAL_LINK}) {
            $havemanual = 1;
        }
        if (defined $builds{$buildname}->{PDF}) {
            $havepdf = 1;
        }
        if (defined $builds{$buildname}->{PS}) {
            $haveps = 1;
        }
        if (defined $builds{$buildname}->{HTML}) {
            $havehtml = 1;
        }
        if (defined $builds{$buildname}->{BUILD_SPONSOR}) {
            $havesponsor = 1;
        }
        if (defined $builds{$buildname}->{SNAPSHOT}) {
            $havesnapshot = 1;
        }
        if (defined $builds{$buildname}->{FULL_HISTORY} ||
            defined $builds{$buildname}->{CLEAN_HISTORY}) {
            $havehistory = 1;
        }
    }

    if (defined $main::opt_n) {
        $linktarget = "target=\"_blank\""
    }

    print $indexhtml "<div class='buildtable'>\n";
    print $indexhtml "<table border=1>\n";
    print $indexhtml "<tr>\n";
    print $indexhtml "<th class='name'>Build Name</th><th class='time'>Last Finished</th>";
    print $indexhtml "<th class='rev'>Rev</th>";
    print $indexhtml "<th>Config</th><th class='fullbrief'>Setup</th><th class='fullbrief'>Compile</th><th class='fullbrief'>Tests</th><th>Failures</th>";
    print $indexhtml "<th>Manual</th>" if ($havemanual);
    print $indexhtml "<th class='status'>Status</th>" if ($havestatus);
    print $indexhtml "<th>Build <br>Sponsor</th>" if ($havesponsor);
    print $indexhtml "<th>History</th>" if ($havehistory);
    # New entries
    print $indexhtml "<th>PDF</th>" if ($havepdf);
    print $indexhtml "<th>PS</th>" if ($haveps);
    print $indexhtml "<th>HTML</th>" if ($havehtml);
    print $indexhtml "<th>SNAPSHOT</th>" if ($havesnapshot);
    print $indexhtml "\n</tr>\n";
    print $indexhtml "\n";

    foreach my $buildname (@builds) {
        print "        Looking at $buildname\n" if ($verbose);

        print $indexhtml '<tr><td>';

        if (defined $builds{$buildname}->{URL}) {
            print $indexhtml "<a href=\"".$builds{$buildname}->{URL} ."/index.html\" $linktarget>" ;
            print $indexhtml $buildname;
            print $indexhtml "</a> ";
        }
        else {
            print $indexhtml $buildname;
        }

        if (defined $builds{$buildname}->{BASENAME}) {
            my $basename = $builds{$buildname}->{BASENAME};

            ### Do we use the local cache or do we work
            ### with the storage of the build itself?
            my $webfile;
            if ((!$use_build_logs) || (defined $builds{$buildname}{CACHE})) {
                $webfile = "$buildname/$basename";
            } else {
                $webfile = $builds{$buildname}->{URL}."/$basename";
            }

            my $orange = $orange_default;
            my $red = $red_default;

            if (defined $builds{$buildname}->{ORANGE_TIME}) {
                $orange = $builds{$buildname}->{ORANGE_TIME};
            }

            if (defined $builds{$buildname}->{RED_TIME}) {
                $red = $builds{$buildname}->{RED_TIME};
            }

            my $class;

            if (defined $builds{$buildname}->{STATUS} &&
                $builds{$buildname}->{STATUS} =~ /Disabled\r?/) {
                $class = 'disabled';
            }
            else {
                $class = timestamp_class ($basename, $orange, $red, $buildname);
            }
            print $indexhtml '<td class=', $class, '>',decode_timestamp ($basename);

            my $diffRev = '';
            if (defined $builds{$buildname}->{SUBVERSION_CHECKEDOUT_OPENDDS} &&
                !($builds{$buildname}->{SUBVERSION_CHECKEDOUT_OPENDDS} =~ /None/)) {
                $diffRev = $builds{$buildname}->{SUBVERSION_CHECKEDOUT_OPENDDS};
            }
            elsif (defined $builds{$buildname}->{SUBVERSION_CHECKEDOUT_ACE}) {
                $diffRev = $builds{$buildname}->{SUBVERSION_CHECKEDOUT_ACE};
            }
            else {
                $diffRev = 'None';
            }
            my $diffRoot = $builds{$buildname}->{DIFFROOT};
            # If we have a diff revision, and a diffroot URL, show a link
            if (($diffRev !~ /None/) && ($diffRoot)) {
              my $url = $diffRoot . $diffRev;
              my $link = "<a href='$url' $linktarget>$diffRev</a>";
              print $indexhtml "<td class='$class'>&nbsp;$link&nbsp;</td>";
            } else {
              print $indexhtml "<td class='$class'>&nbsp;$diffRev&nbsp;</td>";
            }

            print $indexhtml '<td>';
            if (defined $builds{$buildname}->{CONFIG_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Config.html\" $linktarget>Config</a>] ";
            }
            else {
                print $indexhtml "&nbsp;";
            }

            my $color;
            if (!defined $builds{$buildname}->{SETUP_SECTION}) {
                $color = 'white';
                $class = 'normal';
            }
            elsif ($builds{$buildname}->{SETUP_ERRORS} > 0) {
                $color = 'red';
                $class = 'error';
            }
            elsif ($builds{$buildname}->{SETUP_WARNINGS} > 0) {
                $color = 'orange';
                $class = 'warning';
            }
            else {
                $color = 'lime';
                $class = 'good';
            }

            print $indexhtml "<td bgcolor=$color class=\"$class\">";
            if (defined $builds{$buildname}->{SETUP_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . $builds{$buildname}->{SETUP_SECTION} . "\" $linktarget>Full</a>] ";
                if ($builds{$buildname}->{SETUP_ERRORS} + $builds{$buildname}->{SETUP_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . $builds{$buildname}->{SETUP_SECTION} . "\" $linktarget>Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined $builds{$buildname}->{COMPILE_SECTION}) {
                $color = 'white';
                $class = 'normal';
            }
            elsif ($builds{$buildname}->{COMPILE_ERRORS} > 0) {
                $color = 'red';
                $class = 'error';
            }
            elsif ($builds{$buildname}->{COMPILE_WARNINGS} > 0) {
                $color = 'orange';
                $class = 'warning';
            }
            else {
                $color = 'lime';
                $class = 'good';
            }

            print $indexhtml "<td bgcolor=$color class=\"$class\">";
            if (defined $builds{$buildname}->{COMPILE_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . $builds{$buildname}->{COMPILE_SECTION} . "\" $linktarget>Full</a>] ";
                if ($builds{$buildname}->{COMPILE_ERRORS} + $builds{$buildname}->{COMPILE_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . $builds{$buildname}->{COMPILE_SECTION} . "\" $linktarget>Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined $builds{$buildname}->{TEST_SECTION}) {
                $color = 'white';
                $class = 'normal';
            }
            elsif ($builds{$buildname}->{TEST_ERRORS} > 0) {
                $color = 'red';
                $class = 'error';
            }
            elsif ($builds{$buildname}->{TEST_WARNINGS} > 0) {
                $color = 'orange';
                $class = 'warning';
            }
            else {
                $color = 'lime';
                $class = 'good';
            }

            print $indexhtml "<TD bgcolor=$color class=\"$class\">";
            if (defined $builds{$buildname}->{TEST_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . $builds{$buildname}->{TEST_SECTION} . "\" $linktarget>Full</a>] ";
                if ($builds{$buildname}->{TEST_ERRORS} + $builds{$buildname}->{TEST_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . $builds{$buildname}->{TEST_SECTION} . "\" $linktarget>Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }
            if (defined $builds{$buildname}->{SECTION_ERROR_SUBSECTIONS}) {
                if ($builds{$buildname}->{SECTION_ERROR_SUBSECTIONS} > 0) {
                    $color = 'red';
                    $class = 'error';
                }
                else {
                    $color = 'lime';
                    $class = 'good';
                }
                print $indexhtml "<TD bgcolor=$color class=\"$class\">";
                print $indexhtml $builds{$buildname}->{SECTION_ERROR_SUBSECTIONS};
            }
            else {
                print $indexhtml "<TD>";
                print $indexhtml "&nbsp;";
            }
        }
        else {
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Time
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Rev
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Config
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # CVS
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Compiler
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Tests
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Subsections with Errors
        }


        if ($havemanual) {
            print $indexhtml "<td align=center>";
            if (defined $builds{$buildname}->{MANUAL_LINK}) {
                print $indexhtml "<input type=\"button\" value=\"Start\" ";
                print $indexhtml "onclick=\"window.location.href='";
                print $indexhtml $builds{$buildname}->{MANUAL_LINK};
                print $indexhtml "'\">";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }
        if ($havestatus) {
            print $indexhtml "<td>";
            if (defined $builds{$buildname}->{STATUS}) {
                print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "/status.txt\" $linktarget\>";
                print $indexhtml $builds{$buildname}->{STATUS};
                print $indexhtml "</a>";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }

        if ($havepdf) {
            print $indexhtml "<td>";
            if (defined $builds{$buildname}->{PDF}) {
                print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{PDF}, "\" $linktarget\>";
                print $indexhtml "pdf</a>";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }

        if ($haveps) {
            print $indexhtml "<td>";
            if (defined $builds{$buildname}->{PS}) {
                print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{PS}, "\" $linktarget\>";
                print $indexhtml "ps</a>";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }

        if ($havehtml) {
            print $indexhtml "<td>";
            if (defined $builds{$buildname}->{HTML}) {
                print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{HTML}, "\/index.html\" $linktarget\>";
                print $indexhtml "html</a>";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }

        if ($havesnapshot) {
            print $indexhtml "<td>";
            if (defined $builds{$buildname}->{SNAPSHOT}) {
                print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{SNAPSHOT}, "\" $linktarget\>";
                print $indexhtml "snapshot</a>";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }

        if ($havesponsor) {
            print $indexhtml "<td>";
            print $indexhtml "<a href=\"";
            if (defined $builds{$buildname}->{BUILD_SPONSOR_URL}) {
                print $indexhtml $builds{$buildname}->{BUILD_SPONSOR_URL}."";
            }
            print $indexhtml "\" target=\"_blank\">";
            if (defined $builds{$buildname}->{BUILD_SPONSOR}) {
                print $indexhtml $builds{$buildname}->{BUILD_SPONSOR}."";
            }
            print $indexhtml "</a>";
        }

        if ($havehistory) {
            print $indexhtml "<td>";
            if (defined $builds{$buildname}->{FULL_HISTORY}) {
                print $indexhtml "<a href=\"";
                print $indexhtml "http:\/\/teststat.remedy.nl\/teststat\/builds\/", $buildname, ".html";
                print $indexhtml "\" $linktarget>";
                print $indexhtml "Full";
                print $indexhtml "</a>";
                print $indexhtml " ";
            }
            if (defined $builds{$buildname}->{CLEAN_HISTORY}) {
                print $indexhtml "<a href=\"";
                print $indexhtml "http:\/\/teststat.remedy.nl\/teststat\/builds\/clean_", $buildname, ".html";
                print $indexhtml "\" $linktarget>";
                print $indexhtml "Clean";
                print $indexhtml "</a>";
            }
            print $indexhtml "</td>";
        }

        print $indexhtml "</tr>\n";
    }
    print $indexhtml "</table>\n";
    print $indexhtml "</div>\n";
}

## Eventually this should probably be shared code with autobuild.pl, but
## for now, implement it as a no-op which returns something which is undefined.
sub GetVariable ($)
{
    my $v = shift;
    if ($v eq 'junit_xml_output') {
        return $junit_xml_output;
    } else {
        my %a=();
        return $a{'UNDEFINED'};
    }
}


###############################################################################
#
# Reads lists of builds from different XML files and develops a
# integrated scoreboard. This is in addition to the individual
# scoreboards separately.  The names of the xml files have
# to be passed with the -j commandline option
#
# Arguments:  $ - Output directory and comma separate list of input files
#
# Returns:    Nothing
#
###############################################################################
sub build_integrated_page ($$)
{
    my $dir = shift;
    my $filelist = shift;

    unlink ("$dir/temp.xml");
    print "Build Integrated page\n" if ($verbose);

    if (!defined $filelist) {
      print "Need to specify with -j a comma separated list of input files";
      return;
    }

    my @file_list = split (',', $filelist);

    my $newfile = new FileHandle;

    unless ($newfile->open (">>$dir/temp.xml")) {
        print "could not create file $dir/temp.xml";
        return;
    }

    print $newfile "<INTEGRATED>\n";
    foreach my $file_list(@file_list) {
        my $file_handle = new FileHandle;
        # Get the filename without path and without extension
        my $filename = fileparse($file_list, ".xml");
        print $newfile "<build_$filename>\n";

        unless ($file_handle->open ("<$file_list")) {
          print "could not open file $file_list";
          return;
        }
        my @list = <$file_handle>;
        print $newfile @list;
        print $newfile "\n";
        close $file_handle;
    }
    print $newfile "\n</INTEGRATED>\n";

    close $newfile;

    my $parser = new IntegratedParser;
    $parser->Parse("$dir/temp.xml", \%builds);

    build_group_hash ();
    query_latest ();
    update_cache ($dir);
    clean_cache ($dir);
    query_status ();
    update_html ($dir,"$dir/integrated.html", "");
    unlink ("$dir/temp.xml");
}

###############################################################################
#
# Formats a time passed in as seconds in timegm() format.
#   Converts to local timezone if -l was specified to scoreboard.pl
#
###############################################################################
sub format_time
{
    my $time_in_secs = shift;
    my $use_long_format = shift;

    if ($use_local) {
      my @tmp = localtime($time_in_secs);
        my $hour = int($tmp[2]);
        my $ampm = ($hour >= 12 ? 'pm' : 'am');
        if ($hour > 12) {
          $hour -= 12;
    }
    elsif ($hour == 0) {
      $hour = 12;
    }
        my $year = int($tmp[5]) + 1900;
  if (defined $use_long_format && $use_long_format) {
      return sprintf("%d/%02d/%s %02d:%02d:%02d %s",
         int($tmp[4]) + 1, int($tmp[3]), $year, $hour, $tmp[1], $tmp[0], $ampm);
  } else {
      return sprintf("%02d/%02d %02d:%02d %s",
         int($tmp[4]) + 1, int($tmp[3]), $hour, $tmp[1], $ampm);

  }
    }
    return scalar(gmtime($time_in_secs));
}

###############################################################################
#
# Returns the time as either local time or UTC time depending on
# the -l command line option.
#
# Returns:    time
#
###############################################################################
sub get_time_str
{
    return format_time(timegm(gmtime()), 1);
}

###############################################################################
#
# Callbacks for commands
#

###############################################################################
###############################################################################

# Getopts
#
# You can do the following with this set os options.
# 1. You can generate the index page for the scoreboard
# 2. You can generate individual scoreboards for every subset ie. ace,
#    ace_future, or whatever
# 3. Generate an integrated page for #2 having all in one page. This
#    step is heavily hard coded for the scoreboard at the doc_group!
# Any one should be able to use #1 and #2. How to use them?
#
# 1: You can run like this
#
#    $ ./scoreboard.pl -v -d [path to the directory where you would like
#                             place your html files]
#                         -i [path to the file with the name where you
#                             have placed your index file in XML
#                             format]
#
#     This command just generates an index ie. index.html page from
#     whatever XML file that you pass through in -i option and places
#     it in the directory pointed by -d option. The option -v is for
#     verbose!
#
# 2: For generating individual html pages you can do this
#
#    $ ./scoreboard.pl -d [please see above for explanation]
#                      -f [name and path of the XML file that needs
#                          to be used as a meta-file for HTML
#                          generation]
#                      -o [name of the output file. The html file will
#                          be saved by this name and placed in the
#                          directory pointed by -d].

use vars qw/$opt_b $opt_c $opt_d $opt_f $opt_h $opt_i $opt_o $opt_v $opt_t $opt_z $opt_l $opt_r $opt_s $opt_k $opt_x $opt_j $opt_y $opt_n $opt_u/;

if (!getopts ('bcd:f:hi:o:t:vzlr:s:k:xj:y:n:u')
    || !defined $opt_d
    || defined $opt_h) {
    print "scoreboard.pl [-h] -d dir [-v] [-f file] [-i file] [-o file]\n",
          "              [-t title] [-z] [-l] [-r file] [-s file] [-c] [-x]\n",
          "              [-k num_logs] [-b] [-j filelist] [-y file] [-n] [-u]\n";
    print "\n";
    print "    -h         display this help\n";
    print "    -d         directory where the output files are placed \n";
    print "    -v         enable verbose debugging [def: only print errors]\n";
    print "    -f         file for which html should be generated \n";
    print "    -i         use <file> as the index file to generate Index page only\n";
    print "    -o         name of file where the output HTML files are placed\n";
    print "    -t         the title for the scoreboard (default Scoreboard)\n";
    print "    -z         Integrated page. Only the output directory is valid\n";
    print "    -l         Use local instead of UTC time\n";
    print "    -r         Specify name of RSS file\n";
    print "    -s         name of file where build schedule can be found\n";
    print "    -c         co-located directory, all files local in -d \n";
    print "    -k         number of logs to keep, default is $keep_default\n";
    print "    -x         'history' links generated\n";
    print "    -b         use the build URL for logfile refs; no local cache unless specified\n";
    print "    -j         comma separated list of input files which for an integrated page has to be generated\n";
    print "    -y         specify name of file with custom CSS styling";
    print "    -n         generate build links that open in new tab/window";
    print "    -u         generate *_JUnit.xml files";
    print "    All other options will be ignored  \n";
    exit (1);
}

my $index = "";
my $inp_file = "";
my $out_file = "";
my $rss_file = "";
my $dir = "html";

$index = $opt_i;

# Just generate Index page alone
$dir = $opt_d;

if (defined $opt_v) {
    print "Using verbose output\n";
    $verbose = 1;
}

if (defined $opt_t) {
    $scoreboard_title = $opt_t;
}

if (defined $opt_l) {
    print "Using localtime\n";
    $use_local = 1;
}

if (defined $opt_i){
$index = $opt_i;
print 'Running Index Page Update at ' . get_time_str() . "\n" if ($verbose);
build_index_page ($dir, $index);
exit (1);
}

if (defined $opt_b) {
    $use_build_logs = 1;
}

if (defined $opt_u) {
    $junit_xml_output = 1;
}

if (defined $opt_y) {
    open my $css_fh, '<', $opt_y or die "Can't open custom CSS file $opt_y";
    read $css_fh, $custom_css, -s $css_fh;
}

if (defined $opt_z) {
print 'Running Integrated Page Update at ' . get_time_str() . "\n" if ($verbose);
build_integrated_page ($dir, $opt_j);
exit (1);
}

$inp_file = $opt_f;

if (defined $opt_o) {
    $out_file = $opt_o;
    ($log_prefix = $out_file) =~ s/\.[^.]+$//;
}

if (defined $opt_r) {
    print "Using RSS file\n";
    $rss_file = $opt_r;
}

if (defined $opt_s) {
    print "Using schedule file\n";
    $sched_file = $opt_s;
}

if (defined $opt_k) {
    $keep_default = $opt_k;
}

load_build_list ($inp_file);
build_group_hash ();
if (defined $opt_c) {
  local_update_cache ($dir);
  local_query_status ($dir);
} else {
  query_latest ();
  update_cache ($dir);
  clean_cache ($dir);
  query_status ();
  if (defined $opt_x) {
    query_history ();
  }
}
update_html ($dir,"$dir/$out_file",$rss_file);

print 'Finished Scoreboard Update at ' . get_time_str() . "\n" if ($verbose);

###############################################################################
###############################################################################
