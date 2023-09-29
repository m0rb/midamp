use File::Slurp     qw(:all);
use List::MoreUtils qw(first_index);
use MIME::Base64;

sub playback {
   my $in = shift;
   chomp $in;
   `pkill aplaymidi`;
   $in =~ s/(\W)/\\$1/g;
   midikill($hwid);
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
            midikill($hwid);
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
   midikill($hwid);
}

sub midikill {
   for ( 0 .. 9, "a" .. "f" ) {
      `$amargs -S "00B${_}7B00"`;
      `$amargs -S "00B${_}7900"`;
   }
}

sub mididev {
   my $type  = shift;
   my %query = (
      port => {
         prog => "aplaymidi -l",
         reg  => '(\d):(\d)'
      },
      hwid => {
         prog => "amidi -l",
         reg  => '(\w):(\d)'
      }
   );

   my @find = grep { /@_/ } (`$query{$type}{prog}`);

   for (<@find>) {
      $_ =~ /$query{$type}{reg}/ and return $_;
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

1;
