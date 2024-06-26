# Classes
# -------

# * Class Definition
# * Class Instantiation
# * Inheritance and Super

test "classes with a four-level inheritance chain", ->

  class Base
    func: (string) ->
      "zero/#{string}"

    @static: (string) ->
      "static/#{string}"

  class FirstChild extends Base
    func: (string) ->
      super('one/') + string

  SecondChild = class extends FirstChild
    func: (string) ->
      super('two/') + string

  thirdCtor = ->
    @array = [1, 2, 3]

  class ThirdChild extends SecondChild
    constructor: -> thirdCtor.call this

    # Gratuitous comment for testing.
    func: (string) ->
      super('three/') + string

  result = (new ThirdChild).func 'four'

  ok result is 'zero/one/two/three/four'
  ok Base.static('word') is 'static/word'

  FirstChild::func = (string) ->
    super('one/').length + string

  result = (new ThirdChild).func 'four'

  ok result is '9two/three/four'

  ok (new ThirdChild).array.join(' ') is '1 2 3'


test "constructors with inheritance and super", ->

  identity = (f) -> f

  class TopClass
    constructor: (arg) ->
      @prop = 'top-' + arg

  class SuperClass extends TopClass
    constructor: (arg) ->
      identity super 'super-' + arg

  class SubClass extends SuperClass
    constructor: ->
      identity super 'sub'

  ok (new SubClass).prop is 'top-super-sub'


test "Overriding the static property new doesn't clobber Function::new", ->

  class OneClass
    @new: 'new'
    function: 'function'
    constructor: (name) -> @name = name

  class TwoClass extends OneClass
  delete TwoClass.new

  Function.prototype.new = -> new this arguments...

  ok (TwoClass.new('three')).name is 'three'
  ok (new OneClass).function is 'function'
  ok OneClass.new is 'new'

  delete Function.prototype.new


test "basic classes, again, but in the manual prototype style", ->

  Base = ->
  Base::func = (string) ->
    'zero/' + string
  Base::['func-func'] = (string) ->
    "dynamic-#{string}"

  FirstChild = ->
  SecondChild = ->
  ThirdChild = ->
    @array = [1, 2, 3]
    this

  ThirdChild extends SecondChild extends FirstChild extends Base

  FirstChild::func = (string) ->
    super('one/') + string

  SecondChild::func = (string) ->
    super('two/') + string

  ThirdChild::func = (string) ->
    super('three/') + string

  result = (new ThirdChild).func 'four'

  ok result is 'zero/one/two/three/four'

  ok (new ThirdChild)['func-func']('thing') is 'dynamic-thing'


test "super with plain ol' prototypes", ->

  TopClass = ->
  TopClass::func = (arg) ->
    'top-' + arg

  SuperClass = ->
  SuperClass extends TopClass
  SuperClass::func = (arg) ->
    super 'super-' + arg

  SubClass = ->
  SubClass extends SuperClass
  SubClass::func = ->
    super 'sub'

  eq (new SubClass).func(), 'top-super-sub'


test "'@' referring to the current instance, and not being coerced into a call", ->

  class ClassName
    amI: ->
      @ instanceof ClassName

  obj = new ClassName
  ok obj.amI()


test "super() calls in constructors of classes that are defined as object properties", ->

  class Hive
    constructor: (name) -> @name = name

  class Hive.Bee extends Hive
    constructor: (name) -> super

  maya = new Hive.Bee 'Maya'
  ok maya.name is 'Maya'


test "classes with JS-keyword properties", ->

  class Class
    class: 'class'
    name: -> @class

  instance = new Class
  ok instance.class is 'class'
  ok instance.name() is 'class'


test "Classes with methods that are pre-bound to the instance, or statically, to the class", ->

  class Dog
    constructor: (name) ->
      @name = name

    bark: =>
      "#{@name} woofs!"

    @static = =>
      new this('Dog')

  spark = new Dog('Spark')
  fido  = new Dog('Fido')
  fido.bark = spark.bark

  ok fido.bark() is 'Spark woofs!'

  obj = func: Dog.static

  ok obj.func().name is 'Dog'


test "a bound function in a bound function", ->

  class Mini
    num: 10
    generate: =>
      for i in [1..3]
        =>
          @num

  m = new Mini
  eq (func() for func in m.generate()).join(' '), '10 10 10'


test "contructor called with varargs", ->

  class Connection
    constructor: (one, two, three) ->
      [@one, @two, @three] = [one, two, three]

    out: ->
      "#{@one}-#{@two}-#{@three}"

  list = [3, 2, 1]
  conn = new Connection list...
  ok conn instanceof Connection
  ok conn.out() is '3-2-1'


