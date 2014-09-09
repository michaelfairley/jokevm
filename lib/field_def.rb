module JokeVM
  class FieldDef
    attr_reader :name

    def initialize(klass, name)
      @klass = klass
      @name = name
    end
  end
end
