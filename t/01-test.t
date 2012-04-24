
use strict;
use warnings;


use Test::More tests => 9;
use FindBin qw($Bin);
use Data::Dump qw/dump/;
use Test::Mock::LWP;
use utf8;


$Mock_ua->mock( env_proxy => sub { 'whatever' } );
$Mock_ua->mock( agent => sub { 'mock ua'} );
$Mock_ua->mock( timeout => sub {} );

use kg::WiktionaryExtractor;

mkdir "$Bin/test-cache";
unlink "$Bin/test-cache/dom";
unlink "$Bin/test-cache/kościół";

my $we = kg::WiktionaryExtractor->new( cache_dir => "$Bin/test-cache");

my $html = `cat $Bin/testinput.html`;

my $table = $we->get_table_data_from_html($html);

my $expected = [
          [ 'nominative', 'dom', 'domy' ],
          [ 'genitive', 'domu', "dom\xC3\xB3w" ],

          [ 'dative', 'domowi', 'domom' ],
          [ 'accusative', 'dom', 'domy' ],
          [ 'instrumental', 'domem', 'domami' ],
          [ 'locative', 'domu', 'domach' ],
          [ 'vocative', 'domu', 'domy' ]
        ];

is_deeply $table, $expected;

#########################
# check cache round trip
$we->write_to_cache("dom", $table);

my $from_cache = $we->read_from_cache("dom");

is_deeply ($from_cache, $expected);


#####################
# test fetching

$Mock_response->mock( decoded_content => sub { `cat t/kościół.html` } );# totally unportable 
$Mock_ua->mock( get => sub { HTTP::Response->new( 200 ) } );

my $result = $we->fetch_html('kościół');
ok $result || print STDERR $we->{error},"\n";

my $kosciol_expected = [
  [ "nominative", "ko\xC5\x9Bci\xC3\xB3\xC5\x82", "ko\xC5\x9Bcio\xC5\x82y", ],
  [ "genitive", "ko\xC5\x9Bcio\xC5\x82a", "ko\xC5\x9Bcio\xC5\x82\xC3\xB3w", ],
  [ "dative", "ko\xC5\x9Bcio\xC5\x82owi", "ko\xC5\x9Bcio\xC5\x82om", ],
  [ "accusative", "ko\xC5\x9Bci\xC3\xB3\xC5\x82", "ko\xC5\x9Bcio\xC5\x82y", ],
  [ "instrumental", "ko\xC5\x9Bcio\xC5\x82em", "ko\xC5\x9Bcio\xC5\x82ami", ],
  ["locative", "ko\xC5\x9Bciele", "ko\xC5\x9Bcio\xC5\x82ach"],
  ["vocative", "ko\xC5\x9Bciele", "ko\xC5\x9Bcio\xC5\x82y"],
];

$table = $we->get_table_data_from_html($result);
ok $table;
is_deeply $table, $kosciol_expected or print STDERR dump($table);


############################
# test the overall get() method

unlink "$Bin/test-cache/kościół";
my $res1 = $we->get('kościół');
is_deeply($res1, $kosciol_expected) || print STDERR dump($res1);
ok ! $we->{got_from_cache};
$res1 = $we->get('kościół');
is_deeply($res1, $kosciol_expected) || print STDERR dump($res1);
ok $we->{got_from_cache};



