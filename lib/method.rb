module JokeVM
  class Method
    def initialize(bytecode)
      @bytecode = bytecode
    end

    def byte(n)
      @bytecode[n]
    end
  end
end
