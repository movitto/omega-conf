# Recipe to verify omega installation as setup by omega.pp

# Verify required services are running
  service { ['httpd', 'rabbitmq-server', 'sshd', 'mysqld', 'omega-server']:
            ensure => 'running' } # TODO just verify, do not start

# Install dependencies
  package { 'curl':
            ensure => 'installed' }

# verify site is active and has correct content
  exec { "get-omega-www":
         command => '/usr/bin/curl http://localhost/womega/ > /tmp/verify-omega-www',
         require => Package['curl'] }

  # TODO use xpath
  exec { "verify-omega-www":
         command => '/usr/bin/test "`/usr/bin/grep omega_canvas /tmp/verify-omega-www`" != ""',
         require => Exec['get-omega-www'] }

# verify mediawiki is active and has correct content
  exec { "get-mediawiki-www":
         command => '/usr/bin/curl -L http://localhost/wiki/ > /tmp/verify-omega-wiki',
         require => Package['curl'] }

  # TODO use xpath
  exec { "verify-mediawiki-www":
         command => '/usr/bin/test "`/usr/bin/grep "Welcome to.*omegaverse.info" /tmp/verify-omega-wiki`" != ""',
         require => Exec['get-mediawiki-www'] }

# ensure necessary firewall ports are open and being listended on
  exec { "verify-ssh-port-open":
         command => '/usr/bin/test "`/usr/sbin/iptables -nvL | /usr/bin/grep 22`" != ""' }

  exec { "verify-ssh-listening":
         command => '/usr/bin/test "`/usr/bin/netstat -nvlp | /usr/bin/grep 22`" != ""' }

  exec { "verify-omega-tcp-port":
         command => '/usr/bin/test "`/usr/sbin/iptables -nvL | /usr/bin/grep 8181`" != ""' }

  exec { "verify-omega-tcp-listening":
         command => '/usr/bin/test "`/usr/bin/netstat -nvlp | /usr/bin/grep 8181`" != ""' }

  exec { "verify-omega-http-port":
         command => '/usr/bin/test "`/usr/sbin/iptables -nvL | /usr/bin/grep 80`" != ""' }

  exec { "verify-omega-http-listening":
         command => '/usr/bin/test "`/usr/bin/netstat -nvlp | /usr/bin/grep 80`" != ""' }

  exec { "verify-omega-ws-port":
         command => '/usr/bin/test "`/usr/sbin/iptables -nvL | /usr/bin/grep 8080`" != ""' }

  exec { "verify-omega-ws-listening":
         command => '/usr/bin/test "`/usr/bin/netstat -nvlp | /usr/bin/grep 8080`" != ""' }

# verify we can connect to game server
  # TODO more involved verification (including auth and such)
  exec { "verify-connect-to-omega":
         command => '/usr/bin/test "`/usr/bin/curl http://localhost:8888 | /usr/bin/grep jsonrpc`" != ""' }
