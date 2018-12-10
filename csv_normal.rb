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
          row['Timestamp'] = convert_time(row.fetch('Timestamp')) if row.has_key?('Timestamp')
          row['ZIP'] = convert_zip(row.fetch('ZIP')) if row.has_key?('ZIP')
          row['FullName'] = upcase_name(row.fetch('FullName')) if row.has_key?('FullName')
          row['FooDuration'] = convert_float_time(row.fetch('FooDuration')) if row.has_key?('FooDuration')
          row['BarDuration'] = convert_float_time(row.fetch('BarDuration')) if row.has_key?('FooDuration')
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

  def convert_time(col)
    time = Time.strptime("#{col} US/Pacific", "%D %r %Z")
    # Convert to US/Eastern
    time = time.getlocal(time.isdst ? "-04:00" : "-05:00")
    time.iso8601
  end

  def convert_zip(col)
    col.strip.rjust(5, '00000')
  end

  def upcase_name(col)
    col.strip.upcase
  end

  def convert_float_time(col)
    %r{(?<hour>\d+):(?<min>\d{2}):(?<sec>\d{2})\.(?<ms>\d{3})}
      .match(col) { |m|
        Float(m[:hour]) * 3600 + Float(m[:min]) * 60 + Float(m[:sec]) + Float(m[:ms]) / 1000
      }
  end
end