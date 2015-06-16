require 'nokogiri'
require_relative 'rspec_result_parser/describe'
require_relative 'rspec_result_parser/example'
require_relative 'rspec_result_parser/result_creator'
require_relative 'rspec_result_parser/rspec_result'

class  String
  def get_style_param(param)
    m = match(/#{param}:\s(.*);/)
    m[1]
  end

  def delete_px
    gsub 'px', ''
  end
end

class ResultParser
  LEVEL_MARGIN = 15
  attr_accessor :example_index
  @example_index = 0

  def self.parse_rspec_html(html_path)
    page = Nokogiri::HTML(open(html_path))
    parse_test_result(page)
  end

  def self.parse_rspec_html_string(html_string)
    page = Nokogiri::HTML(html_string)
    parse_test_result(page)
  end

  def self.get_processing_of_rspec_html(html_path)
    page = Nokogiri::HTML(open(html_path))
    get_processing(page)
  end

  def self.get_total_result_of_rspec_html(html_path)
    page = Nokogiri::HTML(open(html_path))
    get_totals(page)
  end

  def self.parse_test_result(page)
    ResultParser.example_index = 0
    rspec_results = RspecResult.new
    rspec_results.describe = get_describe(page)
    rspec_results.processing = get_processing(page)
    rspec_results.result = get_total_result(page)
    rspec_results.time = get_total_time(page)
    rspec_results.total = get_totals(page)
    rspec_results
  end

  def self.get_processing(page)
    processing = page.css('script:contains("moveProgressBar")').last
    if processing
      process = processing.text.strip.split('\'')[1]
      if process == ''
        '0'
      else
        process
      end
    else
      '0'
    end
  end

  def self.get_total_result(page)
    get_totals(page).include?(' 0 failures')
  end

  def self.get_total_time(page)
    total_time = page.css('script:contains("Finished in")').text.match(/>(.*?)</)
    if total_time
      total_time[1]
    else
      ''
    end
  end

  def self.get_totals(page)
    totals = ''
    total_elem = page.css('script:contains(" example")')
    if total_elem
      totals = total_elem.text.match(/"(.*?)"/)
      if totals
        totals = totals[1]
      else
        totals = ''
      end
    end
    totals
  end

  def self.get_describe(page)
    results = ResultCreator.new
    page.at_css('div.results').xpath('./div').each do |current|
      results.push_to_end(parse_describe(current), get_describe_level(current))
    end
    results.get_result
  end

  def self.get_describe_level(describe)
    describe.xpath('./dl')[0][:style].get_style_param('margin-left').delete_px.to_i / LEVEL_MARGIN
  end

  def self.parse_describe(describe)
    describe_obj = Describe.new(describe.css('dt').text)
    unless describe.css('dd').empty?
      describe.css('dd').each_with_index do |example|
        # example_log = describe.xpath("//dd/preceding-sibling::text()[1]")[@@example_index].text.strip
        describe_obj.child << parse_example(example)
        ResultParser.example_index += 1
      end
    end
    describe_obj
  end

  def self.parse_example(example)
    example_obj = Example.new
    example_obj.text = example.css('span').first.text
    example_obj.passed = example[:class].split(' ')[1]
    if example_obj.passed == 'failed'
      example_obj.duration = example.css('span')[1].text
      example_obj.message = example.css('div.message').text
      example_obj.backtrace = example.css('div.backtrace').text
      example_obj.code = example.css('code').children.to_s
    elsif example_obj.passed == 'passed'
      example_obj.duration = example.css('span')[1].text
    end
    example_obj
  end
end