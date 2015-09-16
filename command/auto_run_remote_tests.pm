#

package Auto_Run_Remote_Tests;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {'internal_options' => {'-envmod' => \&Handle_Envmod,
                                       '-extra_env' => \&Handle_XtraEnv
                                      },
                'substitute_vars_in_options' => 1,
                'extra_env' => undef
               };

    bless ($self, $class);
    return $self;
}

##############################################################################

sub CheckRequirements ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');
    my $remote_root = main::GetVariable ('remote_root');
    my $remote_shell = main::GetVariable ('remote_shell');

    if (!(defined $root || defined $remote_root)) {
        print STDERR __FILE__, ": Requires \"remote_root\" or \"root\" variable\n";
        return 0;
    }
    if (!defined $remote_shell) {
        print STDERR __FILE__, ": Requires \"remote_shell\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $root = main::GetVariable ('root');
    my $remote_root = main::GetVariable ('remote_root');
    my $configs = main::GetVariable ('configs');
    my $excludes = main::GetVariable ('test_excludes');
    my $sandbox = main::GetVariable ('sandbox');
    my $project_root = main::GetVariable ('project_root');
    my $remote_shell = main::GetVariable ('remote_shell');
    my $remote_libpath = main::GetVariable ('remote_libpath');
    my $remote_cmd = "";

    # Pull out options meant for this module
    my($next) = undef;
    my($remainder) = '';
    foreach my $part (grep(!/^\s*$/,
                           split(/(\"[^\"]+\"|\'[^\']+\'|\s+)/, $options))) {
      print STDERR $part . "\n";
      # This assumes that all internal options will take only
      # one parameter.
      if (defined $self->{'internal_options'}->{$part}) {
        $next = $part;
      }
      else {
        if (defined $next) {
          # Handle the internal option
          my($func) = $self->{'internal_options'}->{$next};
          $self->$func($part);

          # Undef these so they are not added to the options
          # that get passed to the auto_run_test.pl script.
          $part = undef;
          $next = undef;
        }
      }

      # If this wasn't an internal option or option parameter, put
      # it in the remainder string.
      if (defined $part && !defined $next) {
        $remainder .= $part . ' ';
      }
    }
    $options = $remainder;
    $options =~ s/\s+$//;

    print STDERR $options . "\n";

    # if no remote root defined use root
    if (!defined $remote_root) {
        $remote_root = $root;
        # chop off trailing slash
        if ($remote_root =~ m/^(.*)\/$/) {
            $remote_root = $1;
        }
        # handle project_root
        if (!defined $project_root) {
            # default
            $remote_root .= "/ACE_wrappers";
        } else {
            if ($project_root =~ m/^\//) {
                # absolute path replaces root
                $remote_root = $project_root;
            } else {
                # append relative path to root
                $remote_root .= "/$project_root";
            }
        }
    }

    # chop off trailing slash
    if ($remote_root =~ m/^(.*)\/$/) {
        $remote_root = $1;
    }

    main::PrintStatus ('Test', 'auto_run_tests');

    $remote_cmd .= "cd $remote_root && ";

    my $dir;
    if ($options =~ m/dir='([^']*)'/) {
        $dir = $1;
        $options =~ s/dir='$dir'//;
    }
    elsif ($options =~ m/dir=([^\s]*)/) {
        $dir = $1;
        $options =~ s/dir=$dir//;
    }

    if (defined $sandbox) {
        $options .= " -s $sandbox";
    }

    if (defined $configs) {
        $options .= " -Config " . join (" -Config ", split (' ', $configs));
    }

    if (defined $excludes) {
        $options .= " -Exclude " . join (" -Exclude ", split (' ', $excludes));
    }

    my $script_path;
    if ($options =~ m/script_path='([^']*)'/) {
        $script_path = $1;
        $options =~ s/script_path='$script_path'//;
    }
    elsif ($options =~ m/script_path=([^\s]*)/) {
        $script_path = $1;
        $options =~ s/script_path=$script_path//;
    }

    if (defined $dir) {
        $remote_cmd .= "cd $dir && ";
    }

    my $remote_tao_root = main::GetVariable ('remote_tao_root');
    if (!defined $remote_tao_root) {
        $remote_tao_root = "$remote_root/TAO";
    }
    my $remote_ciao_root = main::GetVariable ('remote_ciao_root');
    if (!defined $remote_ciao_root) {
        $remote_ciao_root = "$remote_tao_root/CIAO";
    }
    my $remote_dance_root = main::GetVariable ('remote_dance_root');
    if (!defined $remote_dance_root) {
        $remote_dance_root = "$remote_tao_root/DAnCE";
    }
    my $remote_opendds_root = main::GetVariable ('remote_opendds_root');
    if (!defined $remote_opendds_root) {
        $remote_opendds_root = "$remote_tao_root/DDS";
    }

    $remote_cmd .= "ACE_ROOT=$remote_root TAO_ROOT=$remote_tao_root CIAO_ROOT=$remote_ciao_root DANCE_ROOT=$remote_dance_root DDS_ROOT=$remote_opendds_root ";
    $remote_cmd .= "LD_LIBRARY_PATH=\\\$ACE_ROOT/lib:\\\$DDS_ROOT/lib";
    if (defined $remote_libpath) {
      $remote_cmd .= ":$remote_libpath";
    }
    $remote_cmd .= ":\\\$LD_LIBRARY_PATH ";
    $remote_cmd .= " PATH=\\\$PATH:\\\$ACE_ROOT/bin:\\\$ACE_ROOT/lib ";
    if (defined $self->{'extra_env'}) {
      $remote_cmd .= $self->{'extra_env'} . " ";
    }

    if (defined $ENV{'REMOTE_OS'} and ($ENV{'REMOTE_OS'} eq 'iPhone')) {
        if (exists $ENV{'REMOTE_PROCESS_START_WAIT_INTERVAL'}) {
            $remote_cmd .= "default_PROCESS_START_WAIT_INTERVAL=" . $ENV{'REMOTE_PROCESS_START_WAIT_INTERVAL'} . " ";
        } else {
            $remote_cmd .= "default_PROCESS_START_WAIT_INTERVAL=240 ";
        }

        if (exists $ENV{'REMOTE_PROCESS_STOP_WAIT_INTERVAL'}) {
            $remote_cmd .= "default_PROCESS_STOP_WAIT_INTERVAL=" . $ENV{'REMOTE_PROCESS_STOP_WAIT_INTERVAL'} . " ";
        } else {
            $remote_cmd .= "default_PROCESS_STOP_WAIT_INTERVAL=240 ";
        }
    }

    if(defined $script_path) {
        $remote_cmd .= " perl $script_path/auto_run_tests.pl $options";
    }
    else {
        $remote_cmd .= " perl bin/auto_run_tests.pl $options";
    }

    print "Remote shell: $remote_shell\n";
    print "Running: $remote_cmd\n";

    system ("$remote_shell \"$remote_cmd\"");
    return 1;
}

##############################################################################

sub Handle_Envmod {
  my($self)  = shift;
  my($value) = shift;

  if ($value =~ /(\w+)=(.*)/) {
    $ENV{$1} = $2;
  }
}

##############################################################################

sub Handle_XtraEnv {
  my($self)  = shift;
  my($value) = shift;

  if ($value =~ /^\'([^\']*)\'$|^\"([^\"]*)\"$/) {
    $value = $1;
  }

  if ($value =~ /(\w+)=(.*)/) {
    $self->{'extra_env'} .= ' ' . $value;
  }
}

##############################################################################

main::RegisterCommand ("auto_run_remote_tests", new Auto_Run_Remote_Tests ());
