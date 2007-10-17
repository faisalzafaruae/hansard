class CommonsController < ApplicationController

  before_filter :check_valid_date, :only => [:show, :show_source]

  def index
    @sittings_by_year = HouseOfCommonsSitting.all_grouped_by_year
  end

  def show
    @part_id = params[:part_id].to_i if params[:part_id]
    @sittings = HouseOfCommonsSitting.find_in_resolution(@date, @resolution, @part_id)
    if @sittings.size > 1
      @sittings_by_year = [@sittings]
      render :action => "index" and return false 
    end
    @marker_options = {}
    if !@sittings.empty?
      @sitting = @sittings.first
      @day = true
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @sitting.to_xml }
    end
  end

  def show_source
    @sitting = HouseOfCommonsSitting.find_by_date(@date.to_s)
    data = @sitting.data_file.file.read
    respond_to do |format|
      format.xml { render :xml => data }
    end
  end

end