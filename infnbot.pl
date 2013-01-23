#!/usr/local/bin/perl

#no license infnbot.pl theinfinitynetwork.org

use Getopt::Std;

use POE;
use POE::Component::IRC;

use AI::MegaHAL;

$configfile="infnbot.config";

getopts('c:');

if ($opt_c) { $configfile= $opt_c; }

open CFD, "$configfile" or die("$!");

while (<CFD>) {
  chomp;
  eval($_);
}

close(CFD);

$mh = AI::MegaHAL->new('Path' => $brainpath, 'Prompt' => 0, 'Wrap' => 0, 'AutoSave' => $savebrain);




my ($irc) = POE::Component::IRC->spawn();

POE::Session->create(
  inline_states => {
    _start     => \&bot_start,
    irc_001    => \&on_connect,
    irc_public => \&on_public,
    irc_msg => \&on_private,
    irc_disconnected => \&tryreconnect,
    irc_error        => \&tryreconnect,
    irc_socketerr    => \&tryreconnect,
    autoping         => \&doping,

  },
);

sub bot_start {
  $irc->yield(register => "all");

  $irc->yield(
    connect => {
      Nick     => $botnick,
      Username => $username,
      Ircname  => $ircname,
      Server   => $server,
      Port     => $port,
    }
  );
}

sub on_connect {
  foreach (@channels) { $irc->yield('join', $_ ); }
}

sub doping
{
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $kernel->post( bot => userhost => $config->{nickname} )unless $heap->{seen_traffic};
    $heap->{seen_traffic} = 0;
    $kernel->delay( autoping => 300 );
}

sub tryreconnect
{

    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $kernel->delay( autoping => undef );
    $kernel->delay( connect  => 15 );
}

sub on_private {
  my ($kernel, $who, $to, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $address    = (split /!/, $who)[1];
  my $ts      = scalar localtime;

  print "$nick -> $address -> $ts -> $msg" . "\n";
}

sub on_public {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;

  if ($msg =~ /^$botnick /) {
    $msg =~ s/$botnick //g;
    $irc->yield(privmsg => $channel, $mh->do_reply($msg));
    return;
  }

  if ($msg =~ /^.version/) {
    $irc->yield(privmsg => $channel, $VERSION);
    return;
  }

  if ($msg =~ /^.who/) {
    $irc->yield(privmsg => $channel, $who);
    return;
  }

  if ($msg =~ /^.time/) {
    $irc->yield(privmsg => $channel, $ts);
    return;
  }

  if ($msg =~ /^.think/) {
    $lastmsg = $mh->do_reply("");
    $irc->yield(privmsg => $channel, $lastmsg);
    return;
  }

  $mh->learn($msg);

  AI::MegaHAL::megahal_cleanup();
}

$poe_kernel->run();

exit 0;
