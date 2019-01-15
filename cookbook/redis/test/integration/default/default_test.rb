# encoding: utf-8

describe service('redis') do
  it { should be_installed }
  it { should be_running }
  it { should be_enabled }
end
