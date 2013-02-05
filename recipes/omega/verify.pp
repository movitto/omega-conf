# Recipe to verify omega installation as setup by omega.pp

# Verify required services are running
  service { ['httpd', 'rabbitmq-server', 'sshd', 'mysql-server', 'omega-server']:
            ensure => 'running' }

# Install dependencies
  package { 'curl':
            ensure => 'installed' }

# verify site is active and has correct content
  exec { "get-omega-www":
         command => '/usr/bin/curl http://localhost/womega > /tmp/verify-omega-www',
         require => Package['curl'] }

  # TODO use xpath
  exec { "verify-omega-www":
         command => '/usr/bin/false',
         require => Exec['get-omega-www'] }

# verify mediawiki is active and has correct content
  exec { "get-mediawiki-www":
         command => '/usr/bin/curl http://localhost/wiki > /tmp/verify-omega-wiki',
         require => Package['curl'] }

  # TODO use xpath
  exec { "verify-mediawiki-www":
         command => '/usr/bin/false',
         require => Exec['get-mediawiki-www'] }

# TODO ensure necessary firewall ports are open

# TODO verify we can connect to game server
