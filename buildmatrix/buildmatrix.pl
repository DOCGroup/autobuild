#!/usr/bin/env perl
# $Id$
#
#
package buildmatrix;
use fields qw(config_file scoreboard_directory builds results _current_project _current_build);

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";
use common::scoreparser;

use base qw(common::parse_compiler_output);

use IO::File;
use File::Path;

sub load_scoreboard_config($);
sub add_results($$);
sub dump_log($$$);

my $config_file = shift @ARGV;
my $scoreboard_directory = shift @ARGV;

my $build = new buildmatrix;
$build->process;

exit 0;

sub new {
  my buildmatrix $self = shift;
  $self = fields::new($self) unless ref $self;
  $self->SUPER::new();
  $self->{_current_project} = {};
  $self->{_current_build} = {};

  if(not defined $config_file or not defined $scoreboard_directory) {
    die "Usage: $0 <config_file> <scoreboard_directory>\n";
  }

  $self->{results} = {};

  return $self;
}

sub process {
  my $self = shift;

  my %builds = load_scoreboard_config($config_file);

  my %summary = ();
  while(my ($k,$v) = each %builds) {
    $self->add_results($v);
    $summary{$v->{NAME}} = {
                            passed => 0,
                            had_errors => 0,
                            had_warnings => 0,
                            total => 0
                           };
  }
  while(my ($project, $results) = each %{$self->{results}}) {
    while (my ($name, $data) = each %{$results}) {
      if ($data->{errors} != 0) {
        $summary{$name}->{had_errors}++;
      } elsif ($data->{warnings} != 0) {
        $summary{$name}->{had_warnings}++;
      } else {
        $summary{$name}->{passed}++;
      }
      $summary{$name}->{total}++;
    }
  }

  $self->print_prologue(\%summary);

  $self->print_table(\%summary);

  $self->print_epilogue(\%summary);
}

sub load_scoreboard_config($) {
  my $file = shift;
  my $parser = new ScoreboardParser;

  my %builds;
  $parser->Parse($file, \%builds);

  return %builds;
}

sub add_project($$$) {
  my $name = shift;
  my $project = shift;
  my $results = shift;

  $project =~ s/_Static//;

  unless(defined $results->{$project}) {
    $results->{$project} = {};
  }

  unless(defined $results->{$project}->{$name}) {
    $results->{$project}->{$name} = { errors => 0,
                                      warnings => 0,
                                      log => [] };
  }

  return $results->{$project}->{$name};
}

sub add_results($$) {
  my $self = shift;
  my $build = shift;
  my $results = $self->{results};

  my $name = $build->{NAME};
  $self->{_current_build} = $name;

  my $latest = $scoreboard_directory.'/'.$name.'/latest.txt';

  my $fh = new IO::File $latest, 'r';
  if(not defined $fh) {
    warn "Cannot read $latest\n";
    return;
  }

  my $line = <$fh>;
  chomp $line;
  my @fields = split(/\s+/, $line);
  my $file = $fields[0];

  my $logfile = "$scoreboard_directory/$name/$file.txt";
  print STDERR "Parsing $logfile\n";

  $fh = new IO::File $logfile, 'r';
  if (not defined $fh) {
    warn "Cannot read logfile $logfile\n";
    return;
  }

  my @regexp_list =
    (
     # This regular expression matches the GNUmake based
     # builds
     qr{^GNUmakefile:\s\S+/GNUmakefile\.(\S+)}x,

     # This one matches MSVC6 builds
     qr{^-+Configuration:\s(\S+)}x,

     # This one matches VC71 builds
     qr{^-+\sBuild\sstarted:\sProject:\s(\S+),\s}x,

     # This one matches VC.NET builds
     qr{^-+\sRebuild\s.*\sstarted:\sProject:\s(\S+),\s}x,

     # This one matches BCB6 and CBuilderX builds
     qr{make.*\s-f\s(\S+).bor\s}x,
    );

  my $state = 'NOT IN COMPILE';
  my $leave_compile = '#################### ';
  my $enter_compile = $leave_compile.'Compile ';

  LINE: while($line = $fh->getline) {
    chomp $line;
    if ($line =~ m/^$enter_compile/) {
      $state = 'COMPILE';
      $self->{_current_project} = undef;
    } elsif ($line =~ m/^$leave_compile/) {
      $state = 'NOT IN COMPILE';
      $self->{_current_project} = undef;
    }
    next unless $state eq 'COMPILE';

    foreach my $re (@regexp_list) {
      if ($line =~ m/$re/) {
        my $project = $1;
        $self->{_current_project} = add_project($name, $project, $results);
        next LINE;
      }
    }
    next unless defined $self->{_current_project};

    $self->handle_compiler_output_line($line);
#    push @{$current}, $line;
  }
}

