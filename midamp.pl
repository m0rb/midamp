#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use File::Basename;
use lib dirname($0);
use MyLib::Functions;
use MyLib::HTML;
use Config::Tiny;
use File::Slurp qw(:all);
use Getopt::Long;
use Dancer2;

my $config = Config::Tiny->read( dirname($0) . "/config.ini" );
our $device = $config->{'midamp'}->{'device'};

our ( $port, $hwid, $randfile, $playlist, @files );

GetOptions(
   "port|p=s"         => \$port,
   "hwid|h=s"         => \$hwid,
   "device|d=s"       => \$device,
   "playlist|pls=s" => \$playlist
);

$port ||= mididev( "port", $device );
$hwid ||= mididev( "hwid", $device );

our $apmargs = "aplaymidi -p$port";
our $amargs  = "amidi -p$hwid";
our $log     = "log.txt";
our $pn      = 0;

if ( defined $playlist ) {
   our $plays = Config::Tiny->read("$playlist")
     or die "Error reading playlist file.";
   my $index = 0;
   while ( ( my ( $k, $v ) ) = each( %{ $plays->{'playlist'} } ) ) {
      push @files, $v if ( $k =~ /file\d/i );
   }
}
else {
   @files = `ls *.mid *.MID`;
}

my $pi  = packimage("images/play.png");
my $si  = packimage("images/stop.png");
my $pls = packimage("images/pls.png");
my $ff  = packimage("images/ff.png");
my $re  = packimage("images/rewind.png");

get '/' => sub {
   srand;
   my $hh     = request->host;
   my $output = rf( $log, { chomp => 1 } );
   return
       &hHeader($hh)
     . h( 2, "MIDamp" )
     . &br
     . iframe("/current")
     . &br
     . &br
     . href( "/playrandom", img($pi) )
     . href( "/stop",       img($si) )
     . href( "/rewind",     img($re) )
     . href( "/ff",         img($ff) )
     . &br
     . href( "/playlist", img($pls) )
     . &hFooter;
};

get '/playlist' => sub {
   my $hh    = request->host;
   my $out   = hHeader("Playlist");
   my $index = 0;
   foreach (@files) {
      $out .= href( "http://$hh/playnum/$index", "$index: $_" ) . &br;
      $index++;
   }
   $out .= &hFooter;
   return $out;
};

get '/playrandom' => sub {
   srand;
   stopit();
   $pn = 1;
   my $hh = request->host;
   $randfile = randfile();
   fork
     and return hHeader( "Random File", $hh ) . h( 2, $randfile ) . &hFooter;
   wf( $log, $randfile );
   playback($randfile);
};

get '/playnum/:id' => sub {
   stopit();
   $pn = 1;
   my $hh = request->host;
   my $id = route_parameters->get('id');
   our $file = $files[$id];
   fork
     and return hHeader( "Play FileNo", $hh )
     . &br
     . h( 2, "Now Playing: $file" )
     . &hFooter;
   wf( $log, $file );
   playback($file);
};

get '/stop' => sub {
   srand;
   my $hh = request->host;
   stopit();
   return hHeader( "Stop", $hh ) . &br . h( 2, "Stopping..." ) . &hFooter;
};

get '/ff' => sub {
   my $hh = request->host;
   my $fn = rf( $log, { chomp => 1 } );
   if ( -s $log ) {
      stopit();
      my $idx = ( ( &first( $fn, @files ) ) + 1 );
      wf( $log, $files[$idx] );
      fork
        and return hHeader( "Fast Forward", $hh )
        . &br
        . h( 2, "Skipping Track..." )
        . &br
        . h( 3, "Next up: $files[$idx]" )
        . &hFooter;
      playback( $files[$idx] );
   }
};

get '/rewind' => sub {
   my $hh = request->host;
   my $fn = rf( $log, { chomp => 1 } );
   if ( -s $log ) {
      stopit();
      fork
        and return hHeader( "Rewinding...", $hh ) . &hFooter;
      playback($fn);
   }
};

get '/current' => sub {
   my $hh = request->host . "/current";
   my $fn = rf( $log, { chomp => 1 } );

   return hHeader( "Now Playing", $hh ) . "Now Playing: $fn" . &hFooter;

};

print "MIDamp running:\n\tMIDI Port: $port\n\t";
print "MIDI HWID: $hwid\n\tMIDI Dev: $device\n";

start;
