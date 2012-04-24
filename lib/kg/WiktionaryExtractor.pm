=head1 NAME

kg::WiktionaryExtractor - Perl extension for blah blah blah

=head1 SYNOPSIS

  use kg::WiktionaryExtractor;
  $we = kg::WiktionaryExtractor->new();
  $table = $we->get('kościół');
   
  # $table is now an arrayref struct, one row for each case:
  #
  #          [ 'nominative', 'dom', 'domy' ],
  #          [ 'genitive', 'domu', "domów" ],
  #          [ 'dative', 'domowi', 'domom' ],
  #          ...etc.

=head1 DESCRIPTION

Tired of navigating through wiktionary when I want to look up
polish grammar, especially on the phone or ipad.

=head1 METHODS

=cut

package kg::WiktionaryExtractor;

use 5.012003;
use strict;
use warnings;

use Data::Dump qw/dump/ ;
use HTML::TableExtract;
use LWP::UserAgent;

our $VERSION = 0.01;

=head2 new

Overrideable args are cache_dir and wiktionary_url.

=cut

sub new {
    my ($proto, %args) = @_;
    my $self = {
        cache_dir      => ( $args{cache_dir} ||  "/var/run/wiktionary-cache"),
        wiktionary_url => ( $args{wiktionary_url} || "http://en.wiktionary.org/wiki" ),
    };
    return bless $self, $proto;

}

=head2 get

This is the external method.

=cut

sub get {
    my ($self, $word) = @_;

    $word =~ s/\P{IsAlpha}//g;
    $word =~ s/\.//g;
    $word = substr($word, 0, 50);

    $self->{got_from_cache} = 0; # for unit tests

    if (my $result = $self->read_from_cache($word)){
        $self->{got_from_cache} = 1;
        return $result;
    }else{
        my $html = $self->fetch_html($word) || return undef;;
        my $result = $self->get_table_data_from_html($html);
        $self->write_to_cache($word, $result);
        return $result;
    }
}

sub fetch_html {
    my ($self, $word) = @_;

    # $word has already been sanitized

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    # http://stackoverflow.com/questions/24546/why-cant-i-fetch-wikipedia-pages-with-lwpsimple
    $ua->agent("WiktionaryGrammar/$VERSION");

    my $response = $ua->get("$self->{wiktionary_url}/$word");

    if ($response->is_success) {
        return $response->decoded_content;  
    } else {
        $self->{error} = "nothing found at $self->{wiktionary_url}/$word";
        return undef;
    }
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
    # remove the 'sing, plural' row
    shift @table;

    return \@table;

}

sub write_to_cache {
    my ($self, $word, $table) = @_;

    # double paranoid security, since we already did this in get().
    # I could also MIME-encode the filename, but I like how the filenames
    # look with the accents
    $word =~ s/\P{IsAlpha}//g;
    $word =~ s/\.//g;
    $word =~ s{/}{}g;

    my $dir = $self->{cache_dir};
    open my $fh, ">", "$dir/$word" or die "can't open $dir/$word: $!";
    print $fh dump $table;
    close $fh || die "can't close $dir/$word: $!";
}

sub read_from_cache {
    my ($self, $word) = @_;

    my $dir = $self->{cache_dir};

    return undef unless -e "$dir/$word";

    my $s;
    open my $fh, "<", "$dir/$word" || die "can't open $dir/$word: $!";
    while (<$fh>){
        $s .= $_;
    }
    close $fh;
    return eval $s; # should really check return code...
}
    
1;
__END__



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
