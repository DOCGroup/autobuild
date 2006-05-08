eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

# $Id$
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
use DirHandle;
use English;
use FileHandle;
use File::Path;
use Getopt::Std;
use LWP::UserAgent;
use Time::Local;

###############################################################################
# Big bad variables

# %builds->{$name}->{GROUP}            <- Group this build is in
#                 ->{URL}              <- Link to use for directing to all logs
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

my %builds;

# %groups->{$name} <- list of builds for $name

my %groups;

my @nogroup;

my $orange_default = 24;
my $red_default = 48;

# Do not set the value of this variable here.  Instead, edit the
# XML file for the scoreboard, and put the text in between the
# <preamble> </preamble> tags.
our $preamble = "";

our $verbose = 0;
our $scoreboard_title = 'Scoreboard';
our $use_local = 0;

my $build_instructions = "<br><p>Instructions for setting up your
own scoreboard are
<A HREF=\"http://cvs.doc.wustl.edu/viewcvs.cgi/*checkout*/README?cvsroot=autobuild\">
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
    $parser->Parse ($file, \%builds);
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
    print $indexhtml "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n";
    print $indexhtml "<html>\n<head>\n<title>Welcome to ACE+TAO+CIAO's Distributed Scoreboard</title>\n</head>\n";

    ### Start body

    print $indexhtml "<body bgcolor=white><center><h1>Welcome to ACE+TAO+CIAO's Distributed Scoreboard\n</h1></center>\n<hr>\n";
    my $parser = new IndexParser;
    $parser->Parse ($index, \%builds);
    print $indexhtml "$preamble\n";
    print $indexhtml "\n<hr>\n";

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
    print "Getting history inforamtin\n" if ($verbose);

    foreach my $buildname (keys %builds) {
        my $full_link = 'http://www.dre.vanderbilt.edu/~remedynl/teststat/builds/' . $buildname . '.log';
        my $clean_link = 'http://www.dre.vanderbilt.edu/~remedynl/teststat/builds/clean_' . $buildname . '.log';
        if (defined $full_link) {
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
        if (defined $clean_link) {
            print "    Clean history [$buildname] from $full_link\n" if ($verbose);

            my $ua = LWP::UserAgent->new;

            ### We are impatient, so don't wait more than 20 seconds for a
            ### response (the default was 180 seconds)
            $ua->timeout(20);

            my $request = HTTP::Request->new('GET', $clean_link);
            my $response = $ua->request($request);

            if (!$response->is_success ()) {
                $builds{$buildname}{CLEAN_HISTORY} = 1;
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

    if ($address =~ m/^http:\/\/[\w.]*(.*)/) {
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
            Prettify::Process ("$directory/$buildname/$filename");
        }
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
    my $keep = 5;

    print "Cleaning Local Cache\n" if ($verbose);

    if (!-w $directory) {
        warn "Cannot write to $directory";
        return;
    }

    foreach my $buildname (keys %builds) {
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



###############################################################################
#
# timestamp_color
#
# Decodes a YYYYMMDDHHMM timestamp and figures out the color
#
# Arguments:  $ - encoded timestamp
#             $ - orange hours
#             $ - red hours
#
# Returns:    $ - color
#
###############################################################################
sub timestamp_color ($$$)
{
    my $timestamp = shift;
    my $orange = shift;
    my $red = shift;

    if ($timestamp =~ m/(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)_(\d\d)/) {
        my $buildtime = timegm (0, $5, $4, $3, $2 - 1, $1);

        my $nowtime = timegm (gmtime());

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
    print $indexhtml "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n";
    print $indexhtml "<html>\n<head>\n<title>$scoreboard_title</title>\n";

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
    my @builds;

    ### Table

    # check to see if we are doing the "NONE" group
    if (!defined $name) {
        print "    Building table for ungrouped\n" if ($verbose);
        @builds = sort @{$groups{$name}};
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
	if (defined $builds{$buildname}->{SNAPSHOT}) {
	    $havesnapshot = 1;
	}
    }

    print $indexhtml "<table border=1>\n";
    print $indexhtml "<tr>\n";
    print $indexhtml "<th>Build Name</th><th>Last Finished</th>";
    print $indexhtml "<th>Config</th><th>Setup</th><th>Compile</th><th>Tests</th><th>Failures</th>";
    print $indexhtml "<th>Manual</th>" if ($havemanual);
    print $indexhtml "<th>Status</th>" if ($havestatus);
    print $indexhtml "<th>Build <br>Sponsor</th>";
    print $indexhtml "<th>History</th>";
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
            print $indexhtml "<a href=\"".$builds{$buildname}->{URL} ."/\">" ;
            print $indexhtml $buildname;
            print $indexhtml "</a> ";
        }
        else {
            print $indexhtml $buildname;
        }

        if (defined $builds{$buildname}->{BASENAME}) {
            my $basename = $builds{$buildname}->{BASENAME};
            my $webfile = "$buildname/$basename";

            my $orange = $orange_default;
            my $red = $red_default;

            if (defined $builds{$buildname}->{ORANGE_TIME}) {
                $orange = $builds{$buildname}->{ORANGE_TIME};
            }

            if (defined $builds{$buildname}->{RED_TIME}) {
                $red = $builds{$buildname}->{RED_TIME};
            }

            print $indexhtml '<td bgcolor=';
            print $indexhtml timestamp_color ($basename, $orange, $red);
            print $indexhtml '>',decode_timestamp ($basename);

            my $color;

            print $indexhtml '<td>';
            if (defined $builds{$buildname}->{CONFIG_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Config.html\">Config</a>] ";
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined $builds{$buildname}->{SETUP_SECTION}) {
                $color = 'white';
            }
            elsif ($builds{$buildname}->{SETUP_ERRORS} > 0) {
                $color = 'red';
            }
            elsif ($builds{$buildname}->{SETUP_WARNINGS} > 0) {
                $color = 'orange';
            }
            else {
                $color = 'lime';
            }

            print $indexhtml "<td bgcolor=$color>";
            if (defined $builds{$buildname}->{SETUP_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . $builds{$buildname}->{SETUP_SECTION} . "\">Full</a>] ";
                if ($builds{$buildname}->{SETUP_ERRORS} + $builds{$buildname}->{SETUP_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . $builds{$buildname}->{SETUP_SECTION} . "\">Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined $builds{$buildname}->{COMPILE_SECTION}) {
                $color = 'white';
            }
            elsif ($builds{$buildname}->{COMPILE_ERRORS} > 0) {
                $color = 'red';
            }
            elsif ($builds{$buildname}->{COMPILE_WARNINGS} > 0) {
                $color = 'orange';
            }
            else {
                $color = 'lime';
            }

            print $indexhtml "<td bgcolor=$color>";
            if (defined $builds{$buildname}->{COMPILE_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . $builds{$buildname}->{COMPILE_SECTION} . "\">Full</a>] ";
                if ($builds{$buildname}->{COMPILE_ERRORS} + $builds{$buildname}->{COMPILE_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . $builds{$buildname}->{COMPILE_SECTION} . "\">Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined $builds{$buildname}->{TEST_SECTION}) {
                $color = 'white';
            }
            elsif ($builds{$buildname}->{TEST_ERRORS} > 0) {
                $color = 'red';
            }
            elsif ($builds{$buildname}->{TEST_WARNINGS} > 0) {
                $color = 'orange';
            }
            else {
                $color = 'lime';
            }

            print $indexhtml "<TD bgcolor=$color>";
            if (defined $builds{$buildname}->{TEST_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . $builds{$buildname}->{TEST_SECTION} . "\">Full</a>] ";
                if ($builds{$buildname}->{TEST_ERRORS} + $builds{$buildname}->{TEST_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . $builds{$buildname}->{TEST_SECTION} . "\">Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }
            if (defined $builds{$buildname}->{SECTION_ERROR_SUBSECTIONS}) {
                if ($builds{$buildname}->{SECTION_ERROR_SUBSECTIONS} > 0) {
                    $color = 'red';
                }
                else {
                    $color = 'lime';
                }
                print $indexhtml "<TD bgcolor=$color>";
                print $indexhtml $builds{$buildname}->{SECTION_ERROR_SUBSECTIONS};
            }
            else {
                print $indexhtml "<TD>";
                print $indexhtml "&nbsp;";
            }
        }
        else {
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Time
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
                print $indexhtml "onclikc=\"window.location.href='";
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
                print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "/status.txt\"\>";
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
			print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{PDF}, "\"\>";
			print $indexhtml "pdf</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}
	}

	if ($haveps) {
		print $indexhtml "<td>";
		if (defined $builds{$buildname}->{PS}) {
			print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{PS}, "\"\>";
			print $indexhtml "ps</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}
	}

	if ($havehtml) {
		print $indexhtml "<td>";
		if (defined $builds{$buildname}->{HTML}) {
			print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{HTML}, "\/index.html\"\>";
			print $indexhtml "html</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}

	}

	if ($havesnapshot) {
		print $indexhtml "<td>";
		if (defined $builds{$buildname}->{SNAPSHOT}) {
			print $indexhtml "<a href=\"", $builds{$buildname}->{URL}, "\/", $builds{$buildname}->{SNAPSHOT}, "\"\>";
			print $indexhtml "snapshot</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}
	}

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

        print $indexhtml "<td>";
        if (defined $builds{$buildname}->{FULL_HISTORY}) {
            print $indexhtml "<a href=\"";
            print $indexhtml "http:\/\/www.dre.vanderbilt.edu\/~remedynl\/teststat\/builds\/", $buildname, ".log";
            print $indexhtml "\">";
            print $indexhtml "Full";
            print $indexhtml "</a>";
            print $indexhtml " ";
        }
        if (defined $builds{$buildname}->{CLEAN_HISTORY}) {
            print $indexhtml "<a href=\"";
            print $indexhtml "http:\/\/www.dre.vanderbilt.edu\/~remedynl\/teststat\/builds\/clean_", $buildname, ".log";
            print $indexhtml "\">";
            print $indexhtml "Clean";
            print $indexhtml "</a>";
        }
        print $indexhtml "</td>";

	print $indexhtml "</tr>\n";
    }
    print $indexhtml "</table>\n";
}

## Eventually this should probably be shared code with autobuild.pl, but
## for now, implement it as a no-op which returns something which is undefined.
sub GetVariable ($)
{
   my %a=();
   return $a{'UNDEFINED'};
}


###############################################################################
#
# Reads lists of builds from different XML files and develops a
# integrated scoreboard. This is in adition to the individual
# scoreboards for ACE and TAO and CIAO seperately.  The names of xml files have
# been hardcoded.
#
# Arguments:  $ - Output directory
#
# Returns:    Nothing
#
###############################################################################
sub build_integrated_page ($)
{
    my $dir = shift;

    unlink ("$dir/temp.xml");
    print "Build Integrated page\n" if ($verbose);

    my @file_list = ("ace",
                     "ace_future",
                     "tao",
                     "tao_future",
                     "misc",
                     "ciao");

    my $newfile = new FileHandle;

    unless ($newfile->open (">>$dir/temp.xml")) {
        print "could not create file $dir/temp.xml";
        return;
    }

    print $newfile "<INTEGRATED>\n";
    foreach my $file_list(@file_list) {
        my $file_handle = new FileHandle;
        if ($file_list eq 'ace') {
            print $newfile "<build_ace>\n";
        } elsif ($file_list eq 'tao') {
            print $newfile "<build_tao> \n";
        } elsif ($file_list eq 'ciao') {
            print $newfile "<build_ciao> \n";
        }

        $file_handle->open ("<configs/scoreboard/$file_list.xml");
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
    query_history ();
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
    return scalar(gmtime($time_in_secs)) . " UTC";
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
# You can do the followingt with this set os options.
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
# 2: For generating individual html pagesyou can do this
#
#    $ ./scoreboard.pl -d [please see above for explanation]
#                      -f [name and path of the XML file that needs
#                          to be used as a meta-file for HTML
#                          generation]
#                      -o [name of the output file. The html file will
#                          be saved by this name and placed in the
#                          directory pointed by -d].

use vars qw/$opt_d $opt_f $opt_h $opt_i $opt_o $opt_v $opt_t $opt_z $opt_l $opt_r/;

if (!getopts ('d:f:hi:o:t:vzlr:')
    || !defined $opt_d
    || defined $opt_h) {
    print "scoreboard.pl -f file [-h] [-i file] -o file [-m script] [-s dir] [-r] [-z] [-l]\n",
          "              [-t title]\n";
    print "\n";
    print "    -d         directory where the output files are placed \n";
    print "    -h         display this help\n";
    print "    -f         file for which html should be generated \n";
    print "    -i         use <file> as the index file to generate Index page only\n";
    print "    -o         name of file where the output HTML files are placed\n";
    print "    -t         the title for the scoreboard (default Scoreboard)\n";
    print "    -v         enable verbose debugging [def: only print errors]\n";
    print "    -z         Integrated page. Only the output directory is valid\n";
    print "    -l         Use local instead of UTC time\n";
    print "    -r         Specify name of RSS file\n";
    print "    All other options will be ignored  \n";
    exit (1);
}

my $index = "configs/scoreboard/index.xml";
my $inp_file = "configs/scoreboard/ace.xml";
my $out_file = "ace.html";
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

if (defined $opt_z) {
print 'Running Integrated Page Update at ' . get_time_str() . "\n" if ($verbose);
build_integrated_page ($dir);
exit (1);
}

$inp_file = $opt_f;

if (defined $opt_o) {
    $out_file = $opt_o;
}

if (defined $opt_r) {
    print "Using RSS file\n";
    $rss_file = $opt_r;
}

load_build_list ($inp_file);
build_group_hash ();
query_latest ();
update_cache ($dir);
clean_cache ($dir);
query_status ();
query_history ();
update_html ($dir,"$dir/$out_file",$rss_file);

print 'Finished Scoreboard Update at ' . get_time_str() . "\n" if ($verbose);

###############################################################################
###############################################################################
