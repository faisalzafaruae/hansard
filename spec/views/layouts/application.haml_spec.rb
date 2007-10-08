require File.dirname(__FILE__) + '/../../spec_helper'

describe "application.haml", " in general" do
  
  before do
    
  end
  
  def do_render
    render 'layouts/application.haml'
  end
  
  it 'should render the HTML 5 doctype of "<!DOCTYPE html>"' do
    do_render
    response.body[0..14].should == "<!DOCTYPE html>"
  end
  
  it 'should have the lang type of "en-GB"' do
    do_render
    response.should have_tag("html[lang='en-GB']")
  end
   
  it 'should have a link rel="author" with a link to "http://www.parliament.uk" and a title of "UK Parliament"' do
    do_render
    response.should have_tag("link[rel='author']", :title => "UK Parliament", :href => "http://www.parliament.uk")
  end
  
  it 'should have a link rel="bookmark" with a link to the current page and a title of "Millbank Systems: Hansard: May 3rd 1961: School Leavers, Acton"' do
    @title = "May 3rd 1961: School Leavers, Acton"
    assigns[:title] = @title
    do_render
    response.should assert_tag(:link, :attributes => {
      :rel => "bookmark",
      :title => "Millbank Systems: Hansard: " << @title,
      :href => request.request_uri
    })
  end
  
  it 'should have a link rel="contact"' do
    do_render
    response.should have_tag("link[rel='contact']")
  end
  
  it 'should have a link rel="first"' do
    do_render
    response.should have_tag("link[rel='first']")
  end
  
  it 'should have a link rel="help"' do
    do_render
    response.should have_tag("link[rel='help']")
  end
  
  it 'should have a link rel="index"' do
    do_render
    response.should have_tag("link[rel='index']")
  end
  
  it 'should have a link rel="last"' do
    do_render
    response.should have_tag("link[rel='last']")
  end
  
  it 'should have a link rel="license"' do
    do_render
    response.should have_tag("link[rel='license']")
  end
  
  it 'should have a link rel="licence"' do
    do_render
    response.should have_tag("link[rel='licence']")
  end
  
  it 'should have a link rel="next"' do
    do_render
    response.should have_tag("link[rel='next']")
  end
  
  it 'should have a link rel="prev"' do
    do_render
    response.should have_tag("link[rel='prev']")
  end
  
  it 'should have a link rel="tag"' do
    do_render
    response.should have_tag("link[rel='tag']")
  end
  
  it 'should have a link rel="up"' do
    do_render
    response.should have_tag("link[rel='up']")
  end
  
end


describe "application.haml", " when on a day page" do

  before do
    @title = 'hello world'
    @day = Date.new(2004, 9, 16)
    @sitting = mock_model(HouseOfCommonsSitting)
    @sitting.stub!(:date).and_return(@day)

    assigns[:sitting] = @sitting
    assigns[:day] = @day
    assigns[:title] = @title
  end

  def do_render
    render 'layouts/application.haml'
  end

  it 'should have a link rel="alternate" with appropriate title pointing to the xml source ' do
    do_render
    
    response.body.should assert_tag(:link, :attributes => { 
      :rel => "alternate", 
      :type => "text/xml",
      :title => "Source file for: hello world", 
      :href => "/commons/source/2004/sep/16.xml"
    })
  end

  it 'should have a link rel="alternate" with appropriate title pointing to the xml output ' do
    do_render
    
    response.body.should assert_tag(:link, :attributes => { 
      :rel => "alternate", 
      :type => "text/xml",
      :title => "XML file for: hello world", 
      :href => "/commons/2004/sep/16.xml"
    })
  end

end