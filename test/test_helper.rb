require "bundler/setup"
require "pathname"
root_path = Pathname(File.expand_path("..", __dir__))
$LOAD_PATH.unshift root_path.join("lib").to_s
require "minitest/autorun"
require "action_view/component/test_helpers"
require "pry-byebug"

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("config/environment.rb", __dir__)
require "rails/test_help"

# Print full backtrace
Rails.backtrace_cleaner.remove_silencers!

def get_html(result, css: "*")
  result = Nokogiri::HTML(result).css("body > *") if result.is_a?(String)
  result.to_html.strip if (result = result.css(css).first)
end
