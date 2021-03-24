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
        }
    }
}

1;
