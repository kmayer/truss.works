#!/usr/bin/env ruby

require './csv_normal'

normalizer = CSVNormal.new($stdin, $stdout, $stderr)

normalizer.call