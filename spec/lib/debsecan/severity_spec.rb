# frozen_string_literal: true

RSpec.describe Debsecan::Severity do
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

      include_examples '<', Debsecan::Severity::Unknown, Debsecan::Severity::Negligible, true
      include_examples '<', Debsecan::Severity::Negligible, Debsecan::Severity::Low, true
      include_examples '<', Debsecan::Severity::Low, Debsecan::Severity::Medium, true
      include_examples '<', Debsecan::Severity::Medium, Debsecan::Severity::High, true
      include_examples '<', Debsecan::Severity::High, Debsecan::Severity::Critical, true

      include_examples '<', Debsecan::Severity::Critical, Debsecan::Severity::High, false
      include_examples '<', Debsecan::Severity::Medium, Debsecan::Severity::Medium, false
      include_examples '<', Debsecan::Severity::Medium, Debsecan::Severity::Low, false

      include_examples '==', Debsecan::Severity::Medium, Debsecan::Severity::Medium, true
      include_examples '==', Debsecan::Severity::Critical, Debsecan::Severity::Medium, false
    end
  end
end
