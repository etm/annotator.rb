#what: annotators.rb - A Neat Trick for DSL's and Otherwise

Jürgen Mangler
mailto: juergen.mangler@gmail.com

!!A N N O T A T O R S!!
    _                      _        _                 
   / \   _ __  _ __   ___ | |_ __ _| |_ ___  _ __ ___ 
  / _ \ | '_ \| '_ \ / _ \| __/ _` | __/ _ \| '__/ __|
 / ___ \| | | | | | | (_) | || (_| | || (_) | |  \__ \
/_/   \_\_| |_|_| |_|\___/ \__\__,_|\__\___/|_|  |___/

Python style decorators for ruby.

---

!!B A C K G R O U N D!!

00: [MyAnnotation]
01: public void csharp(object ...) {
02:   ... 
03: }

+++

00: @MyAnnotation
01: public void java(object ...) {
02:   ...
03: }

+++

00: @MyDecorator
01: def python():
02:   ...

---

!!B A C K G R O U N D!!

      P Y T H O N         ____
 ________________________/ O  \___/
<_/_\_/_\_/_\_/_\_/_\_/_______/   \

* In python its called decorators - confusing
  '''decorators != decorator pattern'''
* But you can use it to implement the decorator pattern

+++

00: @JSON
01: def ary():
02:   [1, 2, 3]

+++

00: @REST
01: @JSON
02: def ary():
03:   [1, 2, 3]

---

!!H O W T O   D O   I T!!
  _____
 /\/|\/\ R U B Y
 \  |  /
  \ | / 
   \|/ 
    -

* Yehuda Katz:    https://github.com/wycats/ruby_decorators
* Michal Fairley: https://github.com/michaelfairley/method_decorators
* Fred Wu:        https://github.com/fredwu/ruby_decorators

---

!!H O W T O   D O   I T!!
  _____
 /\/|\/\ R U B Y
 \  |  /
  \ | / 
   \|/ 
    -

00: +MyAnnotation
01: def ary(attr)
02:   [1, 2, 3]
03: end

* We can use class methods - a little bit like 'private'
+++
* Functionwise
    * modify parameters that are passed to a method
    * wrapping the method (e.g. to add a Timeout)
    * modify output of a method
+++
* We need a fancy first character - unary operators
---

      P Y T H O N         ____
 ________________________/ O  \___/
<_/_\_/_\_/_\_/_\_/_\_/_______/   \

---

      P Y T H O N               ____
 ___________      _____________/ O  \___/
<_/_\_/_\_/_      \_/_\_/_\_/_______/   \

---
!!I M P L E M E N T A T I O N !!

00: class Test < Annotator
01:   def input(*arg);
02:   def wrap;
03:   def output(result);
04: end

+++
00: class Annotator
01:   def self.+@
02:     Annotators::Stack.all << self
03:   end
04: 
05:   def +@
06:     Annotators::Stack.all << self
07:   end
08: end

---

!!I M P L E M E N T A T I O N !!

00: module Annotators
01:   class Stack 
02:     def self.all
03:       @all ||= []
04:     end
05:   end

---

!!I M P L E M E N T A T I O N !!

00: module Annotators
07:   def method_added(method_name)
08:     super
09: 
+++
10:     return if Stack.all.empty?
11: 
+++    
12:     decorators = Stack.all.pop(Stack.all.length)
13: 
+++    
14:     visibility = if private_method_defined?(method_name)
15:       :private
16:     elsif protected_method_defined?(method_name)
17:       :protected
18:     else
19:       :public
20:     end
21: 
+++    
22:     original   = instance_method(method_name)
        ...
---    

!!I M P L E M E N T A T I O N !!

00: module Annotators
07:   def method_added(method_name)
        ...
24:     define_method method_name do |*args, &blk|
25:
25:       args = decorators.reverse.inject(args) do |res, decorator|
26:         decorator = decorator.new if decorator.respond_to?(:new)
27:         decorator.respond_to?(:input) ? decorator.input(*res) : res
28:       end
29:
+++
30:       result = decorators.inject( 
                     Proc.new{ original.bind(self).call(*args,&blk) } 
                   ) do |b, decorator|
31:         decorator = decorator.new if decorator.respond_to?(:new)
32:         decorator.respond_to?(:wrap) ? Proc.new{ decorator.wrap(&b) } : b
33:       end.call
          ...
---    

!!I M P L E M E N T A T I O N !!

00: module Annotators
07:   def method_added(method_name)
        ...
24:     define_method method_name do |*args, &blk|
          ...
35:       decorators.reverse.inject(result) do |res, decorator|
36:         decorator = decorator.new if decorator.respond_to?(:new)
37:         decorator.respond_to?(:output) ? decorator.output(res) : res
38:       end
39:     end
+++    
40: 
41:     send visibility, method_name
42:   end  

---

!!F I N A L   E X A M P L E!!

00: class Test < Annotator
01:   def input(arg); arg << '_ru'; end
02:   def wrap; Timeout.timeout(5) { yield }; end
03:   def output(result); result << '_py'; end
04: end
05: 
06: class MyClass
07:   extend Annotators
08: 
09:   +Test
10:   def my_method(arg)
11:     arg
12:   end
13: end
14: 
15: m = MyClass.new
16: p m.my_method('hi') # -> 'hi_ru_py'

---

!!T H A N K S!!

juergen.mangler@gmail.com
https://github.com/etm/annotator.rb
