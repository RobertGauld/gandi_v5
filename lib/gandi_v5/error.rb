# frozen_string_literal: true

require_relative 'error/gandi_error'

class GandiV5
  # Generic error class for errors occuring using the API.
  class Error < RuntimeError
  end
end
