# frozen_string_literal: true

RSpec.describe Debsecan::VulnSrcUbuntu do
  let(:test_data_path) { [File.join('./spec/fixtures', 'ubuntu_test_data.txt')] }
  let(:repo_path) { '/tmp/ubuntu_vuln_src_test' }
  let(:src) do
    Debsecan::VulnSrcUbuntu.new(
      releases: %w[xenial zesty],
      local_repo_path: repo_path
    )
  end

  subject { src }

  before(:each) do
    allow(src).to receive(:modified_entries) { test_data_path }
    allow(src).to receive(:bzr_revno) { '1' }
    allow(src).to receive(:branch_or_pull) { true }
  end

  describe '#update' do
    let(:response) { subject.update }
    let(:entries) { response.content }

    it 'returns an UpdateResponse' do
      expect(response).to be_a(Debsecan::UpdateResponse)
    end

    context 'changed? versioning' do
      it 'is true for the first update' do
        expect(response.changed?).to be(true)
      end

      it 'is false for a second update if nothing has changed' do
        expect {}.to change { subject.update.changed? }.from(true).to(false)
      end

      it 'is true for a second update if something has changed' do
        subject.update
        expect do
          allow(src).to receive(:bzr_revno).and_return('2')
        end.to change { subject.update.changed? }.from(false).to(true)
      end
    end

    it 'contains only the expected keys' do
      expect(entries.keys).to eq(%w[firefox thunderbird])
    end

    context 'content format' do
      shared_examples_for 'a parsed ubuntu cve entry' do |versions|
        let(:defect) { entries[pkg] }
        it 'has CVE-2017-5430' do
          expect(defect.identifier).to eq('CVE-2017-5430')
        end

        it 'has the correct description' do
          expect(defect.description).to eq('Lorum Ipsum dolor')
        end

        it 'has the correct number of fix versions' do
          expect(defect.fixed_in.count).to eq(2)
        end

        versions.each do |v|
          it "has #{v} as a fix version" do
            expect(defect.fixed_in.any? { |f| f.version == v }).to eq(true)
          end
        end

        it 'has the correct severity' do
          expect(defect.severity).to eq(Debsecan::Severity::Medium)
        end
      end

      context 'firefox' do
        let(:pkg) { 'firefox' }

        include_examples 'a parsed ubuntu cve entry',
                         %w[53.0+build6-0ubuntu0.16.04.1 53.0+build6-0ubuntu0.17.04.1]
      end

      context 'thunderbird' do
        let(:pkg) { 'thunderbird' }

        include_examples 'a parsed ubuntu cve entry',
                         %w[1:52.1.1+build1-0ubuntu0.16.04.1 1:52.1.1+build1-0ubuntu0.17.04.1]
      end
    end
  end
end
