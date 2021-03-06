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

  after(:all) do
    FileUtils.rm_f("./test01_out.csv")
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

  it "upcases all name columns" do
    {
      "Monkey Alberto"   => "MONKEY ALBERTO",
      "Superman übertan" => "SUPERMAN ÜBERTAN",
      "Résumé Ron"       => "RÉSUMÉ RON",
      "Mary 1"           => "MARY 1",
      "株式会社スタジオジブリ "     => "株式会社スタジオジブリ",
      "HERE WE GO"       => "HERE WE GO",
    }.each do |input, expected|
      stdin = StringIO.new("FullName\n#{input}")
      stdout = StringIO.new

      normalizer = CSVNormal.new(stdin, stdout, stderr)

      normalizer.()

      expect(stdout.string).to eq("FullName\n#{expected}\n")
    end
  end

  it "columns that have embedded commas are okay if they are quote-escaped" do
    stdin = StringIO.new("Address\n\"I,am,okay,really\"")

    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("Address\n\"I,am,okay,really\"\n")
  end

  it "convert the {Foo|Bar}Duration columns to floating point seconds" do
    stdin = StringIO.new("FooDuration,BarDuration\n1:23:32.123,1:32:33.123")
    foo_duration = 1 * 3600 + 23 * 60 + 32 + 0.123
    bar_duration = 1 * 3600 + 32 * 60 + 33 + 0.123

    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("FooDuration,BarDuration\n#{foo_duration},#{bar_duration}\n")
  end

  it "TotalDuration = FooDuration + BarDuration" do
    stdin = StringIO.new("FooDuration,BarDuration,TotalDuration\n1:23:32.123,1:32:33.123,I am a blue monkey that says dadadadada")
    foo_duration = 1 * 3600 + 23 * 60 + 32 + 0.123
    bar_duration = 1 * 3600 + 32 * 60 + 33 + 0.123

    normalizer = CSVNormal.new(stdin, stdout, stderr)

    normalizer.()

    expect(stdout.string).to eq("FooDuration,BarDuration,TotalDuration\n#{foo_duration},#{bar_duration},#{foo_duration + bar_duration}\n")
  end
end