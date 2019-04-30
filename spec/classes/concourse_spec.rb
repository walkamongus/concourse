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
        context 'with init default params' do
          it { is_expected.to contain_archive('concourse_package') }
          it { is_expected.to contain_archive('fly_package') }
          it { is_expected.to contain_file('/etc/concourse') }
          it { is_expected.to contain_file('/opt/concourse/worker') }
          it { is_expected.to contain_file('/opt/concourse/session_signing_key') }
          it { is_expected.to contain_file('/opt/concourse/tsa_host_key') }
          it { is_expected.to contain_file('/opt/concourse/worker_key') }
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
