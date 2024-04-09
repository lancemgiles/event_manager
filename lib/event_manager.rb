# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'pry-byebug'
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phone)
  remove_punc = phone.gsub(/\D/, '')
  pnums = remove_punc.to_s
  if (pnums[0] == '1') && (pnums.length == 11)
    pnums[1..]
  elsif pnums.length > 11
    pnums = '0000000000'
  else
    pnums = pnums.rjust(10, '0')[0..9]
  end
  pnums
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def peak_times(dates)
  
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


mins = []
hrs = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_numbers(row[:homephone])
  reg_date = row[:regdate]

  legislators = legislators_by_zipcode(zipcode)

  reg_time = reg_date.split[1]
  hrs.push(reg_time.split(':')[0].to_i)
  mins.push(reg_time.split(':')[1].to_i)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

avg_hr = hrs.sum(0.0) / hrs.length
avg_min = mins.sum(0.0) / mins.length
puts "Peak registration time: #{avg_hr.round}:#{avg_min.round}"