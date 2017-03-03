use strict;
use warnings;
use Data::Dumper;

=head1
amiga ascii 2 svg

by venam
https://venam.nixers.net
https://github.com/venam
=cut

=head2
Usage: perl $0 ascii > output.svg
=cut
=head3
A bit inspired by:
https://github.com/haliphax/ascii.js
https://ivanceras.github.io/elm-examples/elm-bot-lines/
=cut
=head3
Welcome to a horribly put together script.

I won't polish it further, enjoy!
=cut


unless (scalar(@ARGV)) {
    print "Usage: perl $0 ascii > output.svg\n";
    exit;
}

open (my $fh, $ARGV[0]) or die $!;

my $font_name = 'Topaz a600a1200a400';
my $pixel_size = 12;
my %colorscheme = (
    'black'     => '#342f28',
    'red'       => '#a36f48',
    'green'     => '#9b9630',
    'yellow'    => '#b68740',
    'cyan'      => '#8e8e72',
    'magenta'   => '#b68c7c',
    'blue'      => '#7c7b6f',
    'white'     => '#dac78b',
    'l_black'   => '#606747',
    'l_red'     => '#c8623e',
    'l_green'   => '#a0bc30',
    'l_yellow'  => '#be8136',
    'l_cyan'    => '#7e9f86',
    'l_magenta' => '#a06f6a',
    'l_blue'    => '#595D64',
    'l_white'   => '#eaddc5'
);
my @colors_index = ('black','red','green','yellow','cyan','magenta','blue','white');
my $default_background = '#1c1c1a';
my $pixel_hor_size = $pixel_size/2.0+1.15;
my $pixel_ver_size = $pixel_size+1.20;
my $start_x = $pixel_size/2.0;
my $start_y = $pixel_size+2;
my ($x,$y) = ($start_x,$start_y);
my $output = "";
my $max_width = 0;
my $max_height = 0;
#default to black colorscheme
my $fg_color = $colorscheme{'white'};
my $bg_color = 'none';
# Possible states are:
# escape -> found the start of escape \x1b
# enter_escape -> \[
# in_escape -> anything in between
# end_escape -> character that ends the escape, anything that isn't ;
# or digit usually C or m for forwarding cursor and color respectively
my $state = "normal";
# stores everything that has been captured so far in an escape
my $state_value = "";
my $bold = 0;


for (<$fh>) {

    $max_height++;

    my $char = $_;
    $char =~ s/\r//g;
    $char =~ s/\x1b\[\d+D//g;
    $char =~ s/\x1b\[\d+D//g;
    $char =~ s/\x1b\[A\n\x1b\[\d+C//g;
    $char =~ s/\x1a(?:.|\n)+$//g;
    $char =~ s/\x19\x00\x00.*$//g;

    my @line = split //, $char;
    my $width = 0;
    for (@line) {
        my $c = $_;
        $c =~ s/&/&amp;/g;
        $c =~ s/</&lt;/g;
        $c =~ s/>/&gt;/g;

        # change state
        if ($state eq 'enter_escape') {
            # it's the end of the parsing
            if ($c eq 'm' or $c eq 'C') {
                # reset the state to normal
                if ($c eq 'C') {
                    for (1..$state_value) {
                        $width++;
                        $x += $pixel_hor_size;
                    }
                }
                else {
                    my @cols = split /;/, $state_value;
                    my $fg_col = 'nil';
                    my $bg_col = 'nil';
                    for my $code (@cols) {
                        if ($code == 0) {
                            $fg_col = 7;
                            $bg_col = 0;
                            #$bold = 0;
                        }
                        elsif ($code == 1) {
                            $bold = 1;
                        }
                        elsif ($code == 22) {
                            $bold = 0;
                        }
                        elsif ($code >= 30 and $code <= 37) {
                            $fg_col = $code - 30;
                        }
                        elsif ($code == 39) {
                            $fg_col = 7;
                        }
                        elsif ( $code >= 40 and $code <= 47) {
                            $bg_col = $code - 40;
                        }
                        elsif ( $code == 49) {
                            $bg_col = 0;
                        }
                    }
                    unless ($fg_col eq 'nil') {
                        my $chosen_col = $colors_index[$fg_col];
                        $chosen_col = 'l_'.$chosen_col if ($bold == 1);
                        $fg_color = $colorscheme{$chosen_col};
                    }
                }
                $state = 'normal';
                $state_value = '';
                next;
            }
            else {
                $state_value .= $c;
                next;
            }
        }
        if ($state eq 'escape') {
            if (my $a = ($c =~ /(\[)/)) {
                $state = "enter_escape";
                next;
            }
        }
        # we encounter an escape character
        if (my $a = ($c =~ /(\x1b)/)) {
            $state = "escape";
            next;
        }

        $width++;
        $output .= "<text fill='$fg_color' x='$x' y='$y' style='font-family:$font_name;'>
    ";
        $output .= "$c";
        $output .= "</text>";
        $x += $pixel_hor_size;
    }
    $max_width = $width if ($width > $max_width);
    $output .= "\n";
    $x = $start_x;
    $y += $pixel_ver_size;
}
$max_height++;
$max_width++;

$max_height *= $pixel_ver_size;
$max_width  *= $pixel_hor_size;

$output = "<?xml version='1.0' encoding='utf-8' standalone='no'?>
<!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>

<svg
    version='1.1'
    width='$max_width'
    height='$max_height'
    style='background-color: $default_background;'
    xmlns='http://www.w3.org/2000/svg'>

<g style='font-size: ${pixel_size}px'>".$output;


$output .=  "</g>\n"."</svg>";
print $output;

1;
