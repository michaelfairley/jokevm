require "vm"

module JokeVM
  RSpec.describe VM do
    it "can add numbers" do
      method = Method.new([
        VM::ICONST_2,
        VM::ICONST_2,
        VM::IADD,
        VM::IRETURN
      ])

      vm = VM.new({1 => method}, 1)

      result = vm.run

      expect( result ).to eq 4
    end

    it "can branch" do
      method = Method.new([
        VM::ICONST_0,
        VM::IFNE, 0, 8,
        VM::ICONST_1,
        VM::GOTO, 0, 9,
        VM::ICONST_2,
        VM::ICONST_3,
      ])

      vm = VM.new({1 => method}, 1)
      expect( vm.stack ).to eq []

      vm.step
      expect( vm.stack ).to eq [0]

      vm.step
      expect( vm.stack ).to eq []

      vm.step
      expect( vm.stack ).to eq [1]

      vm.step
      expect( vm.stack ).to eq [1]

      vm.step
      expect( vm.stack ).to eq [1, 3]
    end

    it "can store stuff in locals" do
      method = Method.new([
        VM::ICONST_1,
        VM::ISTORE_0,
        VM::ICONST_2,
        VM::ISTORE_1,
        VM::ICONST_3,
        VM::ISTORE_2,
        VM::ICONST_4,
        VM::ISTORE_3,
        VM::ICONST_5,
        VM::ISTORE, 4,
        VM::ILOAD_0,
        VM::ILOAD_1,
        VM::IADD,
        VM::ILOAD_2,
        VM::IADD,
        VM::ILOAD_3,
        VM::IADD,
        VM::ILOAD, 4,
        VM::IADD,
        VM::IRETURN,
      ])

      vm = VM.new({1 => method}, 1)

      expect( vm.run ).to eq(15)
    end

    it "can invoke static methods" do
      one = Method.new([
        VM::ICONST_1,
        VM::IRETURN,
      ])

      two = Method.new([
        VM::ICONST_2,
        VM::IRETURN,
      ])

      add = Method.new([
        VM::INVOKESTATIC, 0, 10,
        VM::INVOKESTATIC, 0, 11,
        VM::IADD,
        VM::IRETURN,
      ])

      vm = VM.new(
        {
          10 => one,
          11 => two,
          1 => add,
        },
        1
      )
      vm.step
      expect( vm.run ).to eq(3)
    end

    it "can construct objects and do stuff with them" do
      object_init = Method.new([
        VM::RETURN,
      ])

      constructor = Method.new([
        VM::ALOAD_0,
        VM::INVOKESPECIAL, 0, 1,
        VM::RETURN,
      ])

      two = Method.new([
        VM::ICONST_2,
        VM::IRETURN,
      ])

      caller = Method.new([
          VM::NEW, 0, 2,
          VM::DUP,
          VM::INVOKESPECIAL, 0, 3,
          VM::INVOKEVIRTUAL, 0, 4,
      ])

      two_class = Class.new

      vm = VM.new(
        {
          1 => object_init,
          2 => two_class,
          3 => constructor,
          4 => two,
          88 => caller,
        },
        88
      )
      expect( vm.stack ).to eq []

      10.times { vm.step }
      expect( vm.stack ).to eq [2]
    end

    it "can use object fields" do
      object_init = Method.new([
        VM::RETURN,
      ])

      constructor = Method.new([
        VM::ALOAD_0,
        VM::INVOKESPECIAL, 0, 1,
        VM::ALOAD_0,
        VM::ICONST_2,
        VM::PUTFIELD, 0, 5,
        VM::RETURN,
      ])

      two = Method.new([
        VM::ALOAD_0,
        VM::GETFIELD, 0, 5,
        VM::IRETURN,
      ])

      caller = Method.new([
        VM::NEW, 0, 2,
        VM::DUP,
        VM::INVOKESPECIAL, 0, 3,
        VM::INVOKEVIRTUAL, 0, 4,
        VM::IRETURN,
      ])

      two_class = Class.new

      num_field = FieldDef.new(two_class, :x)

      vm = VM.new(
        {
          1 => object_init,
          2 => two_class,
          3 => constructor,
          4 => two,
          5 => num_field,
          88 => caller,
        },
        88
      )
      expect( vm.run ).to eq(2)
    end

    it "can pass arguments to static methods" do
      main = Method.new([
        VM::ICONST_1,
        VM::ICONST_2,
        VM::INVOKESTATIC, 0, 2,
        VM::IRETURN,
      ])

      sub = Method.new([
        VM::ILOAD_0,
        VM::ILOAD_1,
        VM::ISUB,
        VM::IRETURN,
      ], 2)

      vm = VM.new(
        {
          1 => main,
          2 => sub,
        },
        1
      )
      vm.step
      expect( vm.run ).to eq(-1)
    end

    it "can pass arguments to virtual methods" do
      object_init = Method.new([
        VM::RETURN,
      ])

      constructor = Method.new([
        VM::ALOAD_0,
        VM::INVOKESPECIAL, 0, 1,
        VM::RETURN,
      ])

      main = Method.new([
        VM::NEW, 0, 2,
        VM::DUP,
        VM::INVOKESPECIAL, 0, 3,
        VM::ICONST_1,
        VM::ICONST_2,
        VM::INVOKEVIRTUAL, 0, 4,
        VM::IRETURN,
      ])

      sub = Method.new([
        VM::ILOAD_1,
        VM::ILOAD_2,
        VM::ISUB,
        VM::IRETURN,
      ], 2)

      klass = Class.new

      vm = VM.new(
        {
          1 => object_init,
          2 => klass,
          3 => constructor,
          4 => sub,
          5 => main,
        },
        5
      )
      vm.step
      expect( vm.run ).to eq(-1)
    end

    it "can pass arguments to constructors" do
      object_init = Method.new([
        VM::RETURN,
      ])

      constructor = Method.new([
        VM::ALOAD_0,
        VM::INVOKESPECIAL, 0, 4,
        VM::ALOAD_0,
        VM::ILOAD_1,
        VM::ILOAD_2,
        VM::ISUB,
        VM::PUTFIELD, 0, 3,
        VM::RETURN,
      ], 2)

      main = Method.new([
        VM::NEW, 0, 1,
        VM::DUP,
        VM::ICONST_1,
        VM::ICONST_2,
        VM::INVOKESPECIAL, 0, 2,
        VM::GETFIELD, 0, 3,
        VM::IRETURN,
      ])

      klass = Class.new

      value = FieldDef.new(klass, :value)

      vm = VM.new(
        {
          1 => klass,
          2 => constructor,
          3 => value,
          4 => object_init,
          5 => main,
        },
        5
      )
      vm.step
      expect( vm.run ).to eq(-1)
    end
  end
end
