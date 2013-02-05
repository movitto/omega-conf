# Main Omega Puppet Recipe

#$omega_hosted_release  = 'http://github.com/movitto/omega-conf/release';
$omega_hosted_release  = 'http://projects.morsi.org/omega/public'
$omega_private_release = 'puppet:///modules/omega/private'
$omega_public_release  = 'puppet:///modules/omega/public'

# Files
# This recipe assumes the following files are accessible:
#
#   $omega_hosted_release/rubygem-rjr.rpm
#   $omega_hosted_release/omega.rpm
#   $omega_hosted_release/omega-doc.rpm
#
#   $omega_public_release/omega.conf
#   $omega_public_release/iptables
#   $omega_public_release/static-site.tgz
#
#   $omega_private_release/omega.yml
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

### Install omega
  package {['rubygem-json', 'rubygem-curb', 'rubygem-eventmachine',
            'rubygem-activesupport']:
            ensure => 'installed',
            provider => 'yum' }
            

  package {"rubygem-rjr":
            source => "$omega_hosted_release/rubygem-rjr.rpm",
            ensure => 'installed',
            provider => 'rpm',
            require => Package['rubygem-json',
                               'rubygem-curb',
                               'rubygem-eventmachine'] }

  package {"omega":
            source => "$omega_hosted_release/omega.rpm",
            ensure => 'installed',
            provider => 'rpm',
            require => Package['rubygem-rjr', 'rubygem-activesupport'] }

  package {"omega-doc":
            source => "$omega_hosted_release/omega-doc.rpm",
            ensure => 'installed',
            provider => 'rpm',
            require => Package['omega'] }

### Install rjr dependencies
  package {['ruby-devel',
            'openssl-devel',
            'gcc-c++']:
            ensure => 'installed',
            provider => 'yum' }

  package {['em-websocket',
            'isaac',
            'amqp',
            'eventmachine_httpserver']:
            ensure => 'installed',
            provider => 'gem',
            require  => Package['ruby-devel', 'openssl-devel', 'gcc-c++']}

### Install omega dependencies
  package {['rabbitmq-server',
            'httpd',
            'mysql-server',
            'mediawiki',
            'php']:
            ensure => 'installed',
            provider => 'yum' }

   file {'/var/www/omega.tgz':
         source => "$omega_public_release/static-site.tgz",
         ensure => "file" }

   expand_tarball{'/var/www/omega.tgz':
                  dest  => '/var/www/',
                  require => File['/var/www/omega.tgz'] }

   file {'/var/www/omega':
         ensure => 'directory',
         owner  => 'apache',
         group  => 'apache',
         require => Expand_tarball['/var/www/omega.tgz']}

   exec{'omega_www_perms':
        command => '/usr/bin/chmod -R -w,g-w  /var/www/omega',
        require => [File['/var/www/omega'], Package['httpd']] }

   exec{'omega_www_context':
        command => '/usr/bin/chcon -R -v --type=httpd_sys_content_t /var/www/omega',
        require => [File['/var/www/omega'], Package['httpd']] }

### Configure omega deps, start omega services
   exec{"disable_sudo_requiretty":
        command => "/usr/bin/sed -i 's/Defaults\s*requiretty//' /etc/sudoers" }

   if($omega_private_release){
     file{"/etc/omega.yml":
          source => "$omega_private_release/omega.yml",
          ensure => "file",
          owner  => "omega",
          group  => "omega",
          mode   => "0400",
          require => Package["omega"]
         }
   }else{
     file{"/etc/omega.yml":
          source => "/etc/omega.yml"}
   }

   service{'rabbitmq-server':
           ensure  => 'running',
           enable => true,
           require => Package['rabbitmq-server']}

   service{'omega-server':
           ensure  => 'running',
           enable => true,
           require => [Service['rabbitmq-server'],
                       Exec['disable_sudo_requiretty'],
                       File['/etc/omega.yml'],
                       Package["omega"]] }
           
