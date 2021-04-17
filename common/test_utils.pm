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

sub compare_files
{
    my $file1 = shift;
    my $file2 = shift;
    print "compare \"$file1\" with \"$file2\"\n";
    my $r1 = open my $fh1, '<', $file1;
    my $r2 = open my $fh2, '<', $file2;
    if (!$r1 || !$r2) {
        print STDERR "ERROR: Couldn't open \"$file1\" or \"$file2\"\n";
        return 1;
    }
    my $file1_contents = do { local $/; <$fh1> };
    my $file2_contents = do { local $/; <$fh2> };
    if ($file1_contents eq $file2_contents) {
        return 0;
    }
    print(
        ("!" x 40) . " ERROR: Files differ:\n" .
        ("!" x 40) . " \"$file1\":\n$file1_contents\n" .
        ("!" x 40) . " \"$file2\":\n$file2_contents\n");
    return 1;
}

1;
