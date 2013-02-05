# Omega Puppet Mediawiki Configuration

$omega_private_release = 'puppet:///modules/omega/private'

#   Set $omega_private_release to null to skip over mediawiki instantiation
#
#   $omega_private_release/mediawiki.conf
#   $omega_private_release/setup-mw-db.mysql
#   $omega_private_release/latest-mw-db.mysql
#   $omega_private_release/mediawiki-www.tgz
#   $omega_private_release/mediawiki-extensions.tgz
#   $omega_private_release/mediawiki-skins.tgz

### Helpers

define expand_tarball($dest) {
  exec { "expand_tarball_$title":
    command => "/usr/bin/tar -xzvf $title",
    cwd => $dest }
}

### Install mediawiki & dependencies

  package {['httpd',
            'mediawiki',
            'mysql-server',
            'php']:
            ensure => 'installed',
            provider => 'yum' }

  service{'httpd':
          ensure  => 'running',
          enable => true }


### Setup the mediawiki db

     file {'/etc/httpd/conf.d/mediawiki.conf':
           source => "$omega_private_release/mediawiki.conf",
           ensure => "file",
           require => Package['httpd'],
           notify => Service['httpd']}

     file { '/usr/share/mediawiki/omega':
            ensure => 'directory',
            require => Package['mediawiki'] }
     file {'/usr/share/mediawiki/omega/setup-mw-db.mysql':
           source => "$omega_private_release/setup-mw-db.mysql",
           ensure => "file",
           require => File["/usr/share/mediawiki/omega"]}

     file {'/usr/share/mediawiki/omega/latest-mw-db.mysql':
           source => "$omega_private_release/latest-mw-db.mysql",
           ensure => "file",
           require => File["/usr/share/mediawiki/omega"]}

    service{'mysqld':
            ensure  => 'running',
            enable => true,
            require => Package['mysql-server'] }

    exec{'create_mediawiki_db':
         command => '/usr/bin/mysql -u root < /usr/share/mediawiki/omega/setup-mw-db.mysql',
         unless  => '/usr/bin/test "`/usr/bin/mysql -u root -e \"show databases\" | grep wikidb`" != ""',
         require => [Service['mysqld'], File['/usr/share/mediawiki/omega/setup-mw-db.mysql']]}

    exec{'seed_mediawiki_db':
         command => '/usr/bin/mysql -u root wikidb < /usr/share/mediawiki/omega/latest-mw-db.mysql',
         unless  => '/usr/bin/test "`/usr/bin/mysql -u root wikidb -e \"show tables\" | grep page`" != ""',
         require => [Service['mysqld'], Exec['create_mediawiki_db'], File['/usr/share/mediawiki/omega/latest-mw-db.mysql']]}

### Setup mediawiki installation

    # should contain images, LocalSettings.php, and upload-content.php
    file {'/var/www/mediawiki-www.tgz':
          source => "$omega_private_release/mediawiki-www.tgz",
          ensure => "file" }

    expand_tarball{'/var/www/mediawiki-www.tgz':
                   dest  => '/var/www/',
                   require => [Package['mediawiki'],
                               File['/var/www/mediawiki-www.tgz']] }


    file {'/usr/share/mediawiki/mediawiki-extensions.tgz':
          source => "$omega_private_release/mediawiki-extensions.tgz",
          ensure => "file",
          require => Package['mediawiki']}

    expand_tarball{'/usr/share/mediawiki/mediawiki-extensions.tgz':
                   dest  => '/usr/share/mediawiki/',
                   require => File['/usr/share/mediawiki/mediawiki-extensions.tgz'] }
                               

    file {'/usr/share/mediawiki/mediawiki-skins.tgz':
          source => "$omega_private_release/mediawiki-skins.tgz",
          ensure => "file",
          require => Package['mediawiki']}

    expand_tarball{'/usr/share/mediawiki/mediawiki-skins.tgz':
                   dest  => '/usr/share/mediawiki/',
                   require => File['/usr/share/mediawiki/mediawiki-skins.tgz'] }
                               

    file{["/var/www/wiki/images",
          "/usr/share/mediawiki/skins",
          "/usr/share/mediawiki/extensions"]:
          ensure => 'directory',
          owner  => 'apache',
          group  => 'apache',
          recurse => true,
          require => Expand_tarball['/var/www/mediawiki-www.tgz',
                                   '/usr/share/mediawiki/mediawiki-extensions.tgz',
                                   '/usr/share/mediawiki/mediawiki-skins.tgz']}

    file{["/var/www/wiki/LocalSettings.php",
          "/var/www/wiki/upload-content.php"]:
          ensure => 'file',
          owner  => 'apache',
          group  => 'apache',
          mode   => '0400',
          require => Expand_tarball['/var/www/mediawiki-www.tgz']}

    exec{'mediawiki_www_context':
         command => '/usr/bin/chcon -v --type=httpd_mediawiki_rw_content_t \
                 /var/www/wiki/LocalSettings.php /var/www/wiki/upload-content.php',
         require => File['/var/www/wiki/LocalSettings.php',
                         '/var/www/wiki/upload-content.php'] }

    exec{'mediawiki_share_context':
         command => '/usr/bin/chcon -v -R --type=httpd_mediawiki_content_t /usr/share/mediawiki/extensions/',
         require => File['/usr/share/mediawiki/extensions'] }
