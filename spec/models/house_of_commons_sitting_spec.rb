require File.dirname(__FILE__) + '/../spec_helper'

def mock_sitting
  sitting = HouseOfCommonsSitting.new(:start_image_src => "source",
                        :start_column    => "1",
                        :date            => Date.new(1985, 12, 16),
                        :date_text       => "Monday 16th December 1985",
                        :text            => "some text")
  sitting.debates = Debates.new
  sitting
end

describe HouseOfCommonsSitting do
  before(:each) do
    @model = mock_sitting
    @mock_builder = mock("xml builder") 
    @mock_builder.stub!(:housecommons)  
  end

  it "should be valid" do
    @model.should be_valid
  end
  
  it_should_behave_like "an xml-generating model"
  
end

describe HouseOfCommonsSitting, ".to_xml" do
  
  before do
    @mock_builder = mock("xml builder")    
    @sitting = mock_sitting
  end
  
  it "should have a 'housecommons' tag" do
    @sitting.to_xml.should match(/<housecommons>.*?<\/housecommons>/)
  end
  
  it "should have an 'image' tag whose 'src' attribute contains the sitting's start_image_src" do
    @sitting.to_xml.should match(/<image src="source"\/>/)
  end
  
  it "should have a 'col' tag containing the sitting's start column" do
    @sitting.to_xml.should match(/<col>1<\/col>/)
  end
  
  it "should have a 'title' tag containing the sitting title" do
    @sitting.title = "test title"
    @sitting.to_xml.should match(/<title>#{@sitting.title}<\/title>/)
  end
  
  it "should have a 'date' tag with a format attribute containing the sitting date in yyyy-mm-dd format, containing the sitting date text" do
    @sitting.to_xml.should match(/<date format="1985-12-16">Monday 16th December 1985<\/date>/)
  end
  
  it "should render it's text" do
    @sitting.to_xml.should match(/some text/)
  end
  
  it "should call the to_xml method on each of it's debates, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    @mock_builder.stub!(:housecommons).and_yield
    [:image, :col, :title, :date, :<<].each { |field| @mock_builder.stub!(field) }    
    debates = mock_model(Debates)
    @sitting.debates = debates
    debates.should_receive(:to_xml).with(:builder => @mock_builder)
    @sitting.to_xml
  end

end