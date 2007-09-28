class WrittenAnswersController < ApplicationController

  before_filter :check_valid_date, :only => [:show, :show_source]
  
  def index
    @sittings = WrittenAnswersSitting.find(:all, :order => "date asc")
  end
  
  def show
    @sittings = WrittenAnswersSitting.find_in_resolution(@date, @resolution)
    render :action => "index" and return false if @sittings.size > 1
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
    @sitting = WrittenAnswersSitting.find_by_date(@date.to_s)
    data = @sitting.data_file.file.read
    respond_to do |format|
      format.xml { render :xml => data }
    end
  end
  
end