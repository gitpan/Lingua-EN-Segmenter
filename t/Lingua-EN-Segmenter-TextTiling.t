#!/usr/bin/perl -w

use lib qw(t/lib);
use strict;
use Config;

use Test::More tests=>5;
use_ok ('Lingua::EN::Segmenter::TextTiling',qw(segments));
use lib '.';

my $text = <<EOT;
Lingua::EN::Segmenter is a useful module that allows text to be split up 
into words, paragraphs, segments, and tiles.

Paragraphs are by default indicated by blank lines. Known segment breaks are
indicated by a line with only the word "segment_break" in it.

The module detects paragraphs that are unrelated to each other by comparing 
the number of words per-paragraph that are related. The algorithm is designed
to work only on long segments.

SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 
reported from the scene.

EOT
  
my $num_segment_breaks = 1;
my @segments = segments($num_segment_breaks,$text);
is($segments[0],"Lingua::EN::Segmenter is a useful module that allows text to be split up 
into words, paragraphs, segments, and tiles.

Paragraphs are by default indicated by blank lines. Known segment breaks are
indicated by a line with only the word \"segment_break\" in it.

The module detects paragraphs that are unrelated to each other by comparing 
the number of words per-paragraph that are related. The algorithm is designed
to work only on long segments.");
is($segments[1],"SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 
reported from the scene.");

my $OS = $Config::Config{'osname'};

my $dir;

if (-e "eg/segmenter.pl") {
    $dir = ".";
} elsif (-e "../eg/segmenter.pl") {
    $dir = "..";
} else {
    die "Could not find eg/segmenter.pl!";
}

my $segment_evaluator = "$dir/eg/segmenter.pl";
my $segments = join " ", map { "$dir/eg/Segment/$_" } 
    qw(S01 S02 S03 S04 S05 S06 S07 S08 S09 S10);

warn("\n# Testing segmenter against database, this will take some time\n");

my $evaluation = `$Config{perlpath} -Mlib=lib -Mlib=../lib -Mlib=t/lib $segment_evaluator $segments`;
$evaluation =~ m/Average recall = ([\d\.]+)%, average precision = ([\d\.]+)%/;
my $recall = $1;
my $precision = $2;
ok($recall>60, "Recall on large database is greater than 60%");
ok($precision>57, "Recall on large database is greater than 57%");
