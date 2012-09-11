require 'active_support/deprecation'


module ActiveSupport #:nodoc:
  class SafeBuffer < String
    UNSAFE_STRING_METHODS = %w(
      capitalize chomp chop delete downcase gsub lstrip next reverse rstrip
      slice squeeze strip sub succ swapcase tr tr_s upcase prepend
    )

    alias_method :original_concat, :concat
    private :original_concat

    class SafeConcatError < StandardError
      def initialize
        super 'Could not concatenate to the buffer because it is not html safe.'
      end
    end

    def [](*args)
      if args.size < 2
        super
      else
        if html_safe?
          new_safe_buffer = super
          new_safe_buffer.instance_eval { @html_safe = true }
          new_safe_buffer
        else
          to_str[*args]
        end
      end
    end

    def safe_concat(value)
      raise SafeConcatError unless html_safe?
      original_concat(value)
    end

    def initialize(*)
      @html_safe = true
      super
    end

    def initialize_copy(other)
      super
      @html_safe = other.html_safe?
    end

    def clone_empty
      self[0, 0]
    end

    def concat(value)
      if !html_safe? || value.html_safe?
        super(value)
      else
        super(ERB::Util.h(value))
      end
    end
    alias << concat

    def +(other)
      dup.concat(other)
    end

    def %(args)
      args = Array(args).map do |arg|
        if !html_safe? || arg.html_safe?
          arg
        else
          ERB::Util.h(arg)
        end
      end

      self.class.new(super(args))
    end

    def html_safe?
      defined?(@html_safe) && @html_safe
    end

    def to_s
      self
    end

    def to_param
      to_str
    end

    def encode_with(coder)
      coder.represent_scalar nil, to_str
    end

    UNSAFE_STRING_METHODS.each do |unsafe_method|
      if 'String'.respond_to?(unsafe_method)
        class_eval <<-EOT, __FILE__, __LINE__ + 1
          def #{unsafe_method}(*args, &block)       # def capitalize(*args, &block)
            to_str.#{unsafe_method}(*args, &block)  #   to_str.capitalize(*args, &block)
          end                                       # end

          def #{unsafe_method}!(*args)              # def capitalize!(*args)
            @html_safe = false                      #   @html_safe = false
            super                                   #   super
          end                                       # end
        EOT
      end
    end
  end
end

class String
  def html_safe?
    defined?(@_rails_html_safe)
  end

  def html_safe!
    ActiveSupport::Deprecation.warn("Use html_safe with your strings instead of html_safe! See http://yehudakatz.com/2010/02/01/safebuffers-and-rails-3-0/ for the full story.", caller)
    @_rails_html_safe = true
    self
  end

  def add_with_safety(other)
    result = add_without_safety(other)
    if html_safe? && also_html_safe?(other)
      result.html_safe!
    else
      result
    end
  end
  alias_method :add_without_safety, :+
  alias_method :+, :add_with_safety

  def concat_with_safety(other_or_fixnum)
    result = concat_without_safety(other_or_fixnum)
    unless html_safe? && also_html_safe?(other_or_fixnum)
      remove_instance_variable(:@_rails_html_safe) if defined?(@_rails_html_safe)
    end
    result
  end

  alias_method_chain :concat, :safety
  undef_method :<<
  alias_method :<<, :concat_with_safety

  private
    def also_html_safe?(other)
      other.respond_to?(:html_safe?) && other.html_safe?
    end
end
