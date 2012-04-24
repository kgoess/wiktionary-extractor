#!/usr/bin/perl

use strict;
use kg::WiktionaryExtractor;
use Template;
use CGI;

my $q = new CGI;

my $html = <<EOL;
<html>
<head><title>polish cases from wiktionary</title></head>
<body>
<form method="get" action="http://www.goess.org/cgi-bin/wiktionary.cgi">
<input type="text" name="word">
</form>

<table>
[% FOREACH row IN table %]
<tr>
    [% FOREACH item IN row %]
    <td>[% item | html %]</td>
    [% END %]
</tr>
[% END %]
</table>

</html>
EOL

my $we = kg::WiktionaryExtractor->new;
my $results;
if (my $word = $q->param('word')){
    $results = $we->get($word);
}

my $tt = Template->new();

my $output;
$tt->process(\$html, {table => $results}, \$output)
   || die $tt->error();

print $q->header;
print $output;


