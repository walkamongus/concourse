require 'spec_helper'

describe 'concourse' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_class('concourse::install') }
      it { is_expected.to contain_class('concourse::config') }
      it { is_expected.to contain_class('concourse::service') }

      describe 'concourse::install' do
        context 'with init default params (v4.x)' do
          it do
            is_expected.to contain_archive('concourse_package').with(
              'ensure'       => 'present',
              'path'         => '/usr/local/bin/concourse-v4.2.1',
              'extract'      => false,
              'extract_path' => nil,
              'source'       => 'https://github.com/concourse/concourse/releases/download/v4.2.1/concourse_linux_amd64',
              'creates'      => '/usr/local/bin/concourse-v4.2.1',
              'cleanup'      => false,
              'proxy_server' => nil,
            )
          end
          it { is_expected.to contain_file('/usr/local/bin/concourse') }
          it do
            is_expected.to contain_archive('fly_package').with(
              'ensure'       => 'present',
              'path'         => '/usr/local/bin/fly-v4.2.1',
              'extract'      => false,
              'source'       => 'https://github.com/concourse/concourse/releases/download/v4.2.1/fly_linux_amd64',
              'creates'      => '/usr/local/bin/fly-v4.2.1',
              'cleanup'      => false,
              'proxy_server' => nil,
            )
          end
          it { is_expected.to contain_file('/usr/local/bin/fly') }
          it { is_expected.to contain_file('/etc/concourse') }
          it { is_expected.to contain_file('/opt/concourse/worker') }
          it { is_expected.to contain_file('/opt/concourse/session_signing_key') }
          it { is_expected.to contain_file('/opt/concourse/tsa_host_key') }
          it { is_expected.to contain_file('/opt/concourse/worker_key') }
        end

        context 'on version 5.x' do
          let(:params) { { :version => '5.1.0' } }

          it do
            is_expected.to contain_archive('concourse_package').with(
              'ensure'       => 'present',
              'path'         => '/tmp/concourse-5.1.0-linux-amd64.tgz',
              'extract'      => true,
              'extract_path' => '/usr/local/concourse-5.1.0',
              'source'       => 'https://github.com/concourse/concourse/releases/download/v5.1.0/concourse-5.1.0-linux-amd64.tgz',
              'creates'      => '/usr/local/concourse-5.1.0/concourse',
              'cleanup'      => false,
              'proxy_server' => nil,
            )
          end

          it do
            is_expected.to contain_archive('fly_package').with(
              'ensure'       => 'present',
              'path'         => '/tmp/fly-5.1.0-linux-amd64.tgz',
              'extract'      => true,
              'extract_path' => '/opt/fly-5.1.0',
              'source'       => 'https://github.com/concourse/concourse/releases/download/v5.1.0/fly-5.1.0-linux-amd64.tgz',
              'creates'      => '/opt/fly-5.1.0/fly',
              'cleanup'      => false,
              'proxy_server' => nil,
            )
          end
        end
      end

      describe 'concourse::config' do
        context 'with init default params' do
          it { is_expected.to contain_file('/etc/concourse/standalone') }
          it do
            is_expected.to contain_file('web_unit')
              .that_notifies('Exec[concourse_systemd_daemon-reload]')
          end
          it do
            is_expected.to contain_file('worker_unit')
              .that_notifies('Exec[concourse_systemd_daemon-reload]')
          end
        end
      end

      describe 'concourse::service' do
        context 'with init default params' do
          it { is_expected.to contain_service('concourse-web') }
          it { is_expected.to contain_service('concourse-worker') }
        end
      end
    end
  end
end
