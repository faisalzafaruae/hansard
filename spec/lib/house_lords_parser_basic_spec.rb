require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseLordsParser do

  before(:all) do
    Contribution.stub!(:acts_as_solr)
    @sitting_type = HouseOfLordsSitting
    @sitting_date = Date.new(1909, 9, 20)
    @sitting_date_text = 'Monday, 20th September, 1909.'
    @sitting_title = 'HOUSE OF LORDS.'
    @sitting_start_column = '1'
    @sitting_end_column = '1'
    @sitting_start_image = 'S5LV0003P0I0007'
    @sitting_text = nil

    @session = HouseOfLordsSession.new
    @session.save!
    source_file = SourceFile.new
    source_file.should_receive(:parliament_session).and_return(@session)
    file = 'houselords_example.xml'
    @sitting = Hansard::HouseLordsParser.new(File.dirname(__FILE__) + "/../data/#{file}", @logger, source_file).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
    ParliamentSession.delete_all
  end

  it 'should create sitting with association to parliament session' do
    @sitting.parliament_session.should == @session
  end

  it 'should create section for section element in debates' do
    @sitting.debates.sections[0].should_not be_nil
    @sitting.debates.sections[0].should be_an_instance_of(Section)
  end

  it 'should set title on section correctly' do
    @sitting.debates.sections[0].title.should == 'COMMISSION.'
  end

  it 'should create procedural contribution for paragraph element' do
    @sitting.debates.sections[0].contributions[0].should be_an_instance_of(ProceduralContribution)
    @sitting.debates.sections[0].contributions[0].xml_id.should == 'S5LV0003P0-00084'
    @sitting.debates.sections[0].contributions[0].text.should == 'The following Bills received the Royal Assent&#x2014;'
  end


  it_should_behave_like "All sittings"


end
