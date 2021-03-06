# Main Omega Puppet Recipe

$selinux_enabled       = true
$omega_hosted_release  = 'http://raw.github.com/movitto/omega-conf/master/release'
$omega_private_release = 'puppet:///modules/omega/private'
$omega_public_release  = 'puppet:///modules/omega/public'

# Files
# This recipe assumes the following files are accessible:
#
#   $omega_hosted_release/omega.rpm
#   $omega_hosted_release/omega-doc.rpm
#
#   $omega_public_release/httpd.conf
#   $omega_public_release/iptables
#   $omega_public_release/static-site.tgz
#
#   $omega_private_release/omega.yml
#   $omega_private_release/omega_backup-id_rsa.pub
#   $omega_private_release/omega.js

### Helpers

define expand_tarball($dest) {
  exec { "expand_tarball_$title":
    command => "/usr/bin/tar -xzvf $title",
    cwd => $dest }
}

### Install rjr/omega dependencies
  $all_omega_deps = ['activesupport', 'rjr', 'em-websocket',
                     'eventmachine_httpserver', 'em-http-request',
                     'em-websocket-client', 'amqp', 'pry',
                     'rubygem-curb']

  package {'rjr':
            ensure => 'installed',
            provider => 'gem',
            require => Package['ruby-devel', 'openssl-devel', 'gcc-c++', 'make']}

  package {'activesupport':
            ensure => 'installed',
            provider => 'gem',
            require => Package['rjr']}

  package {'em-websocket':
           provider => 'gem',
           require => Package['rjr']}

  package {'eventmachine_httpserver':
           ensure => '0.2.1',
           provider => 'gem',
           require => Package['rjr']}

  package {'em-http-request':
           ensure => '1.0.3',
           provider => 'gem',
           require => Package['rjr']}

  package {'em-websocket-client':
           ensure => '0.1.1',
           provider => 'gem',
           require => Package['rjr']}

  package {'amqp':
           provider => 'gem',
           require => Package['rjr']}

  package {'pry':
           ensure => '0.9.12',
           provider => 'gem' }

  package {'json':
           ensure => '1.7.5',
           provider => 'gem',
           require => Package['rjr']}

  package {['ruby-devel',
            'openssl-devel',
            'gcc-c++',
            'make',
            'rubygem-curb',
            'rabbitmq-server',
            'httpd']:
            ensure => 'installed',
            provider => 'yum' }

### Install omega & site
  package {"omega":
            source => "$omega_hosted_release/omega.rpm",
            ensure => 'installed',
            provider => 'rpm',
            require => Package[$all_omega_deps] }

  package {"omega-doc":
            source => "$omega_hosted_release/omega-doc.rpm",
            ensure => 'installed',
            provider => 'rpm',
            require => Package['omega'] }


   # FIXME outdated not that content has been split out, copy
   # site from rpm, and content from $omega_public_release
   file {'/var/www/omega.tgz':
         source => "$omega_public_release/static-site.tgz",
         ensure => "file",
         require => Package['httpd']}

   # TODO remove file after
   expand_tarball{'/var/www/omega.tgz':
                  dest  => '/var/www/',
                  require => File['/var/www/omega.tgz'] }

   file { '/var/www/omega/javascripts/omega/config.js':
          source => "$omega_private_release/omega.js",
          ensure => "file",
          require => Expand_tarball["/var/www/omega.tgz"]}

   file {'/var/www/omega':
         ensure => 'directory',
         owner  => 'apache',
         group  => 'apache',
         require => [Expand_tarball['/var/www/omega.tgz'], File["/var/www/omega/javascripts/omega/config.js"]]}

   exec{'omega_www_perms':
        command => '/usr/bin/chmod -R -w,g-w  /var/www/omega',
        require => [File['/var/www/omega'], Package['httpd']] }

   if($selinux_enabled){
     exec{'omega_www_context':
          command => '/usr/bin/chcon -R -v --type=httpd_sys_content_t /var/www/omega',
          require => [File['/var/www/omega'], Package['httpd']] }
   }

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
           
### Setup apache config
   file {'/etc/httpd/conf.d/omega.conf':
         source => "$omega_public_release/httpd.conf",
         ensure => "file",
         require => Package['httpd']}

   if($selinux_enabled){
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
   }

    service{'httpd':
            ensure  => 'running',
            enable  => true,
            require => File['/etc/httpd/conf.d/omega.conf'] }

### Seed Omega

    #exec{'seed_omega_universe':
    #     command => '/usr/share/omega/examples/environment.rb',
    #     environment => 'RUBYLIB=/usr/share/omega/lib',
    #     require => [Service['omega-server'], Package['omega-doc']]}
    #     unless  => ''}

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

### create omega-backup user, copy ssh key in place
   if($omega_private_release){
     exec{"add-backup-user":
          command => "/usr/sbin/adduser omega-backup",
          unless  => "/usr/bin/grep omega-backup /etc/passwd" }

     file{"/home/omega-backup/.ssh":
          ensure => "directory",
          require => Exec["add-backup-user"] }

     file{"/home/omega-backup/.ssh/authorized_keys2":
          ensure => 'file',
          source => "$omega_private_release/omega_backup-id_rsa.pub",
          require => File["/home/omega-backup/.ssh"] }
   }
