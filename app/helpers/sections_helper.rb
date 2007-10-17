module SectionsHelper

  def section_previous_and_next_links(section)
    the_links = ""

    # if section.sitting
      # the_links << "<p><ol>"
      # the_links << "<li><a class='sitting-contents' href='#{section_url(section.previous_linkable_section)}'>#{section.sitting.title}</a></li>"
      # the_links << "</ol></p>"
    # end

    if section.previous_linkable_section
      the_links << "<p><ol>"
      the_links << "<li>&larr; <a class='prev-section' href='#{section_url(section.previous_linkable_section)}'>#{section.previous_linkable_section.title}</a></li>"
      the_links << "</ol></p>"
    end

    if section.next_linkable_section
      the_links << "<p><ol>"
      the_links << "<li><a class='next-section' href='#{section_url(section.next_linkable_section)}'>#{section.next_linkable_section.title}</a> &rarr;</li>"
      the_links << "</ol></p>"
    end

    the_links
  end
end