require "forwardable"

require "frame"
require "method"
require "class"
require "object"

module JokeVM
  class VM
    extend Forwardable

    ALOAD_0 = 0x2a
    DUP = 0x59
    GOTO = 0xa7
    IADD = 0x60
    ICONST_0 = 0x03
    ICONST_1 = 0x04
    ICONST_2 = 0x05
    ICONST_3 = 0x06
    ICONST_4 = 0x07
    ICONST_5 = 0x08
    IFNE = 0x9a
    ILOAD = 0x15
    ILOAD_0 = 0x1a
    ILOAD_1 = 0x1b
    ILOAD_2 = 0x1c
    ILOAD_3 = 0x1d
    INVOKESPECIAL = 0xb7
    INVOKESTATIC = 0xb8
    INVOKEVIRTUAL = 0xb6
    IRETURN = 0xac
    ISTORE = 0x36
    ISTORE_0 = 0x3b
    ISTORE_1 = 0x3c
    ISTORE_2 = 0x3d
    ISTORE_3 = 0x3e
    NEW = 0xbb
    RETURN = 0xb1


    def_delegators :@frame, :stack
    def_delegators :stack, :push, :pop

    def initialize(constants, start)
      @constants = constants
      @frame = Frame.new(constants.fetch(start))
      @frames = []
    end

    def step
      opcode = nxt
      case opcode
      when ALOAD_0
        object = @frame.locals[0]
        push(object)
      when DUP
        value = pop
        push(value)
        push(value)
      when IADD
        a, b = pop(2)
        push(a + b)
      when GOTO
        addr = nxt2
        @frame.pc = addr
      when ICONST_0
        push(0)
      when ICONST_1
        push(1)
      when ICONST_2
        push(2)
      when ICONST_3
        push(3)
      when ICONST_4
        push(4)
      when ICONST_5
        push(5)
      when IFNE
        addr = nxt2

        pred = pop
        if pred != 0
          @frame.pc = addr
        end
      when ILOAD
        index = nxt
        push(@frame.locals[index])
      when ILOAD_0
        push(@frame.locals[0])
      when ILOAD_1
        push(@frame.locals[1])
      when ILOAD_2
        push(@frame.locals[2])
      when ILOAD_3
        push(@frame.locals[3])
      when INVOKESPECIAL
        method_number = nxt2
        method = @constants.fetch(method_number)
        object = pop
        @frames.push(@frame)
        @frame = Frame.new(method)
        @frame.locals[0] = object
      when INVOKESTATIC
        method_number = nxt2
        method = @constants.fetch(method_number)
        @frames.push(@frame)
        @frame = Frame.new(method)
      when INVOKEVIRTUAL
        method_number = nxt2
        method = @constants.fetch(method_number)
        object = pop
        @frames.push(@frame)
        @frame = Frame.new(method)
        @frame.locals[0] = object
      when IRETURN
        result = pop
        @frame = @frames.pop
        push(result)
      when ISTORE
        index = nxt
        value = pop
        @frame.locals[index] = value
      when ISTORE_0
        value = pop
        @frame.locals[0] = value
      when ISTORE_1
        value = pop
        @frame.locals[1] = value
      when ISTORE_2
        value = pop
        @frame.locals[2] = value
      when ISTORE_3
        value = pop
        @frame.locals[3] = value
      when NEW
        class_number = nxt2
        klass = @constants.fetch(class_number)
        object = Object.new(klass)
        push(object)
      when RETURN
        @frame = @frames.pop
      else
        raise "Unimplemented"
      end
    end

    def nxt2
      b1 = nxt
      b2 = nxt
      b1*256 + b2
    end

    def nxt
      result = @frame.method.byte(@frame.pc)
      @frame.pc += 1
      result
    end
  end
end
