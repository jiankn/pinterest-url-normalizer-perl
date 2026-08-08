package Pinterest::URL::Normalizer;

use 5.014;
use strict;
use warnings;
use Exporter qw(import);

our $VERSION = '0.1.0';
our @EXPORT_OK = qw(
  is_pinterest_host
  is_pinterest_url
  normalize_pinterest_url
  parse_pinterest_url
);

my @COUNTRY_HOSTS = qw(
  pinterest.at pinterest.be pinterest.ca pinterest.ch pinterest.cl
  pinterest.co pinterest.co.kr pinterest.co.nz pinterest.co.uk
  pinterest.com.au pinterest.com.br pinterest.com.mx pinterest.com.pe
  pinterest.com.tr pinterest.cz pinterest.de pinterest.dk pinterest.es
  pinterest.fi pinterest.fr pinterest.gr pinterest.hu pinterest.id
  pinterest.ie pinterest.it pinterest.jp pinterest.nl pinterest.no
  pinterest.ph pinterest.pl pinterest.pt pinterest.ro pinterest.se
  pinterest.sk
);

my @REGIONAL_SUBDOMAINS = qw(
  at au be br ca ch cl co cz de dk es fi fr gr hu id ie it jp kr mx
  nl no nz pe ph pl pt ro se sk tr uk
);

my %PINTEREST_HOSTS = map { $_ => 1 } (
  'pinterest.com',
  'www.pinterest.com',
  'm.pinterest.com',
  @COUNTRY_HOSTS,
  (map { "www.$_" } @COUNTRY_HOSTS),
  (map { "$_.pinterest.com" } @REGIONAL_SUBDOMAINS),
);

my %RESERVED_FIRST_SEGMENTS = map { $_ => 1 } qw(
  business categories explore help ideas login logout oauth pin pin-builder
  resource search settings signup today topics
);

my $CANONICAL_HOST = 'www.pinterest.com';
my $SHORT_HOST = 'pin.it';

sub _throw {
  my ($code, $message) = @_;
  die Pinterest::URL::Normalizer::Error->new($code, $message);
}

