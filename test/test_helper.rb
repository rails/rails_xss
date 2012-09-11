$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require File.expand_path('../app/config/environment', __FILE__)
MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1] # rails 2.3 vs ruby 1.9
require File.expand_path('../../init', __FILE__)
require 'active_support/test_case'
require 'action_view/test_case'
require 'test/unit'
