class DataFile < ActiveRecord::Base

  belongs_to :source_file
  has_one :sitting, :foreign_key => "data_file_id"

  validates_presence_of :name
  validates_presence_of :directory

  before_validation_on_create :default_attributes

  def self.reload_possible?
    not(ApplicationController.is_production?)
  end

  def reload_possible?
    (DataFile.reload_possible? and !date.nil?)
  end

  def self.from_file file
    name = File.basename(file)
    directory = 'data' + File.dirname(file).split('data')[1]
    data_file = DataFile.find_by_name_and_directory(name, directory)
    unless data_file
      data_file = DataFile.new :name => name, :directory => directory
      data_file.save!
    end
    data_file
  end

  def file
    File.new(File.join(directory, name))
  end

  def type_of_data
    type_of_data = name.split('_')[0]
    type_of_data.sub('house','')
  end

  def date_text
    prefix = name.split('_')[0]
    name.sub(prefix+'_', '').chomp('.xml').gsub('_', '/').sub('/part/', ' part ')
  end

  def date
    if date_text and date_text.size == 10
      begin
        Date.parse(date_text.gsub('/', '-'))
      rescue Exception => e
        nil
      end
    else
      nil
    end
  end

  def add_log text, persist=true
    self.log = '' if log.nil?
    puts text
    $stdout.flush
    if persist
     text = self.log + (text + "\n")
     self.log = text
    end
  end

  def reset_fields
    self.attempted_parse = false
    self.parsed = false
    self.attempted_save = false
    self.saved = false
    self.log = ''
    self.save!
  end

  def stripped_name
    self.directory.split('/').last
  end

  protected
    def default_attributes
      self.attempted_parse = 0 unless self.attempted_parse
      self.parsed = 0 unless self.parsed
      self.attempted_save = 0 unless self.attempted_save
      self.saved = 0 unless self.saved
    end

end
