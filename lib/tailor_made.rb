require "tailor_made/version"

require "groupdate"
require "pagy"
require 'pagy/extras/bootstrap'

require_relative "./groupdate/group_alias" # mockey patch
require_relative "./groupdate/relation_builder" # mockey patch

require "tailor_made/methods"
require "tailor_made/query"

module TailorMade
  class Error < StandardError; end
  # Your code goes here...
end
