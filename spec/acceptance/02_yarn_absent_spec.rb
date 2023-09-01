require 'spec_helper_acceptance'

describe 'removing yarn' do
  describe 'running puppet code' do
    pp = <<-EOS
      class { 'nodejs':
        repo_url_suffix => '6.x',
      }

      if $facts['os']['family'] == 'Debian' and $::operatingsystemrelease == '7.3' {
        class { 'yarn':
          manage_repo    => false,
          install_method => 'npm',
          require        => Class['nodejs'],
          package_ensure => 'absent',
        }
      }
      elsif $facts['os']['family'] == 'Debian' and $::operatingsystemrelease == '7.8' {
        class { 'yarn':
          manage_repo    => false,
          install_method => 'source',
          require        => Package['nodejs'],
          package_ensure => 'absent',
        }
      }
      else {
        class { 'yarn':
          package_ensure => 'absent',
        }

        if $facts['os']['family'] == 'RedHat' and $::operatingsystemrelease =~ /^5\.(\d+)/ {
          class { 'epel': }
          Class['epel'] -> Class['nodejs'] -> Class['yarn']
        }
      }
    EOS
    let(:manifest) { pp }

    it 'works with no errors' do
      apply_manifest(manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest(manifest, catch_changes: true)
    end

    describe command('yarn -h') do
      its(:exit_status) { is_expected.to eq 127 }
    end
  end
end
