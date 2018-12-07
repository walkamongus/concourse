# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include concourse
class concourse::repo::elrepo (
  Stdlib::Httpurl $elrepo_baseurl = 'http://elrepo.org/linux/kernel/el7/$basearch/',
  Stdlib::Httpurl $elrepo_mirrorlist = 'http://mirrors.elrepo.org/mirrors-elrepo-kernel.el7',
){

  assert_private()

  $_gpg_key = '/etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org'

  file { $_gpg_key:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/concourse/RPM-GPG-KEY-elrepo.org',
  }

  exec {  'import_elrepo_gpg_key':
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    command   => "rpm --import ${_gpg_key}",
    unless    => "rpm -q gpg-pubkey-$(echo $(gpg --throw-keyids --keyid-format short < ${_gpg_key}) | cut --characters=11-18 | tr '[A-Z]' '[a-z]')", #lint:ignore:140chars
    require   => File[$_gpg_key],
    logoutput => 'on_failure',
  }

  yumrepo { 'elrepo-kernel':
    ensure     => 'present',
    baseurl    => $elrepo_baseurl,
    descr      => 'ELRepo.org Community Enterprise Linux Kernel Repository',
    enabled    => '1',
    gpgcheck   => '1',
    gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org',
    mirrorlist => $elrepo_mirrorlist,
    proxy      => $concourse::proxy_server,
    require    => Exec['import_elrepo_gpg_key'],
  }

}