test "calling super and passing along all arguments", ->

  class Parent
    method: (args...) -> @args = args

  class Child extends Parent
    method: -> super

  c = new Child
  c.method 1, 2, 3, 4
  ok c.args.join(' ') is '1 2 3 4'


test "classes wrapped in decorators", ->

  func = (klass) ->
    klass::prop = 'value'
    klass

  func class Test
    prop2: 'value2'

  ok (new Test).prop  is 'value'
  ok (new Test).prop2 is 'value2'


test "anonymous classes", ->

  obj =
    klass: class
      method: -> 'value'

  instance = new obj.klass
  ok instance.method() is 'value'


test "Implicit objects as static properties", ->

  class Static
    @static =
      one: 1
      two: 2

  ok Static.static.one is 1
  ok Static.static.two is 2


test "nothing classes", ->

  c = class
  ok c instanceof Function


test "classes with static-level implicit objects", ->

  class A
    @static = one: 1
    two: 2

  class B
    @static = one: 1,
    two: 2

  eq A.static.one, 1
  eq A.static.two, undefined
  eq (new A).two, 2

  eq B.static.one, 1
  eq B.static.two, 2
  eq (new B).two, undefined


test "classes with value'd constructors", ->

  counter = 0
  classMaker = ->
    inner = ++counter
    ->
      @value = inner

  class One
    constructor: classMaker()

  class Two
    constructor: classMaker()

  eq (new One).value, 1
  eq (new Two).value, 2
  eq (new One).value, 1
  eq (new Two).value, 2


test "executable class bodies", ->

  class A
    if true
      b: 'b'
    else
      c: 'c'

  a = new A

  eq a.b, 'b'
  eq a.c, undefined


test "#2502: parenthesizing inner object values", ->

  class A
    category:  (type: 'string')
    sections:  (type: 'number', default: 0)

  eq (new A).category.type, 'string'

  eq (new A).sections.default, 0


test "conditional prototype property assignment", ->
  debug = false

  class Person
    if debug
      age: -> 10
    else
      age: -> 20

  eq (new Person).age(), 20


test "mild metaprogramming", ->

  class Base
    @attr: (name) ->
      @::[name] = (val) ->
        if arguments.length > 0
          @["_#{name}"] = val
        else
          @["_#{name}"]

  class Robot extends Base
    @attr 'power'
    @attr 'speed'

  robby = new Robot

  ok robby.power() is undefined

  robby.power 11
  robby.speed Infinity

  eq robby.power(), 11
  eq robby.speed(), Infinity


test "namespaced classes do not reserve their function name in outside scope", ->

  one = {}
  two = {}

  class one.Klass
    @label = "one"

  class two.Klass
    @label = "two"

  eq typeof Klass, 'undefined'
  eq one.Klass.label, 'one'
  eq two.Klass.label, 'two'


test "nested classes", ->

  class Outer
    constructor: ->
      @label = 'outer'

    class @Inner
      constructor: ->
        @label = 'inner'

  eq (new Outer).label, 'outer'
  eq (new Outer.Inner).label, 'inner'


test "variables in constructor bodies are correctly scoped", ->

  class A
    x = 1
    constructor: ->
      x = 10
      y = 20
    y = 2
    captured: ->
      {x, y}

  a = new A
  eq a.captured().x, 10
  eq a.captured().y, 2


test "Issue #924: Static methods in nested classes", ->

  class A
    @B: class
      @c = -> 5

  eq A.B.c(), 5


test "`class extends this`", ->

  class A
    func: -> 'A'

  B = null
  makeClass = ->
    B = class extends this
      func: -> super + ' B'

  makeClass.call A

  eq (new B()).func(), 'A B'


test "ensure that constructors invoked with splats return a new object", ->

  args = [1, 2, 3]
  Type = (@args) ->
  type = new Type args

  ok type and type instanceof Type
  ok type.args and type.args instanceof Array
  ok v is args[i] for v, i in type.args

  Type1 = (@a, @b, @c) ->
  type1 = new Type1 args...

  ok type1 instanceof   Type1
  eq type1.constructor, Type1
  ok type1.a is args[0] and type1.b is args[1] and type1.c is args[2]

  # Ensure that constructors invoked with splats cache the function.
  called = 0
  get = -> if called++ then false else class Type
  new get() args...

test "`new` shouldn't add extra parens", ->

  ok new Date().constructor is Date


test "`new` works against bare function", ->

  eq Date, new ->
    Date


