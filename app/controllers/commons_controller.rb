class CommonsController < ApplicationController
  
  caches_page :index, :show_commons_hansard

  def show_commons_hansard
    date = UrlDate.new(params)
    if not date.is_valid_date?
      render :text => 'not valid date'
    else
      @sitting = HouseOfCommonsSitting.find_by_date(date.to_date.to_s)
      @marker_options = {}
      respond_to do |format|
        format.html
        format.xml { render :xml => @sitting.to_xml }
      end
    end
  end
  
  def show_commons_hansard_source
  end

  def index
    @sittings = HouseOfCommonsSitting.find(:all)
  end
  
end