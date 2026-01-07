module ApplicationHelper
  class CodeRayify < Redcarpet::Render::HTML
    def block_code(code, language)
      language ||= :plaintext
      CodeRay.scan(code, language).div
    end
  end

  def markdown(text)
    # coderayified = CodeRayify.new(
    #   :filter_html => true,
    #   :hard_wrap => true
    # )
    #
    # options = {
    #   filter_html: true,
    #   hard_wrap: true,
    #   link_attributes: { rel: 'nofollow', target: "_blank" },
    #   space_after_headers: true,
    #   fenced_code_blocks: true,
    #   prettify: true
    # }
    #
    # renderer = Redcarpet::Render::HTML.new(options)
    # markdown = Redcarpet::Markdown.new(coderayified, options)
    #
    # markdown.render(text).html_safe
    coderayified = CodeRayify.new(
      :filter_html => true,
      :hard_wrap => true
    )

    options = {
      :fenced_code_blocks => true,
      :no_intra_emphasis => true,
      :autolink => true,
      :strikethrough => true,
      :lax_html_blocks => true,
      :superscript => true,
      prettify: true,
      space_after_headers: true,
      link_attributes: { rel: 'nofollow', target: "_blank" },
      filter_html: true,
      hard_wrap: true
    }

    markdown_to_html = Redcarpet::Markdown.new(coderayified, options)
    markdown_to_html.render(text).html_safe
  end
end