test "#1182: a subclass should be able to set its constructor to an external function", ->
  ctor = ->
    @val = 1
  class A
  class B extends A
    constructor: ctor
  eq (new B).val, 1

test "#1182: external constructors continued", ->
  ctor = ->
  class A
  class B extends A
    method: ->
    constructor: ctor
  ok B::method

test "#1313: misplaced __extends", ->
  nonce = {}
  class A
  class B extends A
    prop: nonce
    constructor: ->
  eq nonce, B::prop

test "#1182: execution order needs to be considered as well", ->
  counter = 0
  makeFn = (n) -> eq n, ++counter; ->
  class B extends (makeFn 1)
    @B: makeFn 2
    constructor: makeFn 3

test "#1182: external constructors with bound functions", ->
  fn = ->
    {one: 1}
    this
  class B
  class A
    constructor: fn
    method: => this instanceof A
  ok (new A).method.call(new B)

test "#1372: bound class methods with reserved names", ->
  class C
    delete: =>
  ok C::delete

test "#1380: `super` with reserved names", ->
  class C
    do: -> super
  ok C::do

  class B
    0: -> super
  ok B::[0]

test "#1464: bound class methods should keep context", ->
  nonce  = {}
  nonce2 = {}
  class C
    constructor: (@id) ->
    @boundStaticColon: => new this(nonce)
    @boundStaticEqual= => new this(nonce2)
  eq nonce,  C.boundStaticColon().id
  eq nonce2, C.boundStaticEqual().id

test "#1009: classes with reserved words as determined names", -> (->
  eq 'function', typeof (class @for)
  ok not /\beval\b/.test (class @eval).toString()
  ok not /\barguments\b/.test (class @arguments).toString()
).call {}

test "#1482: classes can extend expressions", ->
  id = (x) -> x
  nonce = {}
  class A then nonce: nonce
  class B extends id A
  eq nonce, (new B).nonce

test "#1598: super works for static methods too", ->

  class Parent
    method: ->
      'NO'
    @method: ->
      'yes'

  class Child extends Parent
    @method: ->
      'pass? ' + super

  eq Child.method(), 'pass? yes'

test "#1842: Regression with bound functions within bound class methods", ->

  class Store
    @bound: =>
      do =>
        eq this, Store

  Store.bound()

  # And a fancier case:

  class Store

    eq this, Store

    @bound: =>
      do =>
        eq this, Store

    @unbound: ->
      eq this, Store

    instance: =>
      ok this instanceof Store

  Store.bound()
  Store.unbound()
  (new Store).instance()

test "#1876: Class @A extends A", ->
  class A
  class @A extends A

  ok (new @A) instanceof A

test "#1813: Passing class definitions as expressions", ->
  ident = (x) -> x

  result = ident class A then x = 1

  eq result, A

  result = ident class B extends A
    x = 1

  eq result, B

test "#1966: external constructors should produce their return value", ->
  ctor = -> {}
  class A then constructor: ctor
  ok (new A) not instanceof A

test "#1980: regression with an inherited class with static function members", ->

  class A

  class B extends A
    @static: => 'value'

  eq B.static(), 'value'

test "#1534: class then 'use strict'", ->
  # [14.1 Directive Prologues and the Use Strict Directive](http://es5.github.com/#x14.1)
  nonce = {}
  error = 'do -> ok this'
  strictTest = "do ->'use strict';#{error}"
  return unless (try CoffeeScript.run strictTest, bare: yes catch e then nonce) is nonce

  throws -> CoffeeScript.run "class then 'use strict';#{error}", bare: yes
  doesNotThrow -> CoffeeScript.run "class then #{error}", bare: yes
  doesNotThrow -> CoffeeScript.run "class then #{error};'use strict'", bare: yes

  # comments are ignored in the Directive Prologue
  comments = ["""
  class
    ### comment ###
    'use strict'
    #{error}""",
  """
  class
    ### comment 1 ###
    ### comment 2 ###
    'use strict'
    #{error}""",
  """
  class
    ### comment 1 ###
    ### comment 2 ###
    'use strict'
    #{error}
    ### comment 3 ###"""
  ]
  throws (-> CoffeeScript.run comment, bare: yes) for comment in comments

  # [ES5 §14.1](http://es5.github.com/#x14.1) allows for other directives
  directives = ["""
  class
    'directive 1'
    'use strict'
    #{error}""",
  """
  class
    'use strict'
    'directive 2'
    #{error}""",
  """
  class
    ### comment 1 ###
    'directive 1'
    'use strict'
    #{error}""",
  """
  class
    ### comment 1 ###
    'directive 1'
    ### comment 2 ###
    'use strict'
    #{error}"""
  ]
  throws (-> CoffeeScript.run directive, bare: yes) for directive in directives

