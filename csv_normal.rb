require 'csv'
require 'time'
require 'bigdecimal'

class CSVNormal
  attr_reader :io_in, :csv_out, :io_err

  def initialize(io_in, io_out, io_err)
    @io_in   = io_in
    @csv_out = CSV.new(io_out)
    @io_err  = io_err
  end

  def call
    headers = CSV.parse_line(encoded(io_in.readline))
    csv_out << headers
    options = { headers: headers }.freeze

    io_in.readlines.each.with_index(1) do |line, line_number|
      utf_8 = encoded(line)

      CSV.parse(utf_8, options) do |row|
        begin
          csv_out << convert_row(row)
        rescue => e
          io_err.puts e.message
          io_err.puts ">>>LINE #{line_number}: #{line}"
        end
      end
    end
  ensure
    io_in.close
    csv_out.close
    io_err.close
  end

  private

  def encoded(string)
    string.encode("UTF-8", invalid: :replace)
  end

  def convert_row(data)
    data.tap { |row|
      row['Timestamp']     = convert_time(row.fetch('Timestamp')) if row.has_key?('Timestamp')
      row['ZIP']           = convert_zip(row.fetch('ZIP')) if row.has_key?('ZIP')
      row['FullName']      = upcase_name(row.fetch('FullName')) if row.has_key?('FullName')
      row['FooDuration']   = convert_float_time(row.fetch('FooDuration')) if row.has_key?('FooDuration')
      row['BarDuration']   = convert_float_time(row.fetch('BarDuration')) if row.has_key?('BarDuration')
      row['TotalDuration'] = (row['FooDuration'] + row['BarDuration']) if row.has_key?('TotalDuration')

      %w[FooDuration BarDuration TotalDuration].each do |float_col|
        row[float_col] = row.fetch(float_col).to_f if row.has_key?(float_col)
      end
    }
  end

  def convert_time(col)
    old_tz, ENV['TZ'] = ENV['TZ'], "US/Pacific"

    time = Time.strptime("#{col}", "%D %r")
    # Convert to US/Eastern
    time = time.getlocal(time.isdst ? "-04:00" : "-05:00")
    time.iso8601
  ensure
    ENV['TZ'] = old_tz
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
        Integer(m[:hour]) * 3600 + Integer(m[:min]) * 60 + Integer(m[:sec]) + BigDecimal.new("0.#{m[:ms]}", 3)
      }
  end
end