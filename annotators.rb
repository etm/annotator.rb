class Annotator
  def self.+@
    Annotators::Stack.all << self
  end

  def +@
    Annotators::Stack.all << self
  end
end

module Annotators
  class Stack 
    def self.all
      @all ||= []  # access class level instance variables (because classes are objects too)
    end
  end

  def method_added(method_name)
    super

    return if Stack.all.empty?

    original   = instance_method(method_name)
    decorators = Stack.all.pop(Stack.all.length)
    visibility = if private_method_defined?(method_name)
      :private
    elsif protected_method_defined?(method_name)
      :protected
    else
      :public
    end

    define_method method_name do |*args, &blk|
      args = decorators.reverse.inject(args) do |res, decorator|
        decorator = decorator.new if decorator.respond_to?(:new)
        decorator.respond_to?(:input) ? decorator.input(*res) : res
      end
      result = decorators.inject( Proc.new{ original.bind(self).call(*args,&blk) } ) do |b, decorator|
        decorator = decorator.new if decorator.respond_to?(:new)
        decorator.respond_to?(:wrap) ? Proc.new{ decorator.wrap(&b) } : b
      end.call
      decorators.reverse.inject(result) do |res, decorator|
        decorator = decorator.new if decorator.respond_to?(:new)
        decorator.respond_to?(:output) ? decorator.output(res) : res
      end
    end
    send visibility, method_name
  end
end
