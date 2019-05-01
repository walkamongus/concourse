# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include concourse
class concourse::install (
  $version,
  $node_type,
  $concourse_source,
  $fly_source,
  $install_fly,
  $proxy_server,
  $environment,
  $generate_session_signing_key,
  $generate_tsa_host_key,
  $generate_worker_key,
  $upgrade_kernel,
){

  if $upgrade_kernel {
    contain 'concourse::repo::elrepo'
    file_line { 'update_sysconfig_kernel':
      path              => '/etc/sysconfig/kernel',
      line              => 'DEFAULTKERNEL=kernel-lt',
      match             => '^DEFAULTKERNEL=kernel\s*$',
      replace           => true,
      match_for_absence => false,
      require           => Class['concourse::repo::elrepo'],
    }
    package { 'kernel-lt':
      ensure  => present,
      require => File_line['update_sysconfig_kernel'],
    }
  }

  archive { 'concourse_package':
    ensure       => present,
    path         => '/tmp/concourse.tgz',
    extract      => true,
    extract_path => '/usr/local/',
    source       => $concourse_source,
    creates      => '/usr/local/concourse',
    cleanup      => true,
    proxy_server => $proxy_server,
  }

  archive { 'fly_package':
    ensure       => present,
    path         => '/tmp/fly.tgz',
    extract      => true,
    extract_path => '/usr/local/bin/',
    source       => '/usr/local/concourse/fly-assets/fly-linux-amd64.tgz',
    cleanup      => true,
    creates      => '/usr/local/bin/fly',
    require      => Archive['concourse_package'],
  }

  file {'/usr/local/bin/concourse':
    ensure  => link,
    target  => '/usr/local/concourse/bin/concourse',
    require => Archive['concourse_package'],
  }

  $_concourse_binary = '/usr/local/concourse/bin/concourse'

  exec { 'enable_concourse_execution':
    command   => "chmod 0755 ${_concourse_binary}",
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    unless    => "[ $(stat -c '%a' ${_concourse_binary}) == 755 ]",
    subscribe => Archive['concourse_package'],
  }

  $_gdc_binary = '/usr/local/concourse/bin/gdn'
  exec { 'enable_gdc_execution':
    command   => "chmod 0755 ${_gdc_binary}",
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    unless    => "[ $(stat -c '%a' ${_gdc_binary}) == 755 ]",
    subscribe => Archive['concourse_package'],
  }

  $_fly_binary = '/usr/local/bin/fly'
  exec { 'enable_fly_execution':
    command   => "chmod 0755 ${_fly_binary}",
    path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    unless    => "[ $(stat -c '%a' ${_fly_binary}) == 755 ]",
    subscribe => Archive['concourse_package'],
  }

  file { '/etc/concourse':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  if 'CONCOURSE_WORK_DIR' in keys($environment) {
    exec { "mkdir -p ${environment['CONCOURSE_WORK_DIR']}":
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      creates => $environment['CONCOURSE_WORK_DIR'],
      before  => File[$environment['CONCOURSE_WORK_DIR']],
    }

    file { $environment['CONCOURSE_WORK_DIR']:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  if $generate_session_signing_key {
    $_session_signing_key     = $environment['CONCOURSE_SESSION_SIGNING_KEY']
    $_session_signing_key_dir = dirname($_session_signing_key)
    exec { 'make_session_signing_key_dir':
      command => "mkdir -p ${_session_signing_key_dir}",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      creates => $_session_signing_key_dir,
      before  => Exec['generate_session_signing_key'],
    }
    exec {'generate_session_signing_key':
      command => "ssh-keygen -t rsa -q -N '' -f ${_session_signing_key}",
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      creates => $_session_signing_key,
      before  => File[$_session_signing_key],
    }
    file { $_session_signing_key:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0640',
    }
  }

  if $generate_tsa_host_key {
    $_tsa_host_key     = $environment['CONCOURSE_TSA_HOST_KEY']
    $_tsa_host_key_dir = dirname($_tsa_host_key)
    exec { 'make_tsa_host_key_dir':
      command => "mkdir -p ${_tsa_host_key_dir}",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      creates => $_tsa_host_key_dir,
      before  => Exec['generate_tsa_host_key'],
    }
    exec {'generate_tsa_host_key':
      command => "ssh-keygen -t rsa -q -N '' -f ${_tsa_host_key}",
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      creates => $_tsa_host_key,
      before  => File[$_tsa_host_key],
    }
    file { $_tsa_host_key:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0640',
    }
  }

  if $generate_worker_key {
    $_worker_key     = $environment['CONCOURSE_TSA_WORKER_PRIVATE_KEY']
    $_worker_key_dir = dirname($_worker_key)
    exec { 'make_worker_key_dir':
      command => "mkdir -p ${_worker_key_dir}",
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      creates => $_worker_key_dir,
      before  => Exec['generate_worker_key'],
    }
    exec {'generate_worker_key':
      command => "ssh-keygen -t rsa -q -N '' -f ${_worker_key}",
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      creates => $_worker_key,
      before  => File[$_worker_key],
    }
    file { $_worker_key:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0640',
    }
  }

  if $node_type == 'standalone' and $generate_worker_key {
    exec {'authorize_worker_key':
      command => "cp ${environment['CONCOURSE_TSA_WORKER_PRIVATE_KEY']}.pub \
${environment['CONCOURSE_TSA_AUTHORIZED_KEYS']}",
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      creates => $environment['CONCOURSE_TSA_AUTHORIZED_KEYS'],
      require => Exec['generate_worker_key'],
    }
  }

}
