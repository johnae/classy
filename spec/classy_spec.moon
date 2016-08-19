define = require "classy"

describe "defining a class", ->

  it 'defines a new class', ->
    c = define 'AClass', =>
    assert.equal 'AClass', c.__type
    new = c.new!
    assert.equal 'AClass', new.__type

  describe 'instance methods', ->

    it 'are available on instances', ->
      c = define 'AClass', ->
        instance
          some_method: =>
            "some method"

      new = c.new!
      assert.nil c.some_method
      assert.not_nil new.some_method
      assert.equal "some method",  new\some_method!

  describe 'static methods', ->

    it 'are available on the class', ->
      c = define 'AClass', ->
        static
          some_method: =>
            "some method"

      new = c.new!
      assert.nil new.some_method
      assert.not_nil c.some_method
      assert.equal "some method",  c\some_method!

  describe 'initialization', ->

    it 'allows a custom initializer', ->
      c = define 'AClass', ->
        instance
          initialize: (var) =>
            @var = var
      new = c.new 'abcde'
      new2 = c.new 'cdefg'
      assert.equal 'abcde', new.var
      assert.equal 'cdefg', new2.var

    it 'allows calling new from the context of an instance', ->
      c = define 'AClass', ->
        instance
          initialize: (var) =>
            @var = var
          copy: =>
            @.new @var
      new = c.new 'abcde'
      assert.equal 'abcde', new.var
      new2 = new\copy!
      assert.equal 'abcde', new2.var
      assert.same new, new2
      new.var = 'cdefg'
      assert.not_equal new.var, new2.var

    it 'allows calling new from the context of the class', ->
      c = define 'AClass', ->
        static
          copy: =>
            @.new 10
        instance
          initialize: (var) =>
            @var = var
      new = c\copy!
      assert.equal 10, new.var
      new2 = c\copy!
      assert.same new, new2
      new.var = 20
      assert.not_equal new.var, new2.var

  describe 'inheritance', ->

    it 'allows subclassing', ->
      c1 = define 'AClass', ->
        static
          class_method: =>
            "class method"
        instance
          c1_method: =>
            "c1 method"
      c2 = define 'AClass2', ->
        parent c1

      new = c2.new!
      assert.equal "class method", c2\class_method!
      assert.equal "c1 method",  new\c1_method!

    it 'classes and instances know their identity', ->
      c1 = define 'AClass', ->
        instance
          c1_method: =>
            "c1 method"
      c2 = define 'AClass2', ->
        parent c1

      assert.truthy c1.is_a[c1]
      assert.falsy c1.is_a[c2]
      assert.truthy c2.is_a[c1]
      assert.truthy c2.is_a[c2]

      new = c1.new!
      new2 = c2.new!

      assert.truthy new.is_a[c1]
      assert.falsy new.is_a[c2]
      assert.truthy new2.is_a[c1]
      assert.truthy new2.is_a[c2]

    it 'subclasses can access their parent through "super"', ->
      c1 = define 'AClass', ->
        instance
          c1_method: =>
            "c1 method, var: #{@var}"
          initialize: (var) =>
            @var = var
      c2 = define 'AClass2', ->
        parent c1
        instance
          c1_method: =>
            'c1 sub method ' .. @super.c1_method @
          initialize: (var) =>
            @super.initialize @, var

      new2 = c2.new 'c2'
      assert.equal 'c2', new2.var
      assert.equal 'c1 sub method c1 method, var: c2', new2\c1_method!

    it 'a class can include methods from a given table', ->
      meth_table = {
        func1: (a) =>
          "m1 func1: #{a}"
        func2: (a) =>
          "m1 func2: #{a}"
      }
      meth_table2 = {
        func2: (a) =>
          "m2 func2: #{a}"
        func3: (a) =>
          "m2 func3: #{a}"
      }
      c1 = define 'AClass', ->
        include meth_table
        include meth_table2 -- should override included func2 from meth_table
        instance
          c1_method: =>
            "c1 method, var: #{@var}"
          initialize: (var) =>
            @var = var
      new = c1.new 'a'
      assert.equal 'a', new.var
      assert.equal 'm1 func1: 1', new\func1 1
      assert.equal 'm2 func2: 2', new\func2 2 -- in both meth_table and meth_table2, should be from meth_table2
      assert.equal 'm2 func3: 3', new\func3 3

  describe 'properties', ->

    it 'allows simple property getters', ->
      c = define 'AClass', ->
        properties
          something: => @number * 2
        instance
          initialize: (num) =>
            @number = num

      new = c.new(1)
      new2 = c.new(2)
      assert.equal 1, new.number
      assert.equal 2, new2.number
      assert.equal 2, new.something
      assert.equal 4, new2.something

    it 'allows full properties (getters/setters)', ->
      c = define 'AClass', ->
        properties
          something:
            get: => @number * 2
            set: (v) => @number = v
        instance
          initialize: (num) =>
            @number = num

      new = c.new(1)
      new2 = c.new(2)
      assert.equal 1, new.number
      assert.equal 2, new2.number
      assert.equal 2, new.something
      assert.equal 4, new2.something
      new.something = 10
      new2.something = 20
      assert.equal 10, new.number
      assert.equal 20, new2.number
      assert.equal 20, new.something
      assert.equal 40, new2.something

  describe 'accessors', ->

    it 'allows accessors (getters/setters for internal table variable)', ->

      c = define 'AClass', ->
        accessors
          attributes: {'name', 'age'}
        instance
          initialize: (name, age) =>
            @attributes = {:name, :age}

      new = c.new 'John', 38
      new2 = c.new 'Axel', 28
      assert.same {name: 'John', age: 38}, new.attributes
      assert.same {name: 'Axel', age: 28}, new2.attributes
      assert.equal 'John', new.name
      assert.equal 38, new.age
      assert.equal 'Axel', new2.name
      assert.equal 28, new2.age
      new.name = 'Mary'
      new.age = 50
      assert.equal 'Mary', new.name
      assert.equal 50, new.age
      assert.equal 'Axel', new2.name
      assert.equal 28, new2.age

    it 'allows overriding an accessors getter using a property', ->
      c = define 'AClass', ->
        accessors
          attributes: {'name', 'age'}
        properties
          age: =>
            if @attributes.age < 18
              'underage'
            else
              'grown-up'
        instance
          initialize: (name, age) =>
            @attributes = {:name, :age}

      new = c.new 'Robert', 12
      assert.equal 'Robert', new.name
      assert.equal 12, new.attributes.age
      assert.equal 'underage', new.age
      new.age = 18
      assert.equal 18, new.attributes.age
      assert.equal 'grown-up', new.age

  describe 'metamethods', ->
    c = define 'AClass', ->
      meta
        __add: (other) =>
          @var + other.var
      instance
        initialize: (var) =>
          @var = var
    new1 = c.new 10
    new2 = c.new 6
    assert.equal 16, new1 + new2

  describe 'missing property delegation', ->

    it 'allows a default delegator for missing properties', ->
      c = define 'AClass', ->
        -- you can define both get and set
        -- but in that case there be dragons
        -- using only get is much simpler if
        -- feasible
        missing_property
          get: (k) =>
            values = rawget @, 'values'
            if type(values) == 'table'
              values[k]
          set: (k, v) =>
            values = rawget @, 'values'
            if type(values) == 'table'
              values[k] = v
            else
              rawset @, k, v
        properties
          wuut: => 200
        instance
          initialize: =>
            @values = {a: 100, b: 200}

      new = c.new!
      assert.nil new.what
      assert.nil new.waat
      assert.equal 200, new.wuut
      new.what = 100
      assert.equal 100, new.what
      assert.nil new.waat
      assert.equal 200, new.wuut
      assert.same {a: 100, b: 200, what: 100}, new.values

    it 'allows specifying only a get delegator for missing properties', ->
      c = define 'AClass', ->
        missing_property
          get: (k) =>
            values = rawget @, 'values'
            if type(values) == 'table'
              values[k]
        properties
          wuut: => 200
        instance
          initialize: =>
            @values = {a: 100, b: 200}

      new = c.new!
      assert.nil new.what
      assert.nil new.waat
      assert.equal 200, new.wuut
      new.what = 100
      assert.equal 100, new.what
      assert.nil new.waat
      assert.equal 200, new.wuut
      -- now what isn't set in values but on instance
      assert.same {a: 100, b: 200}, new.values

  describe 'util', ->

    it 'the class initializer context has access to the class being defined via @', ->
      local klazz
      c = define 'AClass', ->
        klazz = @
      assert.equal c.__name, klazz.__name

    it 'the class initializer can do some interesting things via access to self', ->
      c = define 'AClass', ->
        @__instance.hello = => "hello"
        @__instance.initialize = (num) => @var = num
        @__meta.__add = (other) =>
          @var + other.var
        @class_method = =>
          "class method"

      new = c.new 10
      new2 = c.new 11
      assert.equal 'hello', new\hello!
      assert.equal 21, new + new2
      assert.equal 'class method', c\class_method!

    it 'allows copying an instance', ->
      c = define 'AClass', ->
        accessors
          attributes: {'name', 'age'}
        properties
          capitalized_name: => @name\upper!
          age: =>
            if @attributes.age < 18
              'underage'
            else
              'grown-up'
        instance
          initialize: (name, age) =>
            @attributes = {:name, :age}

      new = c.new 'John', 38
      copy = new\dup!
      assert.same new, copy
      copy.name = 'Axel'
      assert.equal 'John', new.name
      assert.equal 'Axel', copy.name
      assert.not_same new, copy
      assert.equal 'JOHN', new.capitalized_name
      assert.equal 'AXEL', copy.capitalized_name
