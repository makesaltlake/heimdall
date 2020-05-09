module ActiveAdminHelper
  def format_multi_line_text(text)
    CGI.escapeHTML(text).split("\n").map(&:chomp).join("<br/>").html_safe
  end
end
