# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include concourse
class concourse::service (
  $node_type,
){

  if $node_type == 'standalone' {
    ['web','worker'].each |$node| {
      service {"concourse-${node}":
        ensure => running,
        enable => true,
      }
    }
  } else {
    service {"concourse-${node_type}":
      ensure => running,
      enable => true,
    }
  }

}
