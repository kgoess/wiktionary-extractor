
use strict;
use warnings;


use Test::More tests => 9;
use FindBin qw($Bin);
use Data::Dump qw/dump/;
use Test::Mock::LWP;
use Encode qw/decode_utf8/;
use utf8;


$Mock_ua->mock( env_proxy => sub { 'whatever' } );
$Mock_ua->mock( agent => sub { 'mock ua'} );
$Mock_ua->mock( timeout => sub {} );

use kg::WiktionaryExtractor;

mkdir "$Bin/test-cache";
unlink "$Bin/test-cache/dom";
unlink "$Bin/test-cache/kościół";

my $we = kg::WiktionaryExtractor->new( cache_dir => "$Bin/test-cache");


my $html = do { local $/ = undef; open my $fh, "<:utf8" , "$Bin/testinput.html"; <$fh> };


my $table = $we->get_table_data_from_html($html);

my $expected = [
          [ 'nominative', 'dom', 'domy' ],
          [ 'genitive', 'domu', ("domów") ],

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

$Mock_response->mock( decoded_content => sub { local $/ = undef; open my $fh, "<:utf8" , "t/kościół.html"; <$fh> } );
$Mock_ua->mock( get => sub { HTTP::Response->new( 200 ) } );

my $result = $we->fetch_html('kościół');
ok $result || print STDERR $we->{error},"\n";

my $kosciol_expected = [
  [ "nominative", "kościół", "kościoły", ],
  [ "genitive", "kościoła", "kościołów", ],
  [ "dative", "kościołowi", "kościołom", ],
  [ "accusative", "kościół", "kościoły", ],
  [ "instrumental", "kościołem", "kościołami", ],
  ["locative", "kościele", "kościołach"],
  ["vocative", "kościele", "kościoły"],
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



