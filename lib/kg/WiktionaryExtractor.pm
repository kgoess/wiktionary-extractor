package kg::WiktionaryExtractor;

use 5.012003;
use strict;
use warnings;

use Data::Dumper ;
use HTML::TableExtract;

sub new {
    my ($proto, %args) = @_;
    my $self = {
        cache_dir => ( $args{cache_dir} ||  "/var/run/wiktionary-cache"),
    };
    return bless $self, $proto;

}

sub get {
    my ($self, $word) = @_;

    $word =~ s/\W//;
    $word =~ s/\.//;
    $word = substr($word, 0, 50);

    $self->{got_from_cache} = 0;

    if (my $result = $self->read_from_cache($word)){
        $self->{got_from_cache} = 1;
        return $result;
    }else{
        my $html = $self->fetch_html($word);
        my $result = $self->get_table_data_from_html($html);
        $self->write_to_cache($result);
        return $result;
    }
}

sub fetch_html {
    ...
}
sub get_table_data_from_html {
    my ($self, $html) = @_;

    my ($polish_html) = $html =~ m{(<span [^>]+ id="Polish" .+?  ) (?: <h2 | $ ) }xs;
    return undef unless $polish_html;
    my $te = HTML::TableExtract->new( attribs => { class => "inflection-table" });
    $te->parse($polish_html);
    my $declension;
    foreach my $ts ($te->tables) {
        $declension = $ts;
        last;
    }
    die "couldn't find declension data in html"
        unless $declension;
    my @table;
    foreach my $row ($declension->rows){
        #print "row is @$row\n";
        push @table, $row;
    }
    # remove 'sing, plural' row
    shift @table;

    return \@table;

}

sub write_to_cache {
    my ($self, $word, $table) = @_;

    # double paranoid security
    $word =~ s/\W//g;
    $word =~ s/\.//g;
    $word =~ s{/}{}g;

    my $dir = $self->{cache_dir};
    open my $fh, ">", "$dir/$word" or die "can't open $dir/$word: $!";
    print $fh Dumper $table;
    close $fh;
}

sub read_from_cache {
    my ($self, $word) = @_;

    my $dir = $self->{cache_dir};

    open my $fh, "<", "$dir/$word" || die "can't open $dir/$word: $!";
    my $s;
    while (<$fh>){
        $s .= $_;
    }
    our $VAR1;
    eval $s;
    return $VAR1;
}
    
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

kg::WiktionaryExtractor - Perl extension for blah blah blah

=head1 SYNOPSIS

  use kg::WiktionaryExtractor;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for kg::WiktionaryExtractor, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Kevin Goess, E<lt>kevin@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin Goess

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