sub current_data() {
  my $self = shift;
  return $self->{_current_project};
}

sub Output_Normal($) {
  my $self = shift;
  my $line = shift;
  my $data = $self->current_data;

  push @{$data->{log}}, $line;
}

sub Output_Warning($) {
  my $self = shift;
  my $line = shift;
  my $data = $self->current_data;

#  print "Warning: $line\n";

  $data->{warnings}++;
  push @{$data->{log}}, $line;
}

sub Output_Error($) {
  my $self = shift;
  my $line = shift;
  my $data = $self->current_data;

#  print "Error ".$self->{_current_project}.": $line\n";

  $data->{errors}++;
  push @{$data->{log}}, $line;
}

sub dump_log($$$) {
  my $project = shift;
  my $name = shift;
  my $data = shift;
  my $log = $data->{log};

  my $dir = "logs/$project";
  mkpath($dir);

  my $fh = new IO::File "$dir/$name.txt", 'w';
  $fh->print("Errors=", $data->{errors},
             ", Warnings=", $data->{warnings}, "\n");
  foreach my $l (@{$log}) {
    $fh->print($l, "\n");
  }
}

sub print_prologue($) {
  my $self = shift;
  my $summary = shift;

  my $import = '@import';

  print <<__HTML_HEAD;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Strict//EN">
<HTML>
  <HEAD>
    <TITLE>Scoreboard Build Matrix</TITLE>
    <STYLE>$import "buildmatrix.css";</STYLE>
  </HEAD>
  <BODY>
__HTML_HEAD

  # TODO It would be nice to print the number of projects missed by a
  # particular platform...

  print <<__TABLE_START;
<table class="summary">
  <tr class="header">
    <th colspan="6">Summary</th>
  </tr>
  <tr class="header">
    <th>#</th>
    <th>Name</th>
    <th># Error</th>
    <th># Warning</th>
    <th>Total</th>
    <th>% Pass</th>
  </tr>
__TABLE_START

  my $counter = 0;
  while(my ($name, $data) = each %{$summary}) {
    $counter++;
    print '<tr class="';
    if ($counter % 2 == 0) {
      print "even";
    } else {
      print "odd";
    }
    print '"><td>'.$counter.'</td><td class="txt">'.$name.'</td>';
    print '<td>'.$data->{had_errors}.'</td>';
    print '<td>'.$data->{had_warnings}.'</td>';
    print '<td>'.$data->{total}.'</td>';
    if ($data->{total} == 0) {
      print '<td>'.'0'.'</td>';
    } else {
      # Just 2 digits of precision
      my $percent = int(($data->{passed} * 100 * 100)
                        / $data->{total}) / 100.0;
      print '<td>'.$percent.'</td>';
    }
    print '</tr>'."\n";
  }

  print "</table>\n\n\n";
}

sub print_epilogue($) {
  my $self = shift;
  my $summary = shift;

  print <<__CLOSE;
</body>
</html>
__CLOSE
}

sub print_results_header($) {
  my $self = shift;
  my $summary = shift;

  print '<tr class="ih">';
  print '<td class="name">Project Name</td>';
  my $counter = 0;
  foreach my $i (keys %{$summary}) {
    $counter++;
    my $text = join('<br>', split(//, $counter));
    print '<td>'.$text.'</td>';
  }
  print "</tr>\n";
}

sub print_table($) {
  my $self = shift;
  my $summary = shift;

  my $span = scalar(keys %{$summary}) + 2;

  print <<__TABLE_START;
<table class="results">
<tr><th colspan="$span">Build Results By Project</th></tr>
__TABLE_START

  my $counter = 0;
  foreach my $project (sort keys %{$self->{results}}) {
    my $data = $self->{results}->{$project};
    if ($counter % 20 == 0) {
      $self->print_results_header($summary);
    }
    $counter++;
    print '<tr class="';
    if ($counter % 2 == 0) {
      print "even";
    } else {
      print "odd";
    }
    print '"><td class="txt">'.$project.'</td>';
    foreach my $name (keys %{$summary}) {
      if (not defined $data->{$name}) {
        print '<td class="M"> </td>';
      } else {
        if ($data->{$name}->{errors} != 0) {
          print '<td class="E">';
        } elsif ($data->{$name}->{warnings} != 0) {
          print '<td class="W">';
        } else {
          print '<td class="P">';
        }
        print '<a href="logs/'."$project/$name".'.txt">_</a></td>';
        dump_log($project, $name, $data->{$name});
      }
    }
    print "</tr>\n";
  }
  print '</table>';
}

