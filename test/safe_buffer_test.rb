require File.expand_path('../test_helper', __FILE__)

class SafeBufferTest < ActiveSupport::TestCase
  def setup
    @buffer = ActiveSupport::SafeBuffer.new
  end

  test "Should look like a string" do
    assert @buffer.is_a?(String)
    assert_equal "", @buffer
  end

  test "Should escape a raw string which is passed to them" do
    @buffer << "<script>"
    assert_equal "&lt;script&gt;", @buffer
  end

  test "Should NOT escape a safe value passed to it" do
    @buffer << "<script>".html_safe
    assert_equal "<script>", @buffer
  end

  test "Should not mess with an innocuous string" do
    @buffer << "Hello"
    assert_equal "Hello", @buffer
  end

  test "Should not mess with a previously escape test" do
    @buffer << ERB::Util.html_escape("<script>")
    assert_equal "&lt;script&gt;", @buffer
  end

  test "Should be considered safe" do
    assert @buffer.html_safe?
  end

  test "Should return a safe buffer when calling to_s" do
    new_buffer = @buffer.to_s
    assert_equal ActiveSupport::SafeBuffer, new_buffer.class
  end
  
  test "Should not return a safe buffer when using sub" do
    assert !@buffer.sub('', "asdf").html_safe?
  end
  
  test "mark as unsafe when using sub!" do
    assert_equal true, @buffer.html_safe?
    @buffer.sub!('', "asdf")
    assert_equal false, @buffer.html_safe?
    assert_equal "asdf", @buffer
  end
end
