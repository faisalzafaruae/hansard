require 'rubygems'
require 'open-uri'
require 'hpricot'

module Hansard
end

class Hansard::HeaderParser

  include Hansard::ParserHelper

  def initialize file, logger, source_file
    @logger = logger
    @doc = Hpricot.XML open(file)
    @source_file = source_file
  end

  def log text
    @logger.add_log text if @logger
  end

  def parse
    session = nil
    @doc.children.each do |node|
      if node.elem? && node.name == 'hansard'
        session = create_session node
      end
    end
    if session
      session
    else
      raise 'cannot create session, hansard element not found in source XML'
    end
  end

  BASE_MAJESTY_PATTERN = '(.+) YEAR OF THE REIGN OF ([^ ]+) MAJESTY ([^ ]+) ([^ ]+) ([^ ]+)'
  BASE_ONE_YEAR_REIGN_PATTERN = '(\d+) ([^ ]+) ([^ ]+)'
  BASE_TWO_YEAR_REIGN_PATTERN = '(\d+) ?(&amp;|and|AND|&#x0026;) ?(\d+) ([^ ]+) ([^ ]+)'
  AND_SEPARATOR_PATTERN = ' ?(&amp;|and|AND|&#x0026;) ?'

  MAJESTY_PATTERN = /^#{BASE_MAJESTY_PATTERN}$/
  PARLIAMENT_AND_MAJESTY_PATTERN = /NORTHERN IRELAND #{BASE_MAJESTY_PATTERN}$/
  PARLIAMENT_AND_ONE_YEAR_REIGN_PATTERN = /NORTHERN IRELAND #{BASE_ONE_YEAR_REIGN_PATTERN}/
  PARLIAMENT_AND_TWO_YEAR_REIGN_PATTERN = /NORTHERN IRELAND #{BASE_TWO_YEAR_REIGN_PATTERN}/

  ONE_YEAR_REIGN_PATTERN = /^#{BASE_ONE_YEAR_REIGN_PATTERN}/
  TWO_YEAR_REIGN_PATTERN = /^#{BASE_TWO_YEAR_REIGN_PATTERN}/
  ONE_YR_TWO_YR_TWO_MONARCHS = /^#{BASE_ONE_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_TWO_YEAR_REIGN_PATTERN}$/
  ONE_YR_ONE_YR_TWO_MONARCHS = /^#{BASE_ONE_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_ONE_YEAR_REIGN_PATTERN}$/
  TWO_YR_ONE_YR_TWO_MONARCHS = /^#{BASE_TWO_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_ONE_YEAR_REIGN_PATTERN}$/
  TWO_YR_TWO_YR_TWO_MONARCHS = /^#{BASE_TWO_YEAR_REIGN_PATTERN}#{AND_SEPARATOR_PATTERN}#{BASE_TWO_YEAR_REIGN_PATTERN}$/

  def self.match_majesty_reign_and_name match
    year = match[1].strip.sub(' ','-')
    name = match[4]
    monarch_suffix = match[5]

    year_of_the_reign = "#{year}"
    monarch_name = "#{name} #{monarch_suffix}"
    return year_of_the_reign, monarch_name
  end

  def self.match_two_year_reign_and_monarch match, index_increment=0
    first_year = match[1 + index_increment]
    and_separator = match[2 + index_increment]
    second_year = match[3 + index_increment]
    name = match[4 + index_increment]
    monarch_suffix = match[5 + index_increment].chomp('.')

    year_of_the_reign = "#{first_year} #{and_separator} #{second_year}"
    monarch_name = "#{name} #{monarch_suffix}"
    return year_of_the_reign, monarch_name
  end

  def self.match_one_year_reign_and_monarch match, index_increment=0
    year = match[1 + index_increment]
    name = match[2 + index_increment]
    monarch_suffix = match[3 + index_increment].chomp('.')

    year_of_the_reign = "#{year}"
    monarch_name = "#{name} #{monarch_suffix}"
    return year_of_the_reign, monarch_name
  end

  def self.find_second_reign_and_monarch text, first_pattern, second_pattern, index_increment
    if (match = first_pattern.match(text))
      other_reign, other_monarch = match_one_year_reign_and_monarch match, index_increment
    elsif (match = second_pattern.match(text))
      other_reign, other_monarch = match_two_year_reign_and_monarch match, index_increment
    else
      other_reign, other_monarch = nil, nil
    end
    return other_reign, other_monarch
  end

  def self.find_reign_and_monarch text
    year_of_the_reign = monarch_name = other_year_of_the_reign = nil
    text = text.gsub('<lb/>','')

    if (match = TWO_YEAR_REIGN_PATTERN.match(text))
      if ((monarch_suffix = match[5].chomp('.')) && monarch_suffix.is_roman_numerial?)
        year_of_the_reign, monarch_name = match_two_year_reign_and_monarch(match)
        other_year_of_the_reign, other_monarch_name = find_second_reign_and_monarch(text, TWO_YR_ONE_YR_TWO_MONARCHS, TWO_YR_TWO_YR_TWO_MONARCHS, 6)
      end
    elsif (match = ONE_YEAR_REIGN_PATTERN.match(text))
      if ((monarch_suffix = match[3].chomp('.')) && monarch_suffix.is_roman_numerial?)
        year_of_the_reign, monarch_name = match_one_year_reign_and_monarch(match)
        other_year_of_the_reign, other_monarch_name = find_second_reign_and_monarch(text, ONE_YR_ONE_YR_TWO_MONARCHS, ONE_YR_TWO_YR_TWO_MONARCHS, 4)
      end
    elsif ((match = PARLIAMENT_AND_MAJESTY_PATTERN.match(text)) || (match = MAJESTY_PATTERN.match(text)))
      year_of_the_reign, monarch_name = match_majesty_reign_and_name(match)
    elsif (match = PARLIAMENT_AND_TWO_YEAR_REIGN_PATTERN.match(text))
      year_of_the_reign, monarch_name = match_two_year_reign_and_monarch(match)
    elsif (match = PARLIAMENT_AND_ONE_YEAR_REIGN_PATTERN.match(text))
      year_of_the_reign, monarch_name = match_one_year_reign_and_monarch(match)
    end

    if other_year_of_the_reign
      year_of_the_reign += ", #{other_year_of_the_reign}"
      monarch_name += ", #{other_monarch_name}"
    end
    return year_of_the_reign, monarch_name
  end

  SESSION_PARLIAMENT_PATTERN = /^([^ ]+) SESSION OF THE ([^ ]+) PARLIAMENT OF THE UNITED KINGDOM OF GREAT BRITAIN/

  def self.find_session_and_parliament text
    if (match = SESSION_PARLIAMENT_PATTERN.match(text) || (match = SESSION_PARLIAMENT_PATTERN.match(text.gsub('<lb/>',''))))
      session_of_parliament = match[1]
      number_of_parliament = match[2]
    end
    return session_of_parliament, number_of_parliament
  end

  BASE_SERIES_VOLUME_PATTERN = "([^ ]+) SERIES ?(&#x2014;|—|-|&#2014;) ?VOLUME ([^ ]+)"
  SERIES_VOLUME_PATTERN      = /^#{BASE_SERIES_VOLUME_PATTERN}$/
  SERIES_VOLUME_PART_PATTERN = /^#{BASE_SERIES_VOLUME_PATTERN} \(Part ([^ ]+)\)$/

  def self.find_series_and_volume_and_part text
    if (match = SERIES_VOLUME_PATTERN.match text)
      series_number = match[1]
      volume_in_series = match[3].chomp('.')
      volume_part_number = nil
    elsif (match = SERIES_VOLUME_PART_PATTERN.match text)
      series_number = match[1]
      volume_in_series = match[3].chomp('.')
      volume_part_number = match[4]
    else
      series_number = volume_in_series = volume_part_number = nil
    end

    return [series_number, volume_in_series, volume_part_number]
  end

  private

    def handle_titlepage titlepage, session
      session.titlepage_text = clean_html(titlepage).strip

      titlepage.children.each do |node|
        if is_element? 'p', node
          text = clean_html(node).strip
          series, volume, part = Hansard::HeaderParser.find_series_and_volume_and_part(text)
          if series
            session.series_number = series
            session.volume_in_series = volume
            session.volume_in_series_part_number = part
          else
            session_of_parliament, parliament = Hansard::HeaderParser.find_session_and_parliament(text)
            if session_of_parliament
              session.session_of_parliament = session_of_parliament
              session.number_of_parliament = parliament
            else
              year_of_the_reign, monarch_name = Hansard::HeaderParser.find_reign_and_monarch(text)
              if year_of_the_reign
                session.year_of_the_reign = year_of_the_reign
                session.monarch_name = monarch_name
              end
            end
          end
        end
      end
    end

    def create_session hansard
      if @source_file.house == 'commons'
        model_class = HouseOfCommonsSession
      elsif @source_file.house == 'lords'
        model_class = HouseOfLordsSession
      else
        raise 'cannot create session, cannot identify house from titlepage paragraphs'
      end

      session = model_class.new
      hansard.children.each do |node|
        if is_element? 'titlepage', node
          handle_titlepage node, session
        end
      end
      session.source_file_id = @source_file.id
      session
    end

end