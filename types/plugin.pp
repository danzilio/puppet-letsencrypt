# @summary List of accepted plugins
type Letsencrypt::Plugin = Enum[
  'apache',
  'standalone',
  'webroot',
  'nginx',
  'dns-route53',
  'dns-google',
  'dns-cloudflare',
  'dns-rfc2136',
  'dns-ovh',
]
