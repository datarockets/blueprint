RSpec.describe 'Bluepirnt test command' do
  let(:stubbed_env) { create_stubbed_env }

  it 'example' do
    stdout, _stderr, _status = stubbed_env.execute('bin/blueprint test')
    expect(stdout).to eq "Hello world!!!\n"
  end
end
