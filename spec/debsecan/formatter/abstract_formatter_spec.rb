# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Debsecan::Formatter::AbstractFormatter do
  describe 'API invocation' do
    subject(:formatter) { double('formatter') }

    let(:output) { $stdout.string }

    before do
      $stdout = StringIO.new
    end

    after do
      $stdout = STDOUT
    end
  end
end
