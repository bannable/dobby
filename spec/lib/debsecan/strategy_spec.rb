# frozen_string_literal: true

RSpec.describe Debsecan::Strategy do
  class ExampleStrategy
    include Debsecan::Strategy
  end

  let(:fresh_strategy) do
    c = Class.new
    c.send(:include, Debsecan::Strategy)
  end

  describe '.default_options' do
    it 'is inherited from a parent class' do
      superklass = Class.new
      superklass.send :include, Debsecan::Strategy
      superklass.configure do |c|
        c.foo = 'bar'
      end

      klass = Class.new(superklass)
      expect(klass.default_options.foo).to eq('bar')
    end
  end

  describe '.configure' do
    subject { fresh_strategy }

    context 'with a block' do
      it 'allows setting default option values' do
        subject.configure { |c| c.graul = 'xyzzy' }
        expect(subject.default_options['graul']).to eq('xyzzy')
      end

      it 'works when block does not evaluate to true' do
        subject.configure do |c|
          c.foo = '123'
          c.bar = nil
        end
        expect(subject.default_options['foo']).to eq('123')
      end
    end

    it 'deep merges a hash' do
      subject.configure a: { b: 123 }
      subject.configure a: { c: 456 }
      expect(subject.default_options['a']).to eq('b' => 123, 'c' => 456)
    end
  end

  describe '.option' do
    subject { fresh_strategy }

    it 'sets a default value' do
      subject.option :foo, 123
      expect(subject.default_options.foo).to eq(123)
    end

    it 'sets a default value to nil if a value is not provided' do
      subject.option :foo
      expect(subject.default_options.foo).to be_nil
    end
  end

  describe '.args' do
    subject { fresh_strategy }

    it 'is inheritable' do
      subject.args %i[foo bar]
      expect(Class.new(subject).args).to eq(%i[foo bar])
    end

    it 'sets args to the provided value if it one is provided' do
      subject.args %i[foo bar]
      expect(subject.args).to eq(%i[foo bar])
    end

    it 'accepts corresponding options as default arg values' do
      subject.args %i[a b]
      subject.option :a, 1
      subject.option :b, 2

      expect(subject.new.options.a).to eq 1
      expect(subject.new.options.b).to eq 2
      expect(subject.new(3, 4).options.b).to eq 4
      expect(subject.new(nil, 4).options.a).to eq nil
    end
  end

  describe '#initialize' do
    context 'options extraction' do
      it 'is the default options if any are provided' do
        allow(ExampleStrategy).to receive(:default_options).and_return(
          Debsecan::Strategy::Options.new(foo: 123)
        )
        expect(ExampleStrategy.new.options.foo).to eq(123)
      end
    end

    context 'custom args' do
      subject { fresh_strategy }

      it 'sets options based on supplied arguments' do
        subject.args %i[foo bar]
        s = subject.new('baz', 'xyzzy')
        expect(s.options[:foo]).to eq('baz')
        expect(s.options[:bar]).to eq('xyzzy')
      end
    end
  end

  describe '#inspect' do
    it 'returns the class name' do
      expect(ExampleStrategy.new.inspect).to eq('#<ExampleStrategy>')
    end
  end
end
