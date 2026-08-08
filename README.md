# Pinterest::URL::Normalizer

A dependency-free Perl module and CLI for parsing, classifying, and normalizing Pinterest URLs without network requests.

It supports Pin, `pin.it`, profile, board, and Ideas URLs across Pinterest's canonical, mobile, regional-subdomain, and country-domain hosts. Tracking parameters and fragments are removed, but short links are never followed.

## Install

```sh
cpanm Pinterest::URL::Normalizer
```

## Library

```perl
use Pinterest::URL::Normalizer qw(parse_pinterest_url);

my $result = parse_pinterest_url(
  'https://pinterest.co.uk/pin/123456789/?utm_source=share'
);

print $result->{kind};            # pin
print $result->{normalized_url};  # https://www.pinterest.com/pin/123456789/
```

## CLI

```sh
pinterest-url-normalizer 'https://pinterest.de/example_user/travel/?x=1'
# https://www.pinterest.com/example_user/travel/
```

The package produces a canonical Pinterest URL for downstream tools. For the next browser-based image step, use the [Pinterest image downloader](https://savepinner.com/).

## Development

```sh
perl Makefile.PL
make test
make dist
```

## Security boundary

- HTTPS only
- no credentials or non-standard ports
- no DNS lookup, HTTP request, redirect following, or media download
- unsupported and lookalike hosts are rejected

## License

MIT
