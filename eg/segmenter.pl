#!/local/bin/perl

use Lingua::EN::Segmenter::TextTiling;
use Lingua::EN::Segmenter::Baseline;
use Lingua::EN::Segmenter::Evaluator qw(evaluate_segmenter);
use Lingua::EN::Splitter;
use Math::HashSum qw(hashsum);

use File::Slurp;
use strict;

#####################################################
# Initialization
#####################################################

my $VERBOSE = shift @ARGV if $ARGV[0] eq "-v";
my @VERBOSE = $VERBOSE ? (VERBOSE=>1) : ();
my $baseline_segmenter = Lingua::EN::Segmenter::Baseline->new();
my $tiling_segmenter = Lingua::EN::Segmenter::TextTiling->new(@VERBOSE);
$baseline_segmenter->set_paragraph_regexp(qr/<p no=\d+ ?(segment_break)?>/);
$tiling_segmenter->set_paragraph_regexp(qr/<p no=\d+ ?(segment_break)?>/);

my (@baseline, @tiling);

my $num = @ARGV;

unless (@ARGV) {
    die "Usage: $0 [ -v ] Segment/S*";
}

my %segment_stats;

#####################################################
# Segmentation
#####################################################

foreach (@ARGV) {
    my $input = read_file($_);
    print "\nFile name: $_\n\n";
 
    my %label = map { $_->{para}=>$_ } evaluate_segmenter($tiling_segmenter,20,$input);
    my %baseline = map { $_->{para}=>$_ } evaluate_segmenter($baseline_segmenter,20,$input);
      
    # Verbose output of labels 
    if ($VERBOSE) {
        my $splitter = new Lingua::EN::Splitter();
        my $num_paragraphs = @{$splitter->paragraph_breaks($input)};

        print "Para  True  Label  Str  Rel  VRel  Bsln  Str  Rel  VRel\n";
        
        foreach my $i (0..$num_paragraphs-1) {
            my @label = map { $label{$i}{$_} || 0 } 
                qw(para true label strict relaxed very_relaxed);
            
            my @baseline = map { $baseline{$i}{$_} || 0 } 
                qw(label strict relaxed very_relaxed);
    
            relabel($baseline[0]);
            relabel($label[2]);
                
            printf "%4d  %4d  %5s  %3d  %3.1f  %4d%6s  %3d  %3.1f  %4d\n", 
                @label, @baseline;
                
        }
                
        print "\n";
    }

    push @baseline, values %baseline;
    push @tiling, values %label;
    
    printf "Results from TextTiling algorithm:
  Strict scoring:       %2d%% recall, %2d%% precision
  Relaxed scoring:      %2d%% recall, %2d%% precision
  V. relaxed scoring:   %2d%% recall, %2d%% precision

Results from baseline (random) algorithm:
  Strict scoring:       %2d%% recall, %2d%% precision
  Relaxed scoring:      %2d%% recall, %2d%% precision
  V. relaxed scoring:   %2d%% recall, %2d%% precision
", calc_stats(values %label), calc_stats(values %baseline);    
}

print "Segmented $num files.\n\n";


#####################################################
# Average Results
#####################################################

printf "Average results from TextTiling algorithm:
  Strict scoring:        Average recall = %4.1f%%, average precision = %4.1f%%
  Relaxed scoring:       Average recall = %4.1f%%, average precision = %4.1f%%
  V. relaxed scoring:    Average recall = %4.1f%%, average precision = %4.1f%%

Average results from baseline (random) algorithm:
  Strict scoring:        Average recall = %4.1f%%, average precision = %4.1f%%
  Relaxed scoring:       Average recall = %4.1f%%, average precision = %4.1f%%
  V. relaxed scoring:    Average recall = %4.1f%%, average precision = %4.1f%%
", calc_stats(@tiling), calc_stats(@baseline);    


#############################################################################
# Calculate precision and recall for strict, relaxed, very_relaxed
#############################################################################
sub calc_stats {    
    my %sum = hashsum map { %$_ } @_;

    # Ensure relaxed counts don't double-count
    $sum{relaxed} -= ($sum{relaxed} - $sum{strict})/2;
    $sum{very_relaxed} -= ($sum{very_relaxed} - $sum{strict})/2;

    # Ensure "R" and "L" count as categories
    $sum{label} = grep { $_->{label} } @_;


    return map { 100*$sum{$_}/$sum{true}, 100*$sum{$_}/$sum{label} } 
        qw(strict relaxed very_relaxed);
}


# Convert labels into preferred format
sub relabel {
    if (length($_[0]) > 1 and $_[0] =~ /L/ and 
        $_[0] =~ /R/) {
        $_[0] = "B";
    } else {
        $_[0] = substr($_[0],0,1);
    }
}
