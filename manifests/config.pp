# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include concourse
class concourse::config (
  $node_type,
  $worker_name,
  $environment,
){

  $_name_env_var = "CONCOURSE_NAME=${worker_name}"
  $_env_vars = $environment.map |$key, $value| { "${key}=${value}" }

  file { "/etc/concourse/${node_type}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => join($_env_vars << $_name_env_var, "\n"),
  }

  if $node_type == 'standalone' {
    ['web','worker'].each |$node| {
      file { "${node}_unit":
        ensure  => file,
        path    => "/etc/systemd/system/concourse-${node}.service",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => epp('concourse/service/concourse.service.epp', {
          'node_type' => $node,
          'env_file'  => "/etc/concourse/${node_type}",
        }),
        notify  => Exec['concourse_systemd_daemon-reload'],
      }
    }
  } else {
    file { "${node_type}_unit":
      ensure  => file,
      path    => "/etc/systemd/system/concourse-${node_type}.service",
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp('concourse/service/concourse.service.epp', {
        'node_type' => $node_type,
      }),
      notify  => Exec['concourse_systemd_daemon-reload'],
    }
  }

  exec { 'concourse_systemd_daemon-reload':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
  }

}
