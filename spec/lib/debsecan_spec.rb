# frozen_string_literal: true

require_relative '../../lib/debsecan'

RSpec.describe Debsecan do
  describe '.strategies' do
    it 'increases when a new strategy is created' do
      expect do
        class ExampleStrategy
          include Debsecan::Strategy
        end
      end.to change(Debsecan.strategies, :size).by(1)
      expect(Debsecan.strategies.last).to eq(ExampleStrategy)
    end
  end

  describe 'configuration' do
    describe '.defaults' do
      it 'is a hash of default values' do
        expect(Debsecan::Configuration.defaults).to be_a(Hash)
      end
    end

    it 'is callable from .configure' do
      expect { |b| Debsecan.configure(&b) }.to yield_with_args(Debsecan::Configuration)
    end
  end

  describe '.logger' do
    it 'calls the configured logger' do
      expect(Debsecan).to receive(:config).and_return(double(logger: 'foobar'))
      expect(Debsecan.logger).to eq('foobar')
    end
  end
end
