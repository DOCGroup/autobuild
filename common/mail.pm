package Mail;

use strict;

# we need to import this package to get the value of $OSNAME
use English;

## Find a mailer which supports the "-s" flag

sub find_mailer()
{

   my @MAILERS = ( "/usr/bin/mailx",
                "/bin/mailx",
                "/usr/bin/mail",
                "/bin/mail" );

   my $mailer;

   foreach $mailer ( @MAILERS ) 
   {
      if ( -x $mailer )
      {
         return $mailer;
      }
   }

}

##############################################################################
#
#  Send an e-mail by piping output to the mail or mailx program.
#
sub send_message($$$)
{
  my ($to, $subject, $message) = @_;

  ## If we are on Windows, use the Net::SMTP package instead to send e-mail
  if ($OSNAME eq "MSWin32" )
  {
    my $status = send_message_Net_SMTP($to, $subject, $message);
    return $status;
  }

  my $mailer = find_mailer();

  if( ! defined $mailer  )
  {
      print "Cannot find mail program\n";
      return -1;
  }

  open(MAIL, "|$mailer -s \"$subject\" $to" );

  print MAIL $message;
  close(MAIL);

  return 0; 
}

##############################################################################
# Use the Net::SMTP package on Windows to send an e-mail.
#
sub send_message_Net_SMTP($$$)
{
  my ($to, $subject, $message) = @_;

  ## Net::SMTP is included with ActiveState Perl, but not with other Perl
  ## distributions.  For this reason, use 'require Net::SMTP' inside this
  ## function instead of 'use Net::SMTP' at the top of this file.

  require Net::SMTP;

  my $smtphost = main::GetVariable('MAIL_ADMIN_SMTP_HOST' );

  if ( ! defined $smtphost )
  {
     print "\nMAIL_ADMIN_SMTP_HOST undefined!!\n\n";
     return -1;
  }

  my $smtp = Net::SMTP->new( $smtphost, Debug=>1);

  if ( ! defined $smtp )
  {
     print "\nCould not connect to SMTP server: $smtphost\n\n";
     return -1;
  }


  my $mailname = "";
  require Sys::Hostname;

  if ( $OSNAME eq "MSWin32" )
  {
     require Win32;
     $mailname = Win32::LoginName()."\@". Sys::Hostname::hostname();
  }
  else
  {
     require POSIX;
     $mailname = POSIX::cuserid()."\@". Sys::Hostname::hostname();
  }

  # Send the SMTP MAIL command
  $smtp->mail($mailname);

  # Start the mail
  $smtp->data();

  $smtp->to( $to );
 
  # Start the mail
  $smtp->data();
 
  # Send the header
  # This address will appear in the message
  $smtp->datasend("To: $to\n");
  $smtp->datasend("Subject: $subject\n");
  $smtp->datasend("\n");

  # Send the body
  $smtp->datasend($message);
  $smtp->datasend("\n");

  # Send the termination string
  $smtp->dataend();
 
  # Close the connection
  $smtp->quit();

  return 0; 
}

1;

