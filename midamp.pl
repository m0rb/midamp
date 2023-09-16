#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Dancer2;
use MIME::Base64;
use List::MoreUtils qw(first_index);
use File::Slurp qw(:all);

my @files = `ls *.mid *.MID`;

my $apmargs = "/usr/bin/aplaymidi -p16:0";
my $randfile;

my $play     = "images/play.png";
my $stop     = "images/stop.png";
my $playlist = "images/pls.png";
my $forward  = "images/ff.png";
my $rewind   = "images/rewind.png";

my $log      = "log.txt";

our $pn = 0;

get '/' => sub {
   srand;
   srand;
   my $hh = request->host;
   my $output = rf($log,{chomp=>1});

   my $pi  = packimage($play);
   my $si  = packimage($stop);
   my $pls = packimage($playlist);
   my $ff  = packimage($forward);
   my $re  = packimage($rewind);

   return &hHeader($hh).
   "<BR><BR><h3>NOW PLAYING: $output</h3><BR><BR><A HREF=\"/playrandom\">
   <IMG SRC=\"$pi\"></A><A HREF=\"/stop\"><img src=\"$si\"></A>
   <A HREF=\"/rewind\"><IMG SRC=\"$re\"></A><A HREF=\"/ff\"><IMG SRC=\"$ff\">
   </A><BR><A HREF=\"/playlist\"><IMG SRC=\"$pls\"></A><BR>".&hFooter;
};

get '/playlist' => sub {
   my $hh = request->host;
   my $outbuf = &hHeader("Playlist");
   my $index = 0;
   foreach (@files) {
      $outbuf .= "<a href=\"http://$hh/playnum/$index\">$index: $_</a><br>\n";
      $index++;
   }
   $outbuf .= &hFooter;
   return $outbuf;
};

get '/playrandom' => sub {
   srand;
   stopit();
   $pn = 1;
   my $hh = request->host;
   $randfile = randfile();
   fork
     and return
     &hHeader("Random File",$hh).
     "<H2>$randfile</H2>".
     &hFooter;
   wf($log,$randfile);
   playback($randfile);
};

get '/playnum/:id' => sub {
   stopit();
   $pn = 1;
   my $hh   = request->host;
   my $id   = route_parameters->get('id');
   my $file = $files[$id];
   fork
     and return
   &hHeader("Play FileNo",$hh).
   "<BR><H2>Now Playing: $file</H2>".
   &hFooter;
   wf($log,$file);
   playback($file);
};

get '/stop' => sub {
   srand;
   my $hh = request->host;
   stopit();
   return
   &hHeader("Stop",$hh)."<BR><H2>Stopping...</H2>".&hFooter;
};

get '/ff' => sub {
  my $hh = request->host;
  my $fn = rf($log,{chomp=>1});
  if ( -s $log ) {
  stopit();
  my $idx = first($fn,@files)++;
  wf($log,$files[$idx]);
  fork 
      and return &hHeader("Fast Forward",$hh).
  "<BR><H2>Skipping Track...</H2><BR><H3>Next up: $files[$idx]</H3>".
  &hFooter;
  playback($files[$idx]);
  }
};

get '/rewind' => sub {
  my $hh = request->host;
  my $fn = rf($log,{chomp=>1});
  if ( -s $log ) {
  stopit();
  fork 
      and return &hHeader("Rewinding...",$hh).&hFooter;
  playback($fn);
  }
};


sub playback {
   my $in = shift;
   `pkill aplaymidi`;
   midikill();
   $in =~ s/(\W)/\\$1/g;
   midikill();
   `$apmargs $in`;
   bgplayback();
};

sub bgplayback {
   if ($pn) {
      my $fn = rf($log,{chomp=>1});
      if ( -s $log ) {
         my $idx = &first($fn,@files)++;
         if ( $idx <= $#files ) {
            my $next = $files[$idx];
            wf($log,$next);
            `pkill aplaymidi`;
            midikill();
            $next =~ s/(\W)/\\$1/g;
            midikill();
            `$apmargs $next`;
            bgplayback();
         }
         else {
            stopit();
         }
      }
      else {
         stopit();
      }
   }
};

sub stopit {
   $pn = 0;
   wf($log,"");
   `pkill aplaymidi`;
   midikill();
};

sub midikill {
for(my $i=0;$i<16;$i++) {
my $b = sprintf("%x",$i);
`amidi -S "00B${b}7B00"`;
`amidi -S "00B${b}7900"`;
  }
}


sub rr {
   my @input  = @_;
   my $length = $#input + 1;
   $length = rand($length);
   $length = int $length;
   return $input[$length];
};

sub first {
  my ($input,@list) = @_;
  my $idx = first_index { $_ =~ /$input/ } @list;
  return $idx;
};

sub randfile {
   return rr(@files);
};

sub packimage {
   my $file = shift;
   my $fc = rf($file,{binmode=>":raw"});
   return "data:image/png;base64,".encode_base64($fc);
};

sub hHeader {
  my $title = shift;
  my $ref   = shift;
  my $sleep = 3;

  my $out   = "<HTML><HEAD><TITLE>MIDamp";
  ($title =~ /(\d)$/) and $out .= " " or $out .= ": ";
  $out .= "$title</TITLE>";
  ($ref) and $out .= "<META http-equiv=refresh content=\"
    $sleep; url=http://$ref\">" or true;
  $out  .= "</HEAD><BODY BGCOLOR=\"#000\"><FONT COLOR=\"#0D0\">
  <CENTER><H2>MIDamp</H2>";

  return $out;
};

sub hFooter {
     return "</CENTER></FONT></BODY></HTML>";
};

start;
