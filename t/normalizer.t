use 5.014;
use strict;
use warnings;
use Test::More;

use Pinterest::URL::Normalizer qw(
  is_pinterest_host
  is_pinterest_url
  normalize_pinterest_url
  parse_pinterest_url
);

my $pin = parse_pinterest_url(
  '  https://pinterest.co.uk/pin/123456789/?utm_source=share#fragment  '
);
is($pin->{kind}, 'pin', 'classifies a Pin URL');
is($pin->{pin_id}, '123456789', 'extracts the Pin ID');
is(
  $pin->{normalized_url},
  'https://www.pinterest.com/pin/123456789/',
  'normalizes regional Pin URLs and strips tracking data'
);

my $slugged_pin = parse_pinterest_url(
  'https://www.pinterest.com/pin/example-title--987654321/related/'
);
is($slugged_pin->{pin_id}, '987654321', 'extracts ID from a slugged Pin path');

my $short = parse_pinterest_url('https://pin.it/AbC123?utm_source=copy_link');
is($short->{kind}, 'short', 'classifies a short URL without following it');
is($short->{shortcode}, 'AbC123', 'extracts the short code');
is($short->{normalized_url}, 'https://pin.it/AbC123/', 'normalizes a short URL');

my $profile = parse_pinterest_url('https://m.pinterest.com/example_user/');
is($profile->{kind}, 'profile', 'classifies a profile URL');
is($profile->{username}, 'example_user', 'extracts a username');

my $board = parse_pinterest_url('https://fr.pinterest.com/example_user/travel-ideas/');
is($board->{kind}, 'board', 'classifies a board URL');
is($board->{board_slug}, 'travel-ideas', 'extracts a board slug');

my $ideas = parse_pinterest_url('https://www.pinterest.com/ideas/summer-style/123456/');
is($ideas->{kind}, 'ideas', 'classifies an Ideas URL');
is($ideas->{idea_id}, '123456', 'extracts an Ideas ID');

is(
  normalize_pinterest_url('https://pinterest.de/example_user/my-board/?x=1'),
  'https://www.pinterest.com/example_user/my-board/',
  'normalizes through the convenience function'
);

ok(is_pinterest_host('WWW.PINTEREST.COM'), 'host checks are case-insensitive');
ok(is_pinterest_host('pinterest.com.br'), 'supports country domains');
ok(!is_pinterest_host('pinterest.example.com'), 'rejects lookalike hosts');

ok(is_pinterest_url('https://www.pinterest.com/pin/1/'), 'boolean validator accepts Pins');
ok(!is_pinterest_url('http://www.pinterest.com/pin/1/'), 'rejects HTTP');
ok(!is_pinterest_url('https://example.com/pin/1/'), 'rejects non-Pinterest hosts');
ok(!is_pinterest_url('https://user:pass@www.pinterest.com/pin/1/'), 'rejects credentials');
ok(!is_pinterest_url('https://www.pinterest.com:444/pin/1/'), 'rejects non-standard ports');
ok(!is_pinterest_url('https://www.pinterest.com/search/pins/'), 'rejects reserved paths');

eval { parse_pinterest_url('https://example.com/pin/1/') };
my $error = $@;
ok(ref($error) eq 'Pinterest::URL::Normalizer::Error', 'throws a structured error');
is($error->code, 'INVALID_URL', 'structured error exposes a stable code');

done_testing;
