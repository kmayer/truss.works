# encoding: UTF-8

require 'csv'
require 'time'

class CSVNormal
  attr_reader :io_in, :io_out, :io_err

  def initialize(io_in, io_out, io_err)
    @io_in = io_in
    @io_out = io_out
    @io_err = io_err
  end

  def call
    csv_out = CSV.new(io_out)

    headers = CSV.parse_line(io_in.readline.encode("UTF-8", invalid: :replace))
    csv_out << headers

    io_in.readlines.each do |line|
      utf_8 = line.encode("UTF-8", invalid: :replace)

      options = {
        headers: headers
      }

      CSV.parse(utf_8, options) do |row|
        begin
          row['Timestamp'] = convert_time(row) if row.has_key?('Timestamp')
          csv_out << row
        rescue => e
          io_err.puts e.message
          io_err.puts ">>> #{line}"
        end
      end
    end

    io_in.close
    io_out.close
    io_err.close
  end

  private

  def convert_time(row)
    time = Time.strptime("#{row.fetch('Timestamp')} US/Pacific", "%D %r %Z")
    # Convert to US/Eastern
    time = time.getlocal(time.isdst ? "-04:00" : "-05:00")
    time.iso8601
  end
end