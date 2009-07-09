require 'test_helper'
require 'rails_xss_escaping'

class RailsXssTest < ActiveSupport::TestCase
  test "ERB::Util.h should mark its return value as safe and escape it" do
    escaped = ERB::Util.h("<p>")
    assert_equal "&lt;p&gt;", escaped
    assert escaped.html_safe?
  end

  test "ERB::Util.h should leave previously safe strings alone " do
    # TODO this seems easier to compose and reason about, but
    # this should be verified
    escaped = ERB::Util.h("<p>".html_safe!)
    assert_equal "<p>", escaped
    assert escaped.html_safe?
  end
end
