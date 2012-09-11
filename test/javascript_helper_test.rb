require File.expand_path('../test_helper', __FILE__)

class JavascriptHelperTest < ActionView::TestCase
  def test_escape_javascript_with_safebuffer
    given = %('quoted' "double-quoted" new-line:\n </closed>)
    expect = %(\\'quoted\\' \\"double-quoted\\" new-line:\\n <\\/closed>)
    assert_equal expect, escape_javascript(given)
    assert_equal expect, escape_javascript(ActiveSupport::SafeBuffer.new(given))
  end
end
