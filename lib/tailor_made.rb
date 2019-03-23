require "tailor_made/version"

require "groupdate"
require "pagy"
require 'pagy/extras/bootstrap'

require "groupdate/group_alias" # mockey patch

require "tailor_made/group_alias"
require "tailor_made/relation_alias"
require "tailor_made/methods"
require "tailor_made/query"

module TailorMade
  class Error < StandardError; end
  # Your code goes here...
end
