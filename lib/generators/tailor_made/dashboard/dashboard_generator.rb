require "rails/generators/named_base"
require 'active_support/inflector'

class TailorMade::DashboardGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :namespace, type: :string, default: "tailor_made"

  def create_resource_query
    queries_dir = Rails.root.join("app/queries/#{namespace}")
    FileUtils.mkdir_p(queries_dir) unless File.directory?(queries_dir)
    destination = Rails.root.join(
      "app/queries/#{namespace}/#{regular_file_path}_query.rb",
    )

    template("query.rb.erb", destination)
  end

  def create_resource_controller
    destination = Rails.root.join(
      "app/controllers/#{namespace}/#{regular_file_path.pluralize}_controller.rb",
    )

    template("controller.rb.erb", destination)
  end

  def create_resource_view
    destination = Rails.root.join(
      "app/views/#{namespace}/#{regular_file_path.pluralize}/index.html.erb",
    )

    copy_file("index.html.erb", destination)
  end

  private

  def namespace
    options['namespace']
  end

  def regular_file_path
    (regular_class_path + [file_name]).map!(&:camelize).join("::").underscore
  end
end
