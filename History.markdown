## [3.1.0] - 2025-10-08
### Added
- Configurable TLS/CRL verification for webhook requests:
  - `:bn_ssl_crl_check` => `:none` (default), `:leaf`, `:all`
  - `:bn_ssl_disable_crl` => legacy boolean kill-switch
  - `:bn_ssl_cert_file`, `:bn_ssl_cert_dir` => custom CA locations
- Default behavior keeps TLS peer verification **enabled** while **not** requiring CRLs,
  improving compatibility with Ruby 3.4+ and OpenSSL 3.x.

### Fixed
- Avoids `OpenSSL::SSL::SSLError (unable to get certificate CRL)` on environments where CRL checks are required
  but CRLs are not present.

### Notes
- If you enable CRL checking (`:leaf` or `:all`), ensure your environment provides the necessary CRLs.
  Ruby/OpenSSL does not fetch CRLs automatically.

## 1.3.4 / 2019-06-27

  * If no branch is specified, derive revision from HEAD (#29)

## 1.3.3 / 2016-07-19

  * Rename `revision` to `rev` to avoid collision with Capistrano method (#22)

## 1.3.2 / 2015-11-03

  * using ls-remote instead of rev-parse to fetch revision (#19)

## 1.3.1 / 2015-05-13

  * Fix missing emoji for color-enabled messages (#14)

## 1.3.0 / 2015-03-05

  * Don't show empty () if no revision found (#10)
  * Introduce `slack_destination` which can override the stage. (#12)

## 1.2.0 / 2015-02-27

  * Allow colored output to notifications (#9)
  * Add a `slack:failed` task. (#7)
  * Add the revision to the deploy stage message. (#6)
  * Remove default `before` and `after` hooks (#4)

## 1.1.0 / 2015-02-11

  * Override the application name with `:slack_app_name` (#1)

## 1.0.0 / 2015-02-06

  * Birthday!
