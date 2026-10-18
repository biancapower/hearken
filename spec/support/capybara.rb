require "capybara/rspec"

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: true,
    playwright_cli_executable_path: Rails.root.join("node_modules/.bin/playwright").to_s
  )
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright
  end
end
