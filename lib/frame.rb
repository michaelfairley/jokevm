module JokeVM
  class Frame
    attr_reader :stack, :locals, :method
    attr_accessor :pc

    def initialize(method)
      @method = method
      @pc = 0
      @stack = []
      @locals = {}
    end
  end
end
