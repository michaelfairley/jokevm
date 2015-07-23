module JokeVM
  class Method
    attr_reader :arg_size

    def initialize(bytecode, arg_size = 0)
      @bytecode = bytecode
      @arg_size = arg_size
    end

    def byte(n)
      @bytecode[n]
    end
  end
end