test "#2052: classes should work in strict mode", ->
  try
    do ->
      'use strict'
      class A
  catch e
    ok no

test "directives in class with extends ", ->
  strictTest = """
    class extends Object
      ### comment ###
      'use strict'
      do -> eq this, undefined
  """
  CoffeeScript.run strictTest, bare: yes

test "#2630: class bodies can't reference arguments", ->
  throws ->
    CoffeeScript.compile('class Test then arguments')

  # #4320: Don't be too eager when checking, though.
  class Test
    arguments: 5
  eq 5, Test::arguments

test "#2319: fn class n extends o.p [INDENT] x = 123", ->
  first = ->

  base = onebase: ->

  first class OneKeeper extends base.onebase
    one = 1
    one: -> one

  eq new OneKeeper().one(), 1


test "#2599: other typed constructors should be inherited", ->
  class Base
    constructor: -> return {}

  class Derived extends Base

  ok (new Derived) not instanceof Derived
  ok (new Derived) not instanceof Base
  ok (new Base) not instanceof Base

test "#2359: extending native objects that use other typed constructors requires defining a constructor", ->
  class BrokenArray extends Array
    method: -> 'no one will call me'

  brokenArray = new BrokenArray
  ok brokenArray not instanceof BrokenArray
  ok typeof brokenArray.method is 'undefined'

  class WorkingArray extends Array
    constructor: -> super
    method: -> 'yes!'

  workingArray = new WorkingArray
  ok workingArray instanceof WorkingArray
  eq 'yes!', workingArray.method()


test "#2782: non-alphanumeric-named bound functions", ->
  class A
    'b:c': =>
      'd'

  eq (new A)['b:c'](), 'd'


test "#2781: overriding bound functions", ->
  class A
    a: ->
        @b()
    b: =>
        1

  class B extends A
    b: =>
        2

  b = (new A).b
  eq b(), 1

  b = (new B).b
  eq b(), 2


test "#2791: bound function with destructured argument", ->
  class Foo
    method: ({a}) => 'Bar'

  eq (new Foo).method({a: 'Bar'}), 'Bar'


test "#2796: ditto, ditto, ditto", ->
  answer = null

  outsideMethod = (func) ->
    func.call message: 'wrong!'

  class Base
    constructor: ->
      @message = 'right!'
      outsideMethod @echo

    echo: =>
      answer = @message

  new Base
  eq answer, 'right!'

test "#3063: Class bodies cannot contain pure statements", ->
  throws -> CoffeeScript.compile """
    class extends S
      return if S.f
      @f: => this
  """

test "#2949: super in static method with reserved name", ->
  class Foo
    @static: -> 'baz'

  class Bar extends Foo
    @static: -> super

  eq Bar.static(), 'baz'

test "#3232: super in static methods (not object-assigned)", ->
  class Foo
    @baz = -> true
    @qux = -> true

  class Bar extends Foo
    @baz = -> super
    Bar.qux = -> super

  ok Bar.baz()
  ok Bar.qux()

test "#1392 calling `super` in methods defined on namespaced classes", ->
  class Base
    m: -> 5
    n: -> 4
  namespace =
    A: ->
    B: ->
  namespace.A extends Base

  namespace.A::m = -> super
  eq 5, (new namespace.A).m()
  namespace.B::m = namespace.A::m
  namespace.A::m = null
  eq 5, (new namespace.B).m()

  count = 0
  getNamespace = -> count++; namespace
  getNamespace().A::n = -> super
  eq 4, (new namespace.A).n()
  eq 1, count

  class C
    @a: ->
    @a extends Base
    @a::m = -> super
  eq 5, (new C.a).m()

test "dynamic method names and super", ->
  class Base
    @m: -> 6
    m: -> 5
    m2: -> 4.5
    n: -> 4
  A = ->
  A extends Base

  m = 'm'
  A::[m] = -> super
  m = 'n'
  eq 5, (new A).m()

  name = -> count++; 'n'

  count = 0
  A::[name()] = -> super
  eq 4, (new A).n()
  eq 1, count

  m = 'm'
  m2 = 'm2'
  count = 0
  class B extends Base
    @[name()] = -> super
    @::[m] = -> super
    "#{m2}": -> super
  b = new B
  m = m2 = 'n'
  eq 6, B.m()
  eq 5, b.m()
  eq 4.5, b.m2()
  eq 1, count

  class C extends B
    m: -> super
  eq 5, (new C).m()
