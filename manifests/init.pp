# Concourse Puppet module main class
#
# @summary This class installs and configures Concourse-CI (https://concourse-ci.org/).
#
# @example
#   include concourse
#
# @note For full environment variable configuration parameter documentation, run the appropriate concourse subcommand with --help:
#   concourse --help
#   concourse web --help
#   concourse worker --help
#
# @param node_type
#   Specifies the Concourse installation type. `web` or `worker will only install and configure a web or worker node. `standalone` will install both a web and a worker node.
#
# @param environment
#   Specifies an array of `CONCOURSE_*` environment variables that provide configuration for Concourse.
#
# @param proxy_server
#   Specifies proxy server to use for downloading Concourse. Note that configuring Concourse itself with proxy settings is done through the `environment` parameter.
#
# @param version
#   Specifies version of Concourse to download and install.
#
# @param install_fly
#   Specifies whether to install the fly cli binary.
#
# @param generate_tsa_host_key
#   Specifies whether to auto-generate the tsa_host_key.
#
# @param generate_session_signing_key
#   Specifies whether to auto-generate the session_signing_key.
#
# @param generate_worker_key
#   Specifies whether to auto-generate the worker key.
#
# @param upgrade_kernel
#   Specifies whether to install the ELRepo kernel repository and install the latest LTS Kernel. This defaults to true for RedHat 7 OS family.
#
# @param concourse_source
#   Specifies the download location for the Concourse binary.
#
# @param fly_source
#   Specifies the download location for the fly cli binary.
#
# @param worker_name
#   Specifies the name of the concourse worker.
#
class concourse (
  Enum['worker', 'web', 'standalone'] $node_type,
  Hash[Pattern[/^CONCOURSE_/, /^(http|https|no)_proxy$/], Variant[String, Boolean], 1] $environment,
  Optional[String] $proxy_server,
  String $version,
  Boolean $install_fly,
  Boolean $generate_tsa_host_key,
  Boolean $generate_session_signing_key,
  Boolean $generate_worker_key,
  Boolean $upgrade_kernel,
  Optional[Stdlib::Httpurl] $concourse_source,
  Optional[Stdlib::Httpurl] $fly_source,
  String $worker_name,
){

  case $version {
    /^4/: {
      $_concourse_source = pick($concourse_source, "https://github.com/concourse/concourse/releases/download/v${version}/concourse_linux_amd64")
      $_fly_source       = pick($fly_source, "https://github.com/concourse/concourse/releases/download/v${version}/fly_linux_amd64")
      $_concourse_binary = '/usr/local/bin/concourse'
    }
    /^5/: {
      $_concourse_source = pick($concourse_source, "https://github.com/concourse/concourse/releases/download/v${version}/concourse-${version}-linux-amd64.tgz")
      $_fly_source       = pick($fly_source, "https://github.com/concourse/concourse/releases/download/v${version}/fly-${version}-linux-amd64.tgz")
      $_concourse_binary = '/usr/local/concourse/bin/concourse'
    }
    default: { fail("Concourse version ${version} not supported yet.") }
  }

  class { 'concourse::install':
    version                      => $version,
    node_type                    => $node_type,
    concourse_source             => $_concourse_source,
    fly_source                   => $_fly_source,
    install_fly                  => $install_fly,
    proxy_server                 => $proxy_server,
    environment                  => $environment,
    generate_session_signing_key => $generate_session_signing_key,
    generate_tsa_host_key        => $generate_tsa_host_key,
    generate_worker_key          => $generate_worker_key,
    upgrade_kernel               => $upgrade_kernel,
  }
  contain 'concourse::install'

  class { 'concourse::config':
    node_type        => $node_type,
    environment      => $environment,
    concourse_binary => $_concourse_binary,
    worker_name      => $worker_name,
  }
  contain 'concourse::config'

  class { 'concourse::service':
    node_type   => $node_type,
  }
  contain 'concourse::service'

  Class['concourse::install']
  -> Class['concourse::config']
  ~> Class['concourse::service']

}