sub _parse_https_url {
  my ($input) = @_;

  _throw('INVALID_URL', 'URL must be a string')
    if !defined($input) || ref($input);

  $input =~ s/^\s+//;
  $input =~ s/\s+$//;
  _throw('INVALID_URL', 'URL is empty or too long')
    if $input eq q{} || length($input) > 2048;

  my ($authority, $path) =
    $input =~ m{\Ahttps://([^/?#]+)(/[^?#]*)?(?:\?[^#]*)?(?:#.*)?\z}i;
  _throw('INVALID_URL', 'URL could not be parsed') if !defined $authority;
  _throw('INVALID_URL', 'Credentials are not supported') if $authority =~ /\@/;

  my ($host, $port) = $authority =~ /\A([A-Za-z0-9.-]+)(?::([0-9]+))?\z/;
  _throw('INVALID_URL', 'URL host could not be parsed') if !defined $host;
  _throw('INVALID_URL', 'Non-standard ports are not supported')
    if defined($port) && $port ne '443';

  $host = lc $host;
  $path = '/' if !defined($path) || $path eq q{};

  return ($input, $host, $path);
}

sub is_pinterest_host {
  my ($host) = @_;
  return 0 if !defined($host) || ref($host);
  return $PINTEREST_HOSTS{lc $host} ? 1 : 0;
}

sub parse_pinterest_url {
  my ($input) = @_;
  my ($original_url, $host, $path) = _parse_https_url($input);

  if ($host eq $SHORT_HOST) {
    my ($shortcode) = $path =~ m{\A/([A-Za-z0-9]{2,})/?\z};
    _throw('UNSUPPORTED_URL', 'Unsupported pin.it path')
      if !defined $shortcode;

    return {
      kind           => 'short',
      original_url   => $original_url,
      normalized_url => "https://$SHORT_HOST/$shortcode/",
      host           => $SHORT_HOST,
      shortcode      => $shortcode,
    };
  }

  _throw('INVALID_URL', 'Host is not an allowed Pinterest domain')
    if !is_pinterest_host($host);

  if ($path =~ m{\A/pin/(?:(\d{1,20})|[A-Za-z0-9][A-Za-z0-9_-]*--(\d{1,20}))(?:/[A-Za-z0-9_-]*)?/?\z}) {
    my $pin_id = defined($1) ? $1 : $2;
    return {
      kind           => 'pin',
      original_url   => $original_url,
      normalized_url => "https://$CANONICAL_HOST/pin/$pin_id/",
      host           => $CANONICAL_HOST,
      pin_id         => $pin_id,
    };
  }

  if ($path =~ m{\A/ideas/([A-Za-z0-9][A-Za-z0-9_-]*)/(\d{1,20})/?\z}) {
    my ($idea_slug, $idea_id) = ($1, $2);
    return {
      kind           => 'ideas',
      original_url   => $original_url,
      normalized_url => "https://$CANONICAL_HOST/ideas/$idea_slug/$idea_id/",
      host           => $CANONICAL_HOST,
      idea_slug      => $idea_slug,
      idea_id        => $idea_id,
    };
  }

  my @segments = grep { length $_ } split m{/}, $path;
  my $first_segment = @segments ? lc $segments[0] : q{};
  _throw('UNSUPPORTED_URL', 'Unsupported Pinterest path')
    if $first_segment eq q{} || $RESERVED_FIRST_SEGMENTS{$first_segment};

  if (@segments == 1 && $segments[0] =~ /\A[A-Za-z0-9_][A-Za-z0-9_.-]*\z/) {
    my $username = $segments[0];
    return {
      kind           => 'profile',
      original_url   => $original_url,
      normalized_url => "https://$CANONICAL_HOST/$username/",
      host           => $CANONICAL_HOST,
      username       => $username,
    };
  }

  if (
    @segments == 2
    && $segments[0] =~ /\A[A-Za-z0-9_][A-Za-z0-9_.-]*\z/
    && $segments[1] =~ /\A[A-Za-z0-9][A-Za-z0-9_-]*\z/
  ) {
    my ($username, $board_slug) = @segments;
    return {
      kind           => 'board',
      original_url   => $original_url,
      normalized_url => "https://$CANONICAL_HOST/$username/$board_slug/",
      host           => $CANONICAL_HOST,
      username       => $username,
      board_slug     => $board_slug,
    };
  }

  _throw('UNSUPPORTED_URL', 'Unsupported Pinterest path');
}

sub normalize_pinterest_url {
  my ($input) = @_;
  return parse_pinterest_url($input)->{normalized_url};
}

sub is_pinterest_url {
  my ($input) = @_;
  return 0 if !defined($input) || ref($input);
  return eval { parse_pinterest_url($input); 1 } ? 1 : 0;
}

package Pinterest::URL::Normalizer::Error;

use strict;
use warnings;
use overload q{""} => 'as_string', fallback => 1;

sub new {
  my ($class, $code, $message) = @_;
  return bless { code => $code, message => $message }, $class;
}

sub code { return $_[0]->{code}; }
sub message { return $_[0]->{message}; }
sub as_string { return $_[0]->{code} . ': ' . $_[0]->{message}; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pinterest::URL::Normalizer - Parse and normalize Pinterest URLs without network requests

=head1 SYNOPSIS

  use Pinterest::URL::Normalizer qw(
    is_pinterest_url
    normalize_pinterest_url
    parse_pinterest_url
  );

  my $parsed = parse_pinterest_url(
    'https://pinterest.co.uk/pin/123456789/?utm_source=share'
  );

  print $parsed->{kind};            # pin
  print $parsed->{normalized_url};  # https://www.pinterest.com/pin/123456789/

=head1 DESCRIPTION

This module validates and canonicalizes Pinterest Pin, short, profile, board,
and Ideas URLs locally. It never follows a short link or makes a network
request, so callers retain control over redirects and media retrieval.

The parser stops at a canonical Pinterest URL. When a user needs the next
browser-based media step, the L<Pinterest downloader|https://savepinner.com/pinterest-downloader/>
accepts that normalized URL.

=head1 FUNCTIONS

=head2 parse_pinterest_url

Returns a hash reference with C<kind>, C<original_url>, C<normalized_url>, and
type-specific fields. It throws a C<Pinterest::URL::Normalizer::Error> with
code C<INVALID_URL> or C<UNSUPPORTED_URL> when validation fails.

=head2 normalize_pinterest_url

Returns only the canonical URL.

=head2 is_pinterest_url

Returns a boolean and never throws.

=head2 is_pinterest_host

Checks the supported canonical, mobile, regional-subdomain, and country-domain
Pinterest hosts.

=head1 SECURITY

Only HTTPS URLs are accepted. Credentials and non-standard ports are rejected.
The module performs no DNS lookup, HTTP request, or redirect resolution.

=head1 LICENSE

MIT License.

=cut
