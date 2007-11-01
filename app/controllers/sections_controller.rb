class SectionsController < ApplicationController

  before_filter :check_valid_date, :only => [:show, :nest, :unnest]
  after_filter :combine_markers, :only => [:show]

  def show
    sitting, @section = find_sitting_and_section(params[:type], @date, params[:id])
    @marker_options = {}
    @title = @section.plain_title
  end

  def nest
    if request.post?
      handle_nesting_change :nest!
    end
  end

  def unnest
    if request.post?
      handle_nesting_change :unnest!
    end
  end

  protected
  
    def combine_markers
      self.response.body = self.response.body.gsub(/<\/span>\s*<span class='sidenote'>/, "<br />")
    end
    
    def find_sitting_and_section type, date, slug
      return Sitting.find_sitting_and_section(type, date, slug)
    end

end