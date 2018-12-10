require "rspec"
require "./csv_normal"

describe CSVNormal do
  let(:stdin) { StringIO.new("CSV\n") }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  it "reads from an io and writes to an io" do
    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("CSV\n")
    expect(stderr.string).to be_empty
  end

  it "can be run from the command line" do
    system "./csv_normal.sh < test01.csv > test01_out.csv"
    expect($?).to eq(0)

    expect(FileUtils.compare_file("./test01.csv", "./test01_out.csv")).to be_truthy
  end

  it "normalizes the output to UTF-8" do
    %w[./sample.csv ./sample-with-broken-utf8.csv].each do |sample|
      File.open(sample, "r") do |f|
        stdout     = StringIO.new
        normalizer = CSVNormal.new(f, stdout, stderr)

        normalizer.()

        expect(stdout.string.valid_encoding?).to be_truthy
        expect(stderr.string).to be_empty
      end
    end
  end

  after(:all) do
    FileUtils.rm("./test01_out.csv")
  end
end