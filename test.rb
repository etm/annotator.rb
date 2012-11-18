require './annotators'

class Test < Annotator
  def input(arg)
    arg << '_input'
  end
  def result; end
end

class MyClass
  extend Annotators

  +Test
  def my_method(arg)
    arg
  end
end

m = MyClass.new
p m.my_method('a')
