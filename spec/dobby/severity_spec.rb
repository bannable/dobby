# frozen_string_literal: true

RSpec.describe Dobby::Severity do
  context 'severities' do
    context 'comparisons' do
      shared_examples_for '<' do |left, right, res|
        context "#{left} < #{right}" do
          subject { left < right }
          it { is_expected.to be res }
        end
      end

      shared_examples_for '==' do |left, right, res|
        context "#{left} == #{right}" do
          subject { left == right }
          it { is_expected.to be res }
        end
      end

      include_examples '<', Dobby::Severity::Unknown, Dobby::Severity::Negligible, true
      include_examples '<', Dobby::Severity::Negligible, Dobby::Severity::Low, true
      include_examples '<', Dobby::Severity::Low, Dobby::Severity::Medium, true
      include_examples '<', Dobby::Severity::Medium, Dobby::Severity::High, true
      include_examples '<', Dobby::Severity::High, Dobby::Severity::Critical, true

      include_examples '<', Dobby::Severity::Critical, Dobby::Severity::High, false
      include_examples '<', Dobby::Severity::Medium, Dobby::Severity::Medium, false
      include_examples '<', Dobby::Severity::Medium, Dobby::Severity::Low, false

      include_examples '==', Dobby::Severity::Medium, Dobby::Severity::Medium, true
      include_examples '==', Dobby::Severity::Critical, Dobby::Severity::Medium, false
    end
  end
end
