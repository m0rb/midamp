#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Dancer2;
use MIME::Base64;
use List::MoreUtils qw(first_index);
use File::Slurp     qw(:all);

my @files = `ls *.mid *.MID`;

my $apmargs = "/usr/bin/aplaymidi -p16:0";
my $randfile;

my $pi  = packimage( "images/play.png" );
my $si  = packimage( "images/stop.png" );
my $pls = packimage( "images/pls.png" );
my $ff  = packimage( "images/ff.png" );
my $re  = packimage( "images/rewind.png" );

my $log = "log.txt";

our $pn = 0;

get '/' => sub {
   srand;
   my $hh     = request->host;
   my $output = rf( $log, { chomp => 1 } );
   return &hHeader($hh)
     . h( 2, "MIDamp" ) . &br . iframe( "/current" ) . &br . &br
     . href( "/playrandom", img( $pi ) ) . href( "/stop", img($si) )
     . href( "/rewind", img( $re ) ) .href( "/ff", img($ff)) .&br
     . href( "/playlist", img($pls)) .&hFooter;
};

get '/playlist' => sub {
   my $hh    = request->host;
   my $out   = hHeader( "Playlist" );
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
     and return hHeader( "Random File", $hh ) . h(2,$randfile) . &hFooter;
   wf( $log, $randfile );
   playback($randfile);
};

get '/playnum/:id' => sub {
   stopit();
   $pn = 1;
   my $hh   = request->host;
   my $id   = route_parameters->get('id');
   my $file = $files[$id];
   fork
     and return hHeader( "Play FileNo", $hh ) . &br 
     . h(2,"Now Playing: $file" ) . &hFooter;
   wf( $log, $file );
   playback($file);
};

get '/stop' => sub {
   srand;
   my $hh = request->host;
   stopit();
   return hHeader( "Stop", $hh ) . &br 
   . h(2, "Stopping..." ) . &hFooter;
};

get '/ff' => sub {
   my $hh = request->host;
   my $fn = rf( $log, { chomp => 1 } );
   if ( -s $log ) {
      stopit();
      my $idx = ( ( &first( $fn, @files ) ) + 1 );
      wf( $log, $files[$idx] );
      fork
        and return hHeader( "Fast Forward", $hh ) . &br 
        . h( 2, "Skipping Track..." ) . &br . h( 3, "Next up: $files[$idx]" ) 
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

sub playback {
   my $in = shift;
   `pkill aplaymidi`;
   $in =~ s/(\W)/\\$1/g;
   midikill();
   `$apmargs $in`;
   bgplayback();
}

sub bgplayback {
   if ($pn) {
      my $fn = rf( $log, { chomp => 1 } );
      if ( -s $log ) {
         my $idx = ( ( &first( $fn, @files ) ) + 1 );
         if ( $idx <= $#files ) {
            my $next = $files[$idx];
            wf( $log, $next );
            `pkill aplaymidi`;
            $next =~ s/(\W)/\\$1/g;
            &midikill;
            `$apmargs $next`;
            &bgplayback;
         }
         else {
            &stopit;
         }
      }
      else {
         &stopit;
      }
   }
}

sub stopit {
   $pn = 0;
   wf( $log, "" );
   `pkill aplaymidi`;
   &midikill;
}

sub midikill {
   for ( 0 .. 9, "a" .. "f" ) {
      `amidi -S "00B${_}7B00"`;
      `amidi -S "00B${_}7900"`;
   }
}

sub rr {
   my @input  = @_;
   my $length = $#input + 1;
   $length = rand($length);
   $length = int $length;

   return $input[$length];
}

sub first {
   my ( $input, @list ) = @_;
   my $idx = first_index { $_ =~ /$input/ } @list;

   return $idx;
}

sub randfile {
   return rr(@files);
}

sub packimage {
   my $file = shift;
   my $fc   = rf( $file, { binmode => ":raw" } );

   return "data:image/png;base64," . encode_base64($fc);
}

sub hHeader {
   my $title = shift;
   my $ref   = shift;
   my $sleep = 3;

   my $out = "<HTML><HEAD><TITLE>MIDamp";
   ( $title =~ /(\d)$/ ) and $out .= " " or $out .= ": ";
   $out .= "$title</TITLE>";
   ($ref) and $out .= "<META http-equiv=refresh content=\"
    $sleep; url=http://$ref\">" or true;
   $out .= "</HEAD><BODY BGCOLOR=\"#000\"><FONT COLOR=\"#0D0\">
  <CENTER>";

   return $out;
}

sub hFooter {
   return "</CENTER></FONT></BODY></HTML>";
}

sub h {
 my $i = shift;
 return "<H$i>@_</H$i>";
}

sub href {
  my $ref = shift;
  my $inner = shift;
  return "<A HREF=\"$ref\">$inner</A>";
}

sub iframe { 
  my $p = shift;
  return "<IFRAME SRC=\"$p\" @_></IFRAME>"
}

sub img {
  return "<IMG SRC=\"@_\">";
}

sub br {
  return "<BR>";
}

start;
