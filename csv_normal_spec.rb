require "rspec"
require "./csv_normal"

describe CSVNormal do
  let(:stdin) { StringIO.new("CSV\nrow") }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  after(:each) do
    expect(stderr.string).to be_empty
  end

  it "reads from an io and writes to an io" do
    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("CSV\nrow\n")
  end

  it "can be run from the command line" do
    system "./csv_normal.sh < test01.csv > test01_out.csv"
    expect($?).to eq(0)

    expect(FileUtils.compare_file("./test01.csv", "./test01_out.csv")).to be_truthy
  end

  it "normalizes the output to UTF-8." do
    File.open("./sample.csv", "r") do |f|
      stdout     = StringIO.new
      normalizer = CSVNormal.new(f, stdout, stderr)

      normalizer.()

      expect(stdout.string.valid_encoding?).to be_truthy
    end
  end

  it "normalizes the output to UTF-8, even with broken UTF-8" do
    File.open("./sample-with-broken-utf8.csv", "r") do |f|
      stdout     = StringIO.new
      normalizer = CSVNormal.new(f, stdout, stderr)

      normalizer.()

      expect(stdout.string.valid_encoding?).to be_truthy
    end
  end

  it "converts the timestamp column to ISO-8601" do
    stdin = StringIO.new("Timestamp\n4/1/11 11:00:00 AM")
    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("Timestamp\n2011-04-01T14:00:00-04:00\n")
  end

  it "converts all the timestamps from US/Pacific to US/Eastern" do
    stdin = StringIO.new("Timestamp\n4/1/11 11:00:00 AM")

    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("Timestamp\n2011-04-01T14:00:00-04:00\n")
  end

  it "formats ZIP codes as 5 digits" do
    {
      "12345" => "12345",
      "1"     => "00001",
      "12\n"  => "00012",
      " 123"  => "00123",
      "1234 " => "01234",
    }.each do |input, expected|
      stdin = StringIO.new("ZIP\n#{input}")
      stdout = StringIO.new

      normalizer = CSVNormal.new(stdin, stdout, stderr)

      normalizer.()

      expect(stdout.string).to eq("ZIP\n#{expected}\n")
    end
  end

  after(:all) do
    FileUtils.rm_f("./test01_out.csv")
  end
end