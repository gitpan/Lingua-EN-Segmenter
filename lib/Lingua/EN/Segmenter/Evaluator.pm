package Lingua::EN::Segmenter::Evaluator;

=head1 NAME

Lingua::EN::Segmenter::Evaluator - Evaluate a segmenting method

=head1 SYNOPSIS

See L<Lingua::EN::Segmenter::TextTiling>

=head1 DESCRIPTION

See L<Lingua::EN::Segmenter::TextTiling>

=head1 EXTENDING

See L<Lingua::EN::Segmenter::TextTiling>

=head1 AUTHORS

David James <david@jamesgang.com>

=head1 SEE ALSO

L<Lingua::EN::Segmenter::TextTiling>, L<Lingua::EN::Segmenter::Evaluator>

=cut


$VERSION = 0.01;
@EXPORT_OK = qw(evaluate_segmenter);
use strict;
use base 'Class::Exporter';

# Create a new Evaluator object
sub new {
    my $self = shift;
    bless { 
        @_
    }, $self
}


# Evaluate the segmenter on a particular input
sub evaluate_segmenter {
    my ($self, $segmenter, $num_segments, $input) = @_;
    
    $self->{taken} = {}; 
       
    my $num_paragraphs = @{$segmenter->{splitter}->paragraph_breaks($input)};

    my $break = $self->{break} = $segmenter->{splitter}->segment_breaks($input);
    my $assigned = $self->{assigned} = $segmenter->segment($num_segments, $input);
    
    my @description = map { {
        para=>$_,
        true=>exists $break->{$_},
        label=>$assigned->{$_},
        strict=>exists $break->{$_} && exists $assigned->{$_},
        relaxed=>$self->relaxed_weight($_),
        very_relaxed=>$self->very_relaxed_weight($_),
    } } (0..$num_paragraphs-1);
        
    return @description;
}

# Get the weight of a particular index based on a relaxed scheme
sub relaxed_weight {
    my ($self, $i) = @_;
    my $assigned = $self->{assigned}{$i};
    my $break = $self->{break}{$i};
    if ($assigned and $break) {
        $self->take(1,"break",$i);
        $self->take(1,"assigned",$i);
        return 1;
    }
    if (defined $assigned) {
        if ($assigned =~ /L/ and $self->take(1,"break",$i-1) or
            $assigned =~ /R/ and $self->take(1,"break",$i+1)) {
            return 0.8;
        } elsif ($self->take(1,"break",$i-1) or $self->take(1,"break",$i+1)) {
            return 0.4;
        }
    } elsif (exists $self->{break}{$i}) {
        if ($self->take(1,"assigned",$i-1,"R") or 
            $self->take(1,"assigned",$i+1,"L")) {            
            return 0.8;
        } elsif ($self->take(1,"assigned",$i-1) or 
            $self->take(1,"assigned",$i+1)) {
            
            return 0.4;
        }
    }
    return 0;
}

# Get the weight of a particular index based on a very relaxed scheme
sub very_relaxed_weight {
    my ($self, $i) = @_;
    my $assigned = $self->{assigned}{$i};
    my $break = $self->{break}{$i};
    
    if ($assigned or $break) {
        foreach (-2..2) {
            $assigned ||= $self->take(2,"assigned",$i+$_);
            $break ||= $self->take(2,"break",$i+$_);
        }
    }
    return ($assigned and $break);
}

# Mark a particular index as used if it's not already used 
sub take {
    my ($self,$count,$which,$i,$req) = @_;
    if (!$self->{taken}{$count}{$which}{$i} and $self->{$which}{$i}) {
        if (!$req or $self->{$which}{$i} =~ /$req/) {
            $self->{taken}{$count}{$which}{$i}++;
            return 1;
            
        }
    }
    return;
}


1;

