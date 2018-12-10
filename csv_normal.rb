# encoding: UTF-8
class CSVNormal
  attr_reader :io_in, :io_out, :io_err

  def initialize(io_in, io_out, io_err)
    @io_in = io_in
    @io_out = io_out
    @io_err = io_err
  end

  def call
    io_in.readlines.each do |line|
      io_out.puts line.encode("UTF-8", invalid: :replace)
    end

    io_in.close
    io_out.close
    io_err.close
  end
end