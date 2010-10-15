unless $gems_rake_task
  if Rails::VERSION::MAJOR != 2 || Rails::VERSION::MINOR != 3 || Rails::VERSION::TINY < 8
    $stderr.puts "rails_xss requires Rails 2.3.8 or later. Please upgrade to enable automatic HTML safety."
  else
    require 'rails_xss'
  end
end
