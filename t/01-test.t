
use strict;
use warnings;


use Test::More tests => 2;
use FindBin qw($Bin);
use Data::Dumper;

use kg::WiktionaryExtractor;

mkdir "$Bin/test-cache";
unlink "$Bin/test-cache/dom";

my $we = kg::WiktionaryExtractor->new( cache_dir => "$Bin/test-cache");

my $html = `cat $Bin/testinput.html`;

my $table = $we->get_table_data_from_html($html);

my $expected = [
          [ 'nominative', 'dom', 'domy' ],
          [ 'genitive', 'domu', 'domów' ],
          [ 'dative', 'domowi', 'domom' ],
          [ 'accusative', 'dom', 'domy' ],
          [ 'instrumental', 'domem', 'domami' ],
          [ 'locative', 'domu', 'domach' ],
          [ 'vocative', 'domu', 'domy' ]
        ];

is_deeply $table, $expected;

$we->write_to_cache("dom", $table);

my $from_cache = $we->read_from_cache("dom");

is_deeply ($from_cache, $expected);
