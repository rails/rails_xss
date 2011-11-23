module ActionView
  class Base
    def self.xss_safe?
      true
    end

    module WithSafeOutputBuffer
      # Rails version of with_output_buffer uses '' as the default buf
      def with_output_buffer(buf = ActiveSupport::SafeBuffer.new) #:nodoc:
        super buf
      end
    end

    include WithSafeOutputBuffer
  end

  module Helpers
    module CaptureHelper
      def content_for(name, content = nil, &block)
        ivar = "@content_for_#{name}"
        content = capture(&block) if block_given?
        instance_variable_set(ivar, "#{instance_variable_get(ivar)}#{ERB::Util.h(content)}".html_safe)
        nil
      end
    end    

    module TextHelper
      def concat(string, unused_binding = nil)
        if unused_binding
          ActiveSupport::Deprecation.warn("The binding argument of #concat is no longer needed.  Please remove it from your views and helpers.", caller)
        end

        output_buffer.concat(string)
      end

      def simple_format(text, html_options={})
        start_tag = tag('p', html_options, true)
        text = ERB::Util.h(text).to_str.dup
        text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
        text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")  # 2+ newline  -> paragraph
        text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
        text.insert 0, start_tag
        text.html_safe.safe_concat("</p>")
      end
    end

    module TagHelper
      private
        def content_tag_string_with_escaping(name, content, options, escape = true)
          content_tag_string_without_escaping(name, escape ? ERB::Util.h(content) : content, options, escape)
        end
        alias_method_chain :content_tag_string, :escaping
    end

    module UrlHelper
      def link_to(*args, &block)
        if block_given?
          options      = args.first || {}
          html_options = args.second
          concat(link_to(capture(&block), options, html_options))
        else
          name         = args.first
          options      = args.second || {}
          html_options = args.third

          url = url_for(options)

          if html_options
            html_options = html_options.stringify_keys
            href = html_options['href']
            convert_options_to_javascript!(html_options, url)
            tag_options = tag_options(html_options)
          else
            tag_options = nil
          end

          href_attr = "href=\"#{url}\"" unless href
          "<a #{href_attr}#{tag_options}>#{ERB::Util.h(name || url)}</a>".html_safe
        end
      end
    end
    
    module TranslationHelper
      HTML_SAFE_TRANSLATION_KEY_RE = /(\b|_|\.)html$/
      ESCAPE_INTERPOLATIONS_RESERVED_KEYS = I18n::Backend::Base::RESERVED_KEYS + [:locale, :raise, :cascade]

      # Replace translate to escape any interpolations when using keys ending
      # with html. We don't use method chaining because it can't cover edge cases
      # involving multiple keys.
      #
      # @see https://groups.google.com/group/rubyonrails-security/browse_thread/thread/2b61d70fb73c7cc5
      def translate(keys, options = {})
        if multiple_keys = keys.is_a?(Array)
          ActiveSupport::Deprecation.warn "Giving an array to translate is deprecated, please give a symbol or a string instead", caller
        end

        options[:raise] = true
        keys = scope_keys_by_partial(keys)
        html_safe_options = nil
        
        translations = keys.map do |key|
          if key.to_s =~ HTML_SAFE_TRANSLATION_KEY_RE
            unless html_safe_options
              html_safe_options = options.dup
              options.except(*ESCAPE_INTERPOLATIONS_RESERVED_KEYS).each do |name, value|
                html_safe_options[name] = ERB::Util.html_escape(value.to_s)
              end
            end
            I18n.translate(key, html_safe_options).html_safe
          else
            I18n.translate(key, options)
          end
        end

        if multiple_keys || translations.size > 1
          translations
        else
          translations.first
        end
      rescue I18n::MissingTranslationData => e
        keys = I18n.send(:normalize_translation_keys, e.locale, e.key, e.options[:scope])
        content_tag('span', keys.join(', '), :class => 'translation_missing')
      end
      alias :t :translate
    end
  end
end

module RailsXss
  module SafeHelpers
    def safe_helper(*names)
      names.each do |helper_method_name|
        aliased_target, punctuation = helper_method_name.to_s.sub(/([?!=])$/, ''), $1
        module_eval <<-END
          def #{aliased_target}_with_xss_safety#{punctuation}(*args, &block)
            raw(#{aliased_target}_without_xss_safety#{punctuation}(*args, &block))
          end
        END
        alias_method_chain helper_method_name, :xss_safety
      end
    end
  end
end

Module.class_eval { include RailsXss::SafeHelpers }
