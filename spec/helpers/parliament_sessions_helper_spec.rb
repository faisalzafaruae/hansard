require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSessionsHelper do
  fixtures :parliament_sessions

  it 'should create volumes in series title correctly' do
    volume_in_series_title('sixth').should == 'Volumes in Sixth Series, by number'
  end

  it 'should format monarch name correctly' do
    format_monarch_name('elizabeth_ii').should == 'Elizabeth II'
  end

  it 'should create link text to series url correctly' do
    series_link('SIXTH').should have_tag('a', :text => "Sixth Series")
  end

  it 'should create link text to monarch url correctly' do
    monarch_link('ELIZABETH II').should have_tag('a', :text => "Elizabeth II")
  end

  it 'should create link url to series url correctly' do
    series_link('SIXTH').should have_tag('a[href="/parliament_sessions/series/sixth"]')
  end

  it 'should create link url to monarch url correctly' do
    monarch_link('ELIZABETH II').should have_tag('a[href="/parliament_sessions/monarch/elizabeth_ii"]')
  end

  it 'should create link text to volume url correctly when session is for Commons with a volume part number' do
    session = parliament_sessions(:commons_session)
    text = 'Volume 424 (Part 1), Commons, 19 July&#x2014;4 October 2004'
    volume_link(session).should have_tag('a', :text => text)
  end

  it 'should create link url to volume index correctly when session is for Commons with a volume part number' do
    session = parliament_sessions(:commons_session)
    volume_link(session).should have_tag('a[href="/parliament_sessions/series/sixth/volume/424_1"]')
  end

  it 'should create link text to volume url correctly when session is for Lords with a Roman numeral volume number' do
    session = parliament_sessions(:lords_session)
    text = 'Volume CXXI (121), Lords, Wednesday, 12th November, 1941, to Thursday, 19th February, 1942'
    volume_link(session).should have_tag('a', :text => text)
  end

  it 'should create link url to volume index correctly when session is for Lords with a Roman numeral volume number' do
    session = parliament_sessions(:lords_session)
    volume_link(session).should have_tag('a[href="/parliament_sessions/series/fifth/volume/121"]')
  end

  it 'should create link text to commons session for year of the reign' do
    session = parliament_sessions(:commons_session)
    text = 'Fifty-third year of the reign, Commons'
    reign_link(session).should have_tag('a', :text => text)
  end

  it 'should create link text to lords session for year of the reign' do
    session = parliament_sessions(:lords_session)
    text = '5th &amp; 6th years of the reign, Lords'
    reign_link(session).should have_tag('a', :text => text)
  end

  it 'should create link url to session for year of the reign "FIFTY-THIRD"' do
    session = parliament_sessions(:commons_session)
    reign_link(session).should have_tag('a[href="/parliament_sessions/monarch/elizabeth_ii/regnal_years/fifty-third"]')
  end

  it 'should create link url to session for year of the reign "5 &amp; 6"' do
    session = parliament_sessions(:lords_session)
    reign_link(session).should have_tag('a[href="/parliament_sessions/monarch/george_vi/regnal_years/5_and_6"]')
  end

  it 'should make reign link text correct for "1 &amp; 2"' do
    reign_link_text('1 &amp; 2').should == '1st &amp; 2nd years of the reign'
  end

  it 'should make reign link text correct for "10 AND 11"' do
    reign_link_text('10 AND 11').should == '10th and 11th years of the reign'
  end

  it 'should make reign link text correct for "34 and 35"' do
    reign_link_text('34 and 35').should == '34th and 35th years of the reign'
  end

  it 'should make reign link text correct for "13 &#x0026; 14"' do
    reign_link_text('13 &#x0026; 14').should == '13th &#x0026; 14th years of the reign'
  end

  it 'should make reign link text correct for "12"' do
    reign_link_text('12').should == '12th year of the reign'
  end

  it 'should make column link correctly' do
    column_link(1, nil).should == '1'
  end
end
