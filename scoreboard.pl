eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

#
# $Id$
#

use strict;
use warnings;
use diagnostics;
use common::prettify;
use common::scoreparser;
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

my %builds;

# %groups->{$name} <- list of builds for $name

my %groups;

my @nogroup;

my $orange_default = 24;
my $red_default = 48;

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

    print "Loading Build List\n";

    my $parser = new ScoreboardParser;
    $parser->Parse ($file, \%builds);
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
    print "Grouping builds\n";

    foreach my $buildname (keys %builds) {
        if (defined %builds->{$buildname}->{GROUP}) {
            push @{%groups->{%builds->{$buildname}->{GROUP}}}, $buildname;
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
    print "Getting latest files\n";

    foreach my $buildname (keys %builds) {
        my $latest = load_web_latest (%builds->{$buildname}->{URL});
        
        if ($latest =~ m/(...._.._.._.._..) /) {
            %builds->{$buildname}->{BASENAME} = $1;
        }
        else {
            print STDERR "    Error: Could not find latest.txt for $buildname\n";
            next;
        }
        
        if ($latest =~ m/Config: (\d+)/) {
            %builds->{$buildname}->{CONFIG_SECTION} = $1;
        }
        
        if ($latest =~ m/Setup: (\d+)-(\d+)-(\d+)/) {
            %builds->{$buildname}->{SETUP_SECTION} = $1;
            %builds->{$buildname}->{SETUP_ERRORS} = $2;
            %builds->{$buildname}->{SETUP_WARNINGS} = $3;
        }
        
        if ($latest =~ m/Compile: (\d+)-(\d+)-(\d+)/) {
            %builds->{$buildname}->{COMPILE_SECTION} = $1;
            %builds->{$buildname}->{COMPILE_ERRORS} = $2;
            %builds->{$buildname}->{COMPILE_WARNINGS} = $3;
        }

        if ($latest =~ m/Test: (\d+)-(\d+)-(\d+)/) {
            %builds->{$buildname}->{TEST_SECTION} = $1;
            %builds->{$buildname}->{TEST_ERRORS} = $2;
            %builds->{$buildname}->{TEST_WARNINGS} = $3;
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
    print "Getting status messages\n";

    foreach my $buildname (keys %builds) {
        my $link = %builds->{$buildname}->{URL} . '/status.txt';
        if (defined $link) {
            print "    Status [$buildname] from $link\n";

            my $ua = LWP::UserAgent->new;

            ### We are impatient, so don't wait more than 20 seconds for a
            ### response (the default was 180 seconds)
            $ua->timeout(20);

            my $request = HTTP::Request->new('GET', $link);
            my $response = $ua->request($request);

            if (!$response->is_success ()) {
                print "        No status for $buildname\n";
                next;
            }

            my @contents = split /\n/, $response->content ();

            ### Now look for files

            foreach my $line (@contents) {
                if ($line =~ m/SCOREBOARD_STATUS\:(.*)$/) {
                    %builds->{$buildname}->{STATUS} = $1;
                }
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

    print "    Loading latest from $address/latest.txt\n";

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
        print "        ERROR: Could not latest.txt\n";
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
        my %mon = ( 1 => 'Jan',  2 => 'Feb',  3 => 'Mar',
                    4 => 'Apr',  5 => 'May',  6 => 'Jun',
                    7 => 'Jul',  8 => 'Aug',  9 => 'Sep',
                   10 => 'Oct', 11 => 'Nov', 12 => 'Dec');
        $description =
            sprintf ('%s %s, %s - %s:%s', $mon{int ($2)}, $3, $1, $4, $5);

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

    print "Updating Local Cache\n";

    if (!-w $directory) {
        warn "Cannot write to $directory";
        return;
    }

    foreach my $buildname (keys %builds) {
        ### Check to see if we had problems.  If there is no basename,
        ### we had problems downloading.
        if (!defined %builds->{$buildname}->{BASENAME}) {
            next;
        }

        my $basename = %builds->{$buildname}->{BASENAME};
        my $address = %builds->{$buildname}->{URL} . "/" . %builds->{$buildname}->{BASENAME} . ".txt";

        my $filename = %builds->{$buildname}->{BASENAME} . '.txt';

        print "    Looking at $buildname\n";

        mkpath "$directory/$buildname";

        if (! -r "$directory/$buildname/$filename") {
            print "        Downloading\n";
            my $ua = LWP::UserAgent->new;
            my $request = HTTP::Request->new('GET', $address);
            my $response = $ua->request($request, "$directory/$buildname/$filename");

            if (!$response->is_success ()) {
                print "WARNING: Unable to download $address\n";
                return;
            }
            
            print "        Prettifying\n";
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

    print "Cleaning Local Cache\n";

    if (!-w $directory) {
        warn "Cannot write to $directory";
        return;
    }

    foreach my $buildname (keys %builds) {
        my @existing;
        
        print "    Looking at $buildname\n";

        my $dh = new DirHandle ($directory);

        # Load the directory contents into the @existing array

        if (!defined $dh) {
            print STDERR "Error: Could not read $directory\n";
            return 0;
        }

        while (defined($_ = $dh->read)) {
            if ($_ =~ m/^(...._.._.._.._..)\.txt/) {
                push @existing, "$directory/$1";
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
            print "        Removing $file files\n";
            unlink $file . ".txt";
            unlink $file . "_Full.html";
            unlink $file . "_Brief.html";
            unlink $file . "_Totals.html";
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

        my $nowtime = timegm (gmtime ());

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
# Runs make_pretty on a bunch of files and creates an index.html
#
# Arguments:  $ - directory
#
# Returns:    Nothing
#
###############################################################################
sub update_html ($)
{
    my $dir = shift;
    my $filename = "$dir/index.html";

    my $indexhtml = new FileHandle;

    print "Generating Scoreboard\n";

    unless ($indexhtml->open (">$filename")) {
        warn 'Could not create file: '.$filename." ".$_;
        return;
    }

    ### Print Header

    print $indexhtml "<html>\n<head>\n<title>Build Scoreboard</title>\n</head>\n";

    ### Start body

    print $indexhtml "<body bgcolor=white>\n<h1>Build Scoreboard</h1>\n<hr>\n";

    ### Print tables (first the empty one)

    update_html_table ($dir, $indexhtml, undef) if ($#nogroup >= 0);
    foreach my $group (sort keys %groups) {
        update_html_table ($dir, $indexhtml, $group);
    }

    ### Print timestamp

    print $indexhtml '<br>Last updated at '.scalar (gmtime ())." UTC<br>\n";

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
        print "    Building table for ungrouped\n";
        @builds = sort @nogroup;
    }
    else {
        print "    Building table for group $name\n";
        @builds = sort @{%groups->{$name}};
        print $indexhtml "<a name=\"$name\"><h2></a>$name</h2>\n";
    }

    foreach my $buildname (@builds) {
        if (defined %builds->{$buildname}->{STATUS}) {
            $havestatus = 1;
        }
        if (defined %builds->{$buildname}->{MANUAL_LINK}) {
            $havemanual = 1;
        }
	if (defined %builds->{$buildname}->{PDF}) {
	    $havepdf = 1;
	}
	if (defined %builds->{$buildname}->{PS}) {
	    $haveps = 1;
	}
	if (defined %builds->{$buildname}->{HTML}) {
	    $havehtml = 1;
	}
	if (defined %builds->{$buildname}->{SNAPSHOT}) {
	    $havesnapshot = 1;
	}
    }

    print $indexhtml "<table border=1><th>Build Name<th>Last Finished";
    print $indexhtml "<th>Config<th>Setup<th>Compile<th>Tests";
    print $indexhtml "<th>Manual" if ($havemanual);
    print $indexhtml "<th>Status" if ($havestatus);
    # New entries
    print $indexhtml "<th>PDF" if ($havepdf);
    print $indexhtml "<th>PS" if ($haveps);
    print $indexhtml "<th>HTML" if ($havehtml);
    print $indexhtml "<th>SNAPSHOT" if ($havesnapshot);
    print $indexhtml "\n";

    foreach my $buildname (@builds) {
        print "        Looking at $buildname\n";

        print $indexhtml '<tr><td>';

        if (defined %builds->{$buildname}->{URL}) {
            print $indexhtml "<a href=\"".%builds->{$buildname}->{URL} ."/\">" ;
            print $indexhtml $buildname;
            print $indexhtml "</a> ";
        }
        else {
            print $indexhtml $buildname;
        }

        if (defined %builds->{$buildname}->{BASENAME}) {
            my $basename = %builds->{$buildname}->{BASENAME};
            my $webfile = "$buildname/$basename";

            my $orange = $orange_default;
            my $red = $red_default;

            if (defined %builds->{$buildname}->{ORANGE_TIME}) {
                $orange = %builds->{$buildname}->{ORANGE_TIME};
            }

            if (defined %builds->{$buildname}->{RED_TIME}) {
                $red = %builds->{$buildname}->{RED_TIME};
            }

            print $indexhtml '<td bgcolor=';
            print $indexhtml timestamp_color ($basename, $orange, $red);
            print $indexhtml '>',decode_timestamp ($basename);

            my $color;

            print $indexhtml '<td>';
            if (defined %builds->{$buildname}->{CONFIG_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . %builds->{$buildname}->{CONFIG_SECTION} . "\">Config</a>] ";
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined %builds->{$buildname}->{SETUP_SECTION}) {
                $color = 'white';
            } 
            elsif (%builds->{$buildname}->{SETUP_ERRORS} > 0) {
                $color = 'red';
            }
            elsif (%builds->{$buildname}->{SETUP_WARNINGS} > 0) {
                $color = 'orange';
            }
            else {
                $color = 'lime';
            }

            print $indexhtml "<td bgcolor=$color>";
            if (defined %builds->{$buildname}->{SETUP_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . %builds->{$buildname}->{SETUP_SECTION} . "\">Full</a>] ";
                if (%builds->{$buildname}->{SETUP_ERRORS} + %builds->{$buildname}->{SETUP_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . %builds->{$buildname}->{SETUP_SECTION} . "\">Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined %builds->{$buildname}->{COMPILE_SECTION}) {
                $color = 'white';
            } 
            elsif (%builds->{$buildname}->{COMPILE_ERRORS} > 0) {
                $color = 'red';
            }
            elsif (%builds->{$buildname}->{COMPILE_WARNINGS} > 0) {
                $color = 'orange';
            }
            else {
                $color = 'lime';
            }

            print $indexhtml "<td bgcolor=$color>";
            if (defined %builds->{$buildname}->{COMPILE_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . %builds->{$buildname}->{COMPILE_SECTION} . "\">Full</a>] ";
                if (%builds->{$buildname}->{COMPILE_ERRORS} + %builds->{$buildname}->{COMPILE_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . %builds->{$buildname}->{COMPILE_SECTION} . "\">Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }

            if (!defined %builds->{$buildname}->{TEST_SECTION}) {
                $color = 'white';
            } 
            elsif (%builds->{$buildname}->{TEST_ERRORS} > 0) {
                $color = 'red';
            }
            elsif (%builds->{$buildname}->{TEST_WARNINGS} > 0) {
                $color = 'orange';
            }
            else {
                $color = 'lime';
            }

            print $indexhtml "<TD bgcolor=$color>";
            if (defined %builds->{$buildname}->{TEST_SECTION}) {
                print $indexhtml "[<a href=\"".$webfile."_Full.html#section_" . %builds->{$buildname}->{TEST_SECTION} . "\">Full</a>] ";
                if (%builds->{$buildname}->{TEST_ERRORS} + %builds->{$buildname}->{TEST_WARNINGS} > 0) {
                    print $indexhtml "[<a href=\"".$webfile."_Brief.html#section_" . %builds->{$buildname}->{TEST_SECTION} . "\">Brief</a>]";
                }
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }
        else {
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Time
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Config
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # CVS
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Compiler
            print $indexhtml '<td bgcolor=gray>&nbsp;'; # Tests
        }


        if ($havemanual) {
            print $indexhtml "<td align=center>";
            if (defined %builds->{$buildname}->{MANUAL_LINK}) {
                print $indexhtml "<input type=\"button\" value=\"Start\" ";
                print $indexhtml "onclikc=\"window.location.href='";
                print $indexhtml %builds->{$buildname}->{MANUAL_LINK};
                print $indexhtml "'\">";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }
        if ($havestatus) {
            print $indexhtml "<td>";
            if (defined %builds->{$buildname}->{STATUS}) {
                print $indexhtml "<a href=\"", %builds->{$buildname}->{URL}, "/status.txt\"\>";
                print $indexhtml %builds->{$buildname}->{STATUS};
                print $indexhtml "</a>";
            }
            else {
                print $indexhtml "&nbsp;";
            }
        }
	
	if ($havepdf) {
		print $indexhtml "<td>";
		if (defined %builds->{$buildname}->{PDF}) {
			print $indexhtml "<a href=\"", %builds->{$buildname}->{URL}, "\/", %builds->{$buildname}->{PDF}, "\"\>";
			print $indexhtml "pdf</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}
	}

	if ($haveps) {
		print $indexhtml "<td>";
		if (defined %builds->{$buildname}->{PS}) {
			print $indexhtml "<a href=\"", %builds->{$buildname}->{URL}, "\/", %builds->{$buildname}->{PS}, "\"\>";
			print $indexhtml "ps</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}
	}

	if ($havehtml) {
		print $indexhtml "<td>";
		if (defined %builds->{$buildname}->{HTML}) {
			print $indexhtml "<a href=\"", %builds->{$buildname}->{URL}, "\/", %builds->{$buildname}->{HTML}, "\/index.html\"\>";
			print $indexhtml "html</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}

	}

	if ($havesnapshot) {
		print $indexhtml "<td>";
		if (defined %builds->{$buildname}->{SNAPSHOT}) {
			print $indexhtml "<a href=\"", %builds->{$buildname}->{URL}, "\/", %builds->{$buildname}->{SNAPSHOT}, "\"\>";
			print $indexhtml "snapshot</a>";
		}
		else {
			print $indexhtml "&nbsp;";
		}
	}
	print $indexhtml "\n";
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
# Callbacks for commands
#

###############################################################################
###############################################################################

# Getopts

use vars qw/$opt_c $opt_h $opt_o /;

if (!getopts ('c:ho:') || defined $opt_h) {
    print "scoreboard.pl [-c file] [-h] [-o dir] [-m script] [-r]\n";
    print "\n";
    print "    -c file    use <file> as the configuration file [def: configs/scoreboard/acetao.xml]\n";
    print "    -h         display this help\n";
    print "    -o dir     directory to place files [def: html]\n";
    exit (1);
}

my $file = "configs/scoreboard/acetao.xml";
my $dir = "html";

if (defined $opt_c) {
    $file = $opt_c;
}

if (defined $opt_o) {
    $dir = $opt_o;
}

# Do the stuff

print 'Running Scoreboard Update at '.scalar (gmtime ())."\n";

load_build_list ($file);
build_group_hash ();
query_latest ();
update_cache ($dir);
clean_cache ($dir);
query_status ();
update_html ($dir);

print 'Finished Scoreboard Update at '.scalar (gmtime ())."\n";

###############################################################################
###############################################################################
