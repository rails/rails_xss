require 'test_helper'

class TranslationHelperTest < ActionView::TestCase
  
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TranslationHelper

  def setup
    I18n.backend.store_translations(:en,
      :translations => {
        :hello => '<a>Hello World</a>',
        :html => '<a>Hello World</a>',
        :hello_html => '<a>Hello World</a>',
        :interpolated_text => 'Hello %{word}',
        :interpolated_html => '<a>Hello %{word}</a>',
      }
    )
  end
  
  def test_translate_hello
    assert_equal '<a>Hello World</a>', translate(:'translations.hello')
  end

  def test_returns_missing_translation_message_wrapped_into_span
    expected = '<span class="translation_missing">en, translations, missing</span>'
    assert_equal expected, translate(:"translations.missing")
    assert_equal true, translate(:"translations.missing").html_safe?
  end
  
  def test_with_array_of_keys_returns_missing_translation_message
    expected = '<span class="translation_missing">en, translations, missing</span>'
    assert_deprecated(/Giving an array to translate is deprecated/) do
      assert_equal expected, translate([:"translations.missing", :"translations.interpolated_text"])
    end
  end

  def test_translate_does_not_mark_plain_text_as_safe_html
    assert !translate(:'translations.hello').html_safe?
  end

  def test_translate_marks_translations_named_html_as_safe_html
    assert translate(:'translations.html').html_safe?
  end

  def test_translate_marks_translations_with_a_html_suffix_as_safe_html
    assert translate(:'translations.hello_html').html_safe?
  end

  def test_translate_escapes_interpolations_in_translations_with_a_html_suffix
    assert_equal '<a>Hello &lt;World&gt;</a>', translate(:'translations.interpolated_html', :word => '<World>')
    string_stub = (Struct.new(:to_s)).new; string_stub.to_s = '<World>'
    assert_equal '<a>Hello &lt;World&gt;</a>', translate(:'translations.interpolated_html', :word => string_stub)
  end
  
  def test_t_escapes_interpolations_in_translations_with_a_html_suffix
    assert_equal '<a>Hello &lt;World&gt;</a>', t(:'translations.interpolated_html', :word => '<World>')
  end

  def test_translate_does_not_escape_interpolations_in_translations_without_a_html_suffix
    assert_equal 'Hello <World>', translate(:'translations.interpolated_text', :word => '<World>')
  end
  
  def test_translate_escapes_interpolations_with_multiple_keys
    assert_deprecated(/Giving an array to translate is deprecated/) do
      assert_equal ['<a>Hello &lt;World&gt;</a>', 'Hello <World>'],
        translate([:'translations.interpolated_html', :'translations.interpolated_text'], :word => '<World>')
    end
  end

end
