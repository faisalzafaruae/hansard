require File.dirname(__FILE__) + '/../spec_helper'

describe Sitting do

  before(:each) do
    @sitting = Sitting.new
  end

  it "should be valid" do
    @sitting.should be_valid
  end

end

describe Sitting, ".first_image_source" do

  it "should return the first image source " do
    sitting = Sitting.new(:start_image_src => "image2")
    sitting.first_image_source.should == "image2"
  end

  it "should return nil if the sitting has no image sources" do
    sitting = Sitting.new(:start_image_src => nil)
    sitting.first_image_source.should be_nil
  end

end

describe Sitting, ".find_by_column_and_date_range" do

  before do
    @start_date = Date.new(2006,1,1)
    @end_date = Date.new(2007,1,1)
    @first_sitting = Sitting.create(:date => Date.new(2006, 6, 6), :start_column => "44")
    @second_sitting = Sitting.create(:date => Date.new(2006, 6, 6), :start_column => "55")
  end
  
  it "should return the correct sitting for a column that is the start column of a sitting" do
    Sitting.find_by_column_and_date_range(44, @start_date, @end_date).should == @first_sitting
    Sitting.find_by_column_and_date_range(55, @start_date, @end_date).should == @second_sitting
  end
    
  it "should return the correct sitting for a column that is within a sitting" do
    Sitting.find_by_column_and_date_range(45, @start_date, @end_date).should == @first_sitting
    Sitting.find_by_column_and_date_range(56, @start_date, @end_date).should == @second_sitting
  end
  
end

