# we need to ensure we're running in bundler
begin
  Bundler
rescue
  abort("Make sure you're running 'bundle exec middleman'. If you are and still getting this error, config.rb needs attention.")
end

### 
# Compass
###

# Susy grids in Compass
# First: gem install compass-susy-plugin
# require 'susy'

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Haml
###

# CodeRay syntax highlighting in Haml
# First: gem install haml-coderay
# require 'haml-coderay'

# CoffeeScript filters in Haml
# First: gem install coffee-filter
# require 'coffee-filter'

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

###
# Page command
###

# Per-page layout changes:
# 
# With no layout
# page "/path/to/file.html", :layout => false
# 
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
# 
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

###
# Helpers
###

# Methods defined in the helpers block are available in templates
helpers do
  def custom_or_default_content(thingy)
      if content_for?(thingy)
        yield_content(thingy)
      else
        data.site.send(thingy) || ''
      end
  end
end

# Change the CSS directory
# set :css_dir, "alternative_css_directory"

# Change the JS directory
# set :js_dir, "alternative_js_directory"

# Change the images directory
# set :images_dir, "alternative_image_directory"

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
   activate :minify_css
  
  # Minify Javascript on build
   activate :minify_javascript
  
  # Enable cache buster
   activate :cache_buster
  
  # Use relative URLs
  activate :relative_assets
  
  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher
  
  # Or use a different image path
  # set :http_path, "/Content/images/"
end

activate :directory_indexes
page "/404.html", :directory_index => false
ignore "assets"

require 'susy'

## KSS Configuration
#

%w(
  index
  01_structure
  02_colors
  03_typography
  04_links
  05_buttons
  06_forms
  07_tables
  08_dialogs
  09_graphic
  10_navigation
  11_modules
).each do |name|
  page "styleguide/#{name}.html", :layout => "layouts/styleguide", :directory_index => false do
    @styleguide = Kss::Parser.new('source/stylesheets')
  end
end

# Methods defined in the helpers block are available in templates
helpers do
  # KSS: Generates a styleguide block. A little bit evil with @_out_buf, but
  # if you're using something like Rails, you can write a much cleaner helper
  # very easily.
  def styleguide_block(section, &block)
    @section = @styleguide.section(section)
    @example_html = kss_capture{ block.call }
    @_out_buf << partial('styleguide/block')
  end

  # KSS: Captures the result of a block within an erb template without spitting
  # it to the output buffer.
  def kss_capture(&block)
    out, @_out_buf = @_out_buf, ""
    yield
    @_out_buf
  ensure
    @_out_buf = out
  end

  # Calculate the years for a copyright
  def copyright_years(start_year)
    end_year = Date.today.year
    if start_year == end_year
      start_year.to_s
    else
      start_year.to_s + '-' + end_year.to_s
    end
  end
end
