module Assistant
  # Raised by an adapter when the model call fails or returns nothing usable.
  class AdapterError < StandardError; end
end
