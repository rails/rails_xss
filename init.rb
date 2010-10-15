unless $gems_rake_task
  major, minor, micro = Rails.version.split(".").map(&:to_i)
  if major == 2 && minor == 3 && micro >= 8
    require 'rails_xss'
  else
    $stderr.puts "rails_xss requires Rails 2.3.8 or later. Please upgrade to enable automatic HTML safety."
  end
end