# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dobby::VulnSource::Debian do
  let(:test_data) { File.read(File.join('.', 'spec', 'fixtures', 'debian_vuln_src.json')) }
  let(:src) { Dobby::VulnSource::Debian.new(releases: %w[wheezy jessie sid]) }

  subject { src }

  describe '#update' do
    before do
      allow(src).to receive(:fetch_from_remote) { test_data }
    end

    it 'returns an UpdateResponse' do
      expect(subject.update).to be_a(Dobby::UpdateResponse)
    end

    context '.content' do
      let(:contents) { src.update.content }
      let(:defects) { contents[pkg] }

      it 'contains the expected package keys' do
        expect(contents.keys).to eq(%w[aptdaemon asterisk])
      end

      shared_examples_for 'a parsed debian cve entry' do
        it 'contains an entry with the correct link' do
          expect(defect).not_to be_nil
          expect(defect.link).to eq("https://security-tracker.debian.org/tracker/#{identifier}")
        end

        it 'has the correct description' do
          expect(defect.description).to eq(description)
        end

        it 'has the correct severity' do
          expect(defect.severity).to eq(severity)
        end

        it 'has the correct fix versions' do
          expect(defect.fixed_in.map(&:version).sort).to eq(versions.sort)
        end
      end

      let(:defect) { defects.find { |d| d.identifier == identifier } }
      context 'aptdaemon' do
        let(:pkg) { 'aptdaemon' }

        context 'CVE-2015-1323' do
          let(:identifier) { 'CVE-2015-1323' }
          let(:severity) { Dobby::Severity::Low }
          let(:description) { 'This vulnerability is not very dangerous.' }
          let(:versions) { ['1.1.1+bzr982-1', '|MAX|'] }

          include_examples 'a parsed debian cve entry'
        end

        context 'CVE-2003-0779' do
          let(:identifier) { 'CVE-2003-0779' }
          let(:severity) { Dobby::Severity::Critical }
          let(:description) { 'But this one is very dangerous.' }
          let(:versions) { ['0.7.0', '0.7.0'] }

          include_examples 'a parsed debian cve entry'
        end
      end

      context 'asterisk' do
        let(:pkg) { 'asterisk' }

        context 'CVE-2013-2685' do
          let(:identifier) { 'CVE-2013-2685' }
          let(:severity) { Dobby::Severity::Negligible }
          let(:description) { 'Un-affected packages.' }
          let(:versions) { ['|MIN|'] }

          include_examples 'a parsed debian cve entry'
        end

        context 'CVE-2003-0779' do
          let(:identifier) { 'CVE-2003-0779' }
          let(:severity) { Dobby::Severity::High }
          let(:description) { 'But this one is very dangerous.' }
          let(:versions) { ['0.5.56'] }

          include_examples 'a parsed debian cve entry'
        end
      end
    end

    it 'skips unmarshalling when unchanged' do
      expect(subject.update.changed?).to be_truthy
      expect(subject.update.changed?).to be_falsey
    end
  end
end
