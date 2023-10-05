
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
   my $ref   = shift;
   my $inner = shift;
   return "<A HREF=\"$ref\">$inner</A>";
}

sub iframe {
   my $p = shift;
   return "<IFRAME SRC=\"$p\" @_></IFRAME>";
}

sub img {
   return "<IMG SRC=\"@_\">";
}

sub br {
   return "<BR>";
}

1;
