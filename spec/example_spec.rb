# frozen_string_literal: true

require 'spec_helper'

# This is a simple example spec to verify RSpec is working correctly
# Remove this file once you start writing actual tests
RSpec.describe 'RSpec Setup' do
  it 'can run basic expectations' do
    expect(1 + 1).to eq(2)
  end

  it 'supports string matchers' do
    expect('Hello RSpec').to include('RSpec')
  end

  it 'can test Ruby core functionality' do
    arr = [1, 2, 3]
    expect(arr.length).to eq(3)
    expect(arr).to include(2)
  end
end
