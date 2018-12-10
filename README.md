# The Run Book

[![CircleCI](https://circleci.com/gh/kmayer/truss.works.svg?style=svg)](https://circleci.com/gh/kmayer/truss.works)

Built using Ruby 2.5.1

- To run tests: `rspec csv_normal_spec.rb`
- To run the tool: `csv_normal.sh < [INPUT] > [OUTPUT]`

# Notes

- While the ZIP column is properly formatted, unless care is taken on import, 
  applications like Excel will still treat the column as numeric.
- The README says 

  > that any times that are missing timezone information are in US/Pacific
  
  but none of the sample inputs include a timezone, so it is unclear whether
  there is a need to parse an optional timezone or not. Punting on First Down.
