class Sitting < ActiveRecord::Base
  set_primary_key :Id
  has_many :turns, :foreign_key => "SittingId", :conditions => "IsActive = 1", :order => "CreatedDate"
  has_many :sections, :foreign_key => "SittingId", :conditions => "IsActive = 1", :order => "CreatedDate"

  
  def date
    date = self.SatAt.strftime("%A %d %B %Y")
  end
  
  def year
    year = self.SatAt.year
  end
  
  def month
    month = self.SatAt.month
  end
  
 
  def intervals(start_time,end_time,length)
    
    intervals = []
    while start_time < end_time
      intervals << start_time
      start_time+=length.minutes
    end
    intervals
  
  end
  
  def original_turns
    self.turns.select{|turn|turn.CreatedDate.midnight == self.SatAt.midnight}
  end

  def original_sections
    self.sections.select{|section|section.CreatedDate.midnight == self.SatAt.midnight}
  end

  def Sitting.sittings_by_month(date)
    Sitting.find(:all).select do |sitting|
      (sitting.SatAt.year == date.year and sitting.SatAt.month == date.month)
    end
  end

  def turns_by_interval(start_time,end_time,length)

    intervals = self.intervals(start_time,end_time,length)
    turns_by_interval = {}
    
    intervals.each do |interval|
      turns_by_interval[interval] = []
    end
    
    self.turns.each do |turn|
      turn_interval = intervals.find{|interval|interval+length.minutes>turn.CreatedDate}
      turns_by_interval[turn_interval] << turn
    end
    
    turns_by_interval
  end
  
  def sections_by_interval(length)
  
    intervals = self.intervals(length)
    sections_by_interval = {}
    
    intervals.each do |interval|
      sections_by_interval[interval] = []
    end
    
    self.original_sections.each do |section|
      section_interval = intervals.find{|interval|interval+length.minutes>section.CreatedDate}
      sections_by_interval[section_interval] << section
    end
    
    sections_by_interval
  end

end
