#
# $Id: printqfconfig.pm 5777 2008-08-13 17:49:09Z mitza
#

package PrintQFConfig;

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
    my $self = {};

    bless ($self, $class);
    return $self;
}

##############################################################################

sub CheckRequirements ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
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
    my $project_root = main::GetVariable ('project_root');
    my $config_file = main::GetVariable ('CVS_CONFIG_FILE');
    my $svnurl = 'https://svn.dre.vanderbilt.edu/viewvc';
    my $qfsvnurl = "http://quickfast.googlecode.com/svn/trunk";
    my %information = ('XML'       => ['', '',
                                       "$svnurl/autobuild/trunk/<file>?revision=HEAD"],
                       'AUTOBUILD' => ['ChangeLog', '',
                                       "$svnurl/autobuild/trunk/<file>?revision=HEAD"],
                       'MPC'       => ['ChangeLog', 'MPC/',
                                       "$svnurl/MPC/trunk/<file>?revision=HEAD"],
                       'QUICKFAST' => ['ChangeLog', '',
                                       "$qfsvnurl/<file>?revision=HEAD"],
                      );
    my @cl_order = ('MPC', 'QUICKFAST');

    foreach my $option (split(/\s+/, $options)) {
      if ($option =~ /([^=]+)=(.*)/) {
        my($name)  = uc($1);
        my($value) = $2;
        ## First, check for a ChangeLog setting
        if (defined $information{$name}) {
          $information{$name}->[0] = $value;
        }
        ## Next, check for a URL setting
        elsif ($name =~ s/_URL$// && defined $information{$name}) {
          $value .= '/<file>' if ($value !~ /\/<file>/);
          $information{$name}->[2] = $value;
        }
        ## We did not recognize this setting
        else {
          print "WARNING: $name not recognized.\n";
        }
      }
    }

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    my $url = undef;
    main::PrintStatus ('Config', 'PrintQFConfig');

    $url = $information{XML}->[2];
    $url =~ s/<file>/$config_file/;
    print "XML Config file: <a href=\"$url\">${config_file}</a>\n";

    my $cl = $information{AUTOBUILD}->[0];
    $url = $information{AUTOBUILD}->[2];
    $url =~ s/<file>/$cl/;
    print "================ <a href=\"$url\">Autobuild $cl</a> ================\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
          print STDERR __FILE__, ": Cannot change to $root or $ENV{'ROOT'}\n";
          return 0;
    }

    if (!defined $project_root) {
        $project_root = 'QUICKFAST';
    }

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!chdir $ENV{'QUICKFAST_ROOT'} )
    {
        if (!chdir $project_root) {
            print STDERR __FILE__, ": Cannot change to $project_root or $ENV{'ACE_ROOT'}\n";
            return 0;
        }
    }

    foreach my $cle (@cl_order) {
      my($prroot) = $ENV{$cle . '_ROOT'};
      my($prpath) = (defined $prroot ? "$prroot/" : $information{$cle}->[1]);

      if (-r "$prpath$information{$cle}->[0]") {
          my $cl = $information{$cle}->[0];
          my $url = $information{$cle}->[2];
          $url =~ s/<file>/$cl/;
          print "================ <a href=\"$url\">$cle $cl</a> ================\n";
          print_file ("$prpath$information{$cle}->[0]", 0);
      }
    }

    #
    # QuickFAST.features, if it exists
    #

    if (-r "$ENV{QUICKFAST_ROOT}/QuickFAST.features") {
        print "================ QuickFAST.features ================\n";
        print_file ("$ENV{QUICKFAST_ROOT}/QuickFAST.features", 1);
    }


    return 1;
}

##############################################################################

sub print_file ($$)
{
    my $filename = shift;
    my $printall = shift;

    my $filehandle = new FileHandle ($filename, "r");

    while (<$filehandle>) {
        print $_;

        last if ($printall == 0);
    }
}

##############################################################################

main::RegisterCommand ("print_qf_config", new PrintQFConfig ());
