# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dobby do
  describe '.strategies' do
    it 'increases when a new strategy is created' do
      expect do
        class ExampleStrategy
          include Dobby::Strategy
        end
      end.to change(Dobby.strategies, :size).by(1)
      expect(Dobby.strategies.last).to eq(ExampleStrategy)
    end
  end

  describe 'configuration' do
    describe '.defaults' do
      it 'is a hash of default values' do
        expect(Dobby::Configuration.defaults).to be_a(Hash)
      end
    end

    it 'is callable from .configure' do
      expect { |b| Dobby.configure(&b) }.to yield_with_args(Dobby::Configuration)
    end
  end

  describe '.logger' do
    it 'calls the configured logger' do
      expect(Dobby).to receive(:config).and_return(double(logger: 'foobar'))
      expect(Dobby.logger).to eq('foobar')
    end
  end
end
