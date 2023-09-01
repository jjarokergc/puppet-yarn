require 'spec_helper_acceptance'

describe 'installing yarn' do
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
        }
      }
      elsif $facts['os']['family'] == 'Debian' and $::operatingsystemrelease == '7.8' {
        class { 'yarn':
          manage_repo    => false,
          install_method => 'source',
          require        => Package['nodejs'],
        }
      }
      else {
        class { 'yarn': }

        Package['nodejs'] -> Package['yarn']

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
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match %r{yarn} }
    end
  end
end
