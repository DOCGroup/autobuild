use strict;

package utility;

# Run command, returns 0 if there was an error
sub run_command ($;$) {
  my $command = shift;
  my $ignore_failure = shift;
  if (!defined $ignore_failure) {
      $ignore_failure = 0;
  }

  if (system ($command)) {
      my $error_message;
      if ($? == -1) {
          $error_message = "Failed to Run: $!";
      } elsif ($? & 127) {
          $error_message = sprintf ("Exited on Signal %d, %s coredump",
            ($? & 127),  ($? & 128) ? 'with' : 'without');
      } else {
          $error_message = sprintf ("Returned %d", $? >> 8);
      }
      print STDERR "Command \"$command\" $error_message\n";
      return $ignore_failure;
  }
  return 1;
}

###############################################################################
#
# index_logs
#
# Builds the index.txt file
#
# Arguments:  $ - directory to index
#             $ - optional name to add to title
#             $ - optional diff root
#
# Returns:    Nothing
#
###############################################################################
sub index_logs ($;$$)
{
    my $dir = shift;
    my $name = shift;
    my $diffRoot = shift;
    my @files;
   
    my $dh = new DirHandle ($dir);

    # Load the directory contents into the @existing array

    if (!defined $dh) {
        print STDERR __FILE__, ": Could not read directory $dir\n";
        return 0;
    }

    while (defined($_ = $dh->read)) {
        if ($_ =~ m/^(...._.._.._.._..).txt/) {
            push @files, $1;
        }
    }
    undef $dh;

    @files = reverse sort @files;

    my $fh = new FileHandle ($dir . '/index.html', 'w');
   
    if (!defined $fh) {
        print STDERR __FILE__, ": Cannot create index.html in $dir\n";
        return 0;
    }
   
    my $title = 'Build History';
   
    if (defined $name) {
        $title .= " for $name";
    }
   
    print $fh "<html>\n<head>\n<title>$title</title>\n</head>\n";
    print $fh "<body bgcolor=\"white\"><h1>$title</h1>\n<hr>\n";
    print $fh "<table border=\"1\">\n<th>Last Finished</th><th>Rev</th><th>Setup</th><th>Compile</th><th>Test</th>\n";
   
    foreach my $file (@files) {
        my $totals_fh = new FileHandle ($dir . '/' . $file . '_Totals.html', 'r');
       
        print $fh '<tr>';
       
        if (defined $totals_fh) {
            my $diffRev = 'None';
            print $fh "<td><a href=\"${file}_Totals.html\">$file</a></td>";
            while (<$totals_fh>) {
                if (m/^<!-- BUILD_TOTALS\:/) {
                    if (m/ACE: ([0-9a-f]{6,12})/) {
                        $diffRev = $1;
                    }
                    elsif (m/OpenDDS: ([0-9a-f]{6,12})/) {
                        $diffRev = $1;
                    }
                   
                    if (($diffRev) && ($diffRev !~ /None/) && ($diffRoot)) {
                      my $url = $diffRoot . $diffRev;
                      my $link = "<a href='$url'>$diffRev</a>";
                      print $fh "<td>&nbsp;$link&nbsp;</td>";
                    } else {
                      print $fh "<td>&nbsp;$diffRev&nbsp;</td>";
                    }

                    if (m/Setup: (\d+)-(\d+)-(\d+)/) {
                        print $fh '<td>';
                       
                        if ($2 > 0) {
                            print $fh "<font color=\"red\">$2 Error(s)</font> ";
                        }
                       
                        if ($3 > 0) {
                            print $fh "<font color=\"orange\">$3 Warning(s)</font>";
                        }
                       
                        if ($2 == 0 && $3 == 0) {
                            print $fh '&nbsp';
                        }
                       
                        print $fh '</td>';
                    }
                    else {
                        print $fh '<td>&nbsp;</td>';
                    }
                   
                    if (m/Compile: (\d+)-(\d+)-(\d+)/) {
                        print $fh '<td>';
                       
                        if ($2 > 0) {
                            print $fh "<font color=\"red\">$2 Error(s)</font> ";
                        }
                       
                        if ($3 > 0) {
                            print $fh "<font color=\"orange\">$3 Warning(s)</font>";
                        }
                       
                        if ($2 == 0 && $3 == 0) {
                            print $fh '&nbsp';
                        }
                       
                        print $fh '</td>';
                    }
                    else {
                        print $fh '<td>&nbsp;</td>';
                    }

                    if (m/Test: (\d+)-(\d+)-(\d+)/) {
                        print $fh '<td>';
                       
                        if ($2 > 0) {
                            print $fh "<font color=\"red\">$2 Error(s)</font> ";
                        }
                       
                        if ($3 > 0) {
                            print $fh "<font color=\"orange\">$3 Warning(s)</font>";
                        }
                       
                        if ($2 == 0 && $3 == 0) {
                            print $fh '&nbsp';
                        }
                       
                        print $fh '</td>';
                    }
                    else {
                        print $fh '<td>&nbsp;</td>';
                    }

                    last;
                }
            }
        }
        else {
            print $fh "<td>$file</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>";
        }
        print $fh "</tr>\n";
    }
   
    print $fh "</table>\n</body>\n</html>\n";
    return 1;
}

1;
