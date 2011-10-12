eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
    & eval 'exec perl -S $0 $argv:q'
    if 0;

# $Id$
# -*- perl -*-

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use common::prettify;

package LogCounter;

our @ISA = qw(Prettify);

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  %{$self->{UNFIXED_BUGS}} = ();
  return bless $self, $class;
}

sub Output_Subsection {
  my $self = shift;
  my $name = shift;
  ++$self->{summaries}->{$self->{file}}->{subsections};
  $self->{summaries}->{$self->{file}}->{test_name} = $name;
}

sub Output_Normal {
  my $self = shift;
  ++$self->{summaries}->{$self->{file}}->{normal};
}

sub Output_Error {
  my $self = shift;
  my $line = shift;
  ++$self->{summaries}->{$self->{file}}->{error};
  push @{$self->{summaries}->{$self->{file}}->{error_info}},
  [$., $line, $self->{summaries}->{$self->{file}}->{test_name}];
}

sub Output_Warning {
  my $self = shift;
  my $line = shift;
  ++$self->{summaries}->{$self->{file}}->{warning};
  push @{$self->{summaries}->{$self->{file}}->{warn_info}},
  [$., $line, $self->{summaries}->{$self->{file}}->{test_name}];
}

package main;

my $counter = new LogCounter;

while(<>) {
  $counter->{file} = $ARGV if not $counter->{file};
  $counter->Test_Handler($_);
} continue {
  undef $counter->{file} and close $ARGV if eof;
}

my $indent = scalar keys %{$counter->{summaries}} > 1 ? '  ' : '';

foreach my $file (sort keys %{$counter->{summaries}}) {
  print "FILE $file:\n" unless $indent eq '';
  print "${indent}SUBSECTIONS: $counter->{summaries}->{$file}->{subsections}\n"
    if $counter->{summaries}->{$file}->{subsections};
  print "${indent}NORMAL:      $counter->{summaries}->{$file}->{normal}\n"
    if $counter->{summaries}->{$file}->{normal};
  my $warn = $counter->{summaries}->{$file}->{warning};
  if($warn) {
    print "${indent}WARNING:     $warn\n";
    for my $info (@{$counter->{summaries}->${file}->{warn_info}}) {
      $info->[2] = '' unless defined $info->[2];
      print "$indent  " . $info->[2] . ' ' . $info->[0] . ':' . $info->[1];
    }
  }
  my $error = $counter->{summaries}->{$file}->{error};
  if($error) {
    print "${indent}ERROR:       $error\n";
    for my $info (@{$counter->{summaries}->{$file}->{error_info}}) {
      $info->[2] = '' unless defined $info->[2];
      print "$indent  " . $info->[2] . ' ' . $info->[0] . ':' . $info->[1];
    }
  }
}