### Setup the mediawiki db

   if($omega_private_release){
     file {'/usr/share/omega/examples/setup-mw-db.mysql':
           source => "$omega_private_release/setup-mw-db.mysql",
           ensure => "file",
           require => Package["omega-doc"]}

     file {'/usr/share/omega/examples/latest-mw-db.mysql':
           source => "$omega_private_release/latest-mw-db.mysql",
           ensure => "file",
           require => Package["omega-doc"]}

    service{'mysqld':
            ensure  => 'running',
            enable => true,
            require => Package['mysql-server'] }

    # will require user to manually answer prompts
    # TODO uncomment
    #exec{'/usr/bin/mysql_secure_installation':
    #     require => Service['mysqld']}

    exec{'create_mediawiki_db':
         command => '/usr/bin/mysql -u root < /usr/share/omega/examples/setup-mw-db.mysql',
         unless  => '/usr/bin/test "`/usr/bin/mysql -u root -e \"show databases\" | grep wikidb`" != ""',
         require => [Service['mysqld'], File['/usr/share/omega/examples/setup-mw-db.mysql']]}

    exec{'seed_mediawiki_db':
         command => '/usr/bin/mysql -u root wikidb < /usr/share/omega/examples/latest-mw-db.mysql',
         unless  => '/usr/bin/test "`/usr/bin/mysql -u root wikidb -e \"show tables\" | grep page`" != ""',
         require => [Service['mysqld'], Exec['create_mediawiki_db'], File['/usr/share/omega/examples/latest-mw-db.mysql']]}

### Setup mediawiki installation

    # should contain images, LocalSettings.php, and upload-content.php
    file {'/var/www/mediawiki-www.tgz':
          source => "$omega_private_release/mediawiki-www.tgz",
          ensure => "file" }

    expand_tarball{'/var/www/mediawiki-www.tgz':
                   dest  => '/var/www/wiki/',
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

  }


### Setup apache config
   file {'/etc/httpd/conf.d/omega.conf':
         source => "$omega_public_release/httpd.conf",
         ensure => "file",
         require => Package['httpd']}

    exec{'http_omega_conf_context':
         command => '/usr/bin/chcon -v --type=httpd_config_t /etc/httpd/conf.d/omega.conf',
         require => File['/etc/httpd/conf.d/omega.conf'],
         notify => Service['httpd']}

    exec{'http_user_content':
         command => '/usr/sbin/setsebool -P httpd_read_user_content 1',
         #timeout => 6000,
         require => Package['httpd'],
         notify => Service['httpd']}

    # allow httpd to connect to omega
    exec{'http_omega_port':
         command => '/usr/sbin/semanage port -a -t http_port_t -p tcp 8888',
         unless  => '/usr/bin/test "`/usr/sbin/semanage port -l | grep http_port_t | grep 8888`" != ""',
         require => [Package['httpd'], Service['httpd']] }

    service{'httpd':
            ensure  => 'running',
            enable => true }

### Seed Omega
    exec{'seed_omega_universe':
         command => '/usr/share/omega/examples/environment.rb',
         environment => 'RUBYLIB=/usr/share/omega/lib',
         require => Service['omega-server']}
         #unless  => ''}

    #exec{'/usr/share/omega/examples/users.rb Anubis sibuna Athena regular_user':
    #     environment => 'RUBYLIB="/usr/share/omega/lib"',
    #     require => Service['omega-server'],
    #     unless  => ''}

### Setup iptables, run ssh
   file {'/etc/sysconfig/iptables':
         source => "$omega_public_release/iptables",
         ensure => "file"}

    exec{'iptables-restore':
         command => '/usr/sbin/iptables-restore /etc/sysconfig/iptables',
         require => File['/etc/sysconfig/iptables']}

    service{'sshd':
            ensure => 'running',
            enable => 'true' }
