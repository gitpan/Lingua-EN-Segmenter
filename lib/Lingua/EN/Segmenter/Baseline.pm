# Baseline random segmenter
package Lingua::EN::Segmenter::Baseline;

=head1 NAME

Lingua::EN::Segmenter::Baseline - Segment text randomly for baseline purposes

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

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
=cut

$VERSION = 0.01;
use base 'Lingua::EN::Segmenter::TextTiling';    
use strict;

# Return random depth scores
sub smoothed_depth_scores {
    my ($self,$input) = @_;
    [ map { rand() } @{$self->SUPER::smoothed_depth_scores($input)} ]
}


1;
