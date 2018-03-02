# frozen_string_literal: true

RSpec.describe Debsecan::DpkgStatusFile do
  let(:status_file) { File.join('./spec/fixtures', 'dpkg_status') }
  let(:strategy) { Debsecan::DpkgStatusFile.new(file_path: status_file, release: 'wheezy') }

  let(:packages) { strategy.parse }
  subject { packages }

  describe '#parse' do
    it 'creates 6 packages' do
      expect(subject.count).to eq(6)
      subject.each do |p|
        expect(p).to be_a(Debsecan::Package)
      end
    end

    it 'creates the expected fake-package' do
      package = subject.find { |p| p.name == 'fake-package' }
      expect(package.name).to eq('fake-package')
      expect(package.version).to eq('2')
      expect(package.dist).to eq('Debian')
      expect(package.release).to eq('wheezy')
      expect(package.arch).to eq('amd64')
    end

    it 'uses only the name portion of the source field' do
      package = subject.find { |p| p.name == 'libfcgi-perl' }
      expect(package.source).to eq('libfcgi-perl')
    end
  end
end
