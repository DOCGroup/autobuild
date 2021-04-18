use strict;
use warnings;

sub expect_file_contents
{
    my $expected_contents = shift;
    for my $file (@_) {
        my $result = open my $fh, '<', $file;
        if (!$result) {
            print STDERR "ERROR: Couldn't open \"$file\": $!\n";
            $main::exit_status = 1;
            next;
        }
        my $file_contents = do { local $/; <$fh> };
        if ($file_contents ne $expected_contents) {
            print(
                ("!" x 40) . " ERROR: \"$file\" contents are unexpected:\n" .
                ("!" x 40) . " EXPECTED contains:\n" .
                $expected_contents .
                ("!" x 40) . " $file contains:\n" .
                $file_contents .
                ("!" x 40) . "\n");
            $main::exit_status = 1;
        }
    }
}

###############################################################################
# compare_files
# compare 2 files line by line
# Arguments: $$ - paths to the 2 files
# Returns: 0 - the 2 files exist (not empty) and have the same contents
#          1 - otherwise, and prints the first differing lines, or error
###############################################################################
sub compare_files ($$)
{
    my $file1 = shift;
    my $file2 = shift;
    print "compare \"$file1\" with \"$file2\"\n";
    if (!(-e $file1) || (-z _)) {
        print "\"$file1\" does not exist, or is empty.\n";
        return 1;
    }
    if (!(-e $file2) || (-z _)) {
        print "\"$file2\" does not exist, or is empty.\n";
        return 1;
    }
    my $r1 = open my $fh1, '<', $file1;
    my $r2 = open my $fh2, '<', $file2;
    if (!$r1 || !$r2) {
        print STDERR "ERROR: Couldn't open \"" . ($r1 ? $file2 : $file1) . "\"\n";
        return 1;
    }
    while (1) {
        my $f1_line = <$fh1>;
        my $f2_line = <$fh2>;
        if (!$f1_line && !$f2_line) {
            return 0;
        }
        elsif (!$f1_line || !$f2_line || ($f1_line ne $f2_line)) {
            print "\"$file1\":\n$f1_line\n";
            print "\"$file2\":\n$f2_line\n";
            return 1;
        }
    }
}

1;
