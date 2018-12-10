require 'rspec'
require './csv_normal'

describe CSVNormal do
  let(:stdin) { StringIO.new("CSV\n") }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  it 'reads from an io and writes to an io' do
    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("CSV\n")
    expect(stderr.string).to be_empty
  end

  it 'can be run from the command line' do
    system "./csv_normal.sh < test01.csv > test01_out.csv"
    expect($?).to eq(0)

    expect(FileUtils.compare_file('./test01.csv', './test01_out.csv')).to be_truthy
  end

  after(:all) do
    FileUtils.rm('./test01_out.csv')
  end
end