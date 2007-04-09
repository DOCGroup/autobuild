
package utility;

###############################################################################
#
# index_logs 
#
# Builds the index.txt file
#
# Arguments:  $ - directory to index
#             $ - optional name to add to title
#
# Returns:    Nothing
#
###############################################################################
sub index_logs ($$)
{
    my $dir = shift;
    my $name = shift;
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
    print $fh "<table border=\"1\">\n<th>Timestamp</th><th>Setup</th><th>Compile</th><th>Test</th>\n";
    
    foreach my $file (@files) {
        my $totals_fh = new FileHandle ($dir . '/' . $file . '_Totals.html', 'r');
        
        print $fh '<tr>';
        
        if (defined $totals_fh) {
            print $fh "<td><a href=\"${file}_Totals.html\">$file</a></td>";
            while (<$totals_fh>) {
                if (m/^<!-- BUILD_TOTALS\:/) {
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
            print $fh "<td>$file</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>";
        }
        print $fh "</tr>\n";
    }
    
    print $fh "</table>\n</body>\n</html>\n";
    return 1;
}

1;
