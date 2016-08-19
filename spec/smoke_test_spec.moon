define = require "classy"
format = string.format

Date = define 'Date', ->
  properties
    age:
      get: =>
        now = os.date('*t')
        age = now.year - @year
        if now.month < @month
          age = age - 1
        else if now.month == @month
          if now.day < @day
            age = age - 1
        age
      set: (age) =>
        today = os.date('*t')
        @year = today.year - age
  static
    from_string: (str) =>
      y, m, d = str\match('(%d+)-(%d+)-(%d+)')
      y, m, d = tonumber(y), tonumber(m), tonumber(d)
      @.new y, m, d
  instance
    initialize: (year, month, day) =>
      @year, @month, @day = tonumber(year), tonumber(month), tonumber(day)
  meta
    __tostring: =>
      y, m, d = @year, format('%02d', @month), format('%02d', @day)
      "#{y}-#{m}-#{d}"

    __add: (num_days) =>
      s = num_days*24*60*60
      d = os.time year: @year, month: @month, day: @day
      newdate = os.date '*t', d+s
      @.new newdate.year, newdate.month, newdate.day

    __sub: (num_days) =>
      s = num_days*24*60*60
      d = os.time year: @year, month: @month, day: @day
      newdate = os.date '*t', d-s
      @.new newdate.year, newdate.month, newdate.day

Person = define 'Person', ->
  accessors
    attributes: {'firstname', 'lastname'}
  properties
    name: => "#{@firstname} #{@lastname}"
    birthdate:
      get: => tostring(@attributes.birthdate)
      set: (date) => @attributes.birthdate = Date\from_string(date)
    age:
      get: => @attributes.birthdate.age
      set: (age) => @attributes.birthdate.age = age
  static
    find: (name) =>
      name = name\lower!
      @some_people or= {
        @.new('Bob', 'Johnsson', '1964-03-02'),
        @.new('Mary', 'Jensen', '1983-05-10'),
        @.new('Victoria', 'Hammadi', '1989-12-15')
      }
      found = {}
      for p in *@some_people
        pname = p.name\lower!
        if pname\match name
          found[#found + 1] = p
      found
  instance
    initialize: (firstname, lastname, birthdate) =>
      @attributes = {:firstname, :lastname, birthdate: Date\from_string(birthdate)}

describe 'Smoke test', ->

  describe 'Date', ->

    it 'calculates age from date', ->
      d = Date.new 2000, 01, 01
      today = os.date('*t')
      age = today.year - d.year
      if today.month < d.month
        age -= 1
      else if today.month == d.month
        if today.day < d.day
          age -= 1
      assert.equal age, d.age

    it 'changes the date accordingly by setting age', ->
      d = Date.new 2000, 01, 01
      age = 10
      d.age = age
      assert.equal 10, d.age
      somedate = os.date('*t')
      somedate.month, somedate.day = 1, 1
      somedate.year -= age
      expected_date = "#{somedate.year}-#{format('%02d', somedate.month)}-#{format('%02d', somedate.day)}"
      assert.equal expected_date, tostring(d)

    it 'has a meta method tostring', ->
      d = Date.new 2000, 01, 01
      assert.equal '2000-01-01', tostring(d)

    it 'has a meta method add which adds days', ->
      d = Date.new 2000, 01, 01
      d = d + 10
      assert.equal '2000-01-11', tostring(d)
      d = d + 21
      assert.equal '2000-02-01', tostring(d)

    it 'has a meta method sub which subtracts days', ->
      d = Date.new 2000, 01, 01
      d = d - 10
      assert.equal '1999-12-22', tostring(d)
      d = d - 22
      assert.equal '1999-11-30', tostring(d)

    it 'can be created from a string', ->
      d = Date\from_string '2000-01-01'
      assert.equal 2000, d.year
      assert.equal 1, d.month
      assert.equal 1, d.day
  
  describe 'Person', ->
    local person, expected_age

    before_each ->
      person = Person.new 'John', 'Eriksson', '1978-01-05'
      d = person.attributes.birthdate
      today = os.date('*t')
      expected_age = today.year - d.year
      if today.month < d.month
        expected_age -= 1
      else if today.month == d.month
        if today.day < d.day
          expected_age -= 1

    it 'has a name getter, concatenating firstname and lastname', ->
      assert.equal 'John Eriksson', person.name

    it 'has an age getter, delegating to the internal date', ->
      assert.equal expected_age, person.age

    it 'has a birthdate getter, delegating to the internal date', ->
      assert.equal '1978-01-05', person.birthdate

    it 'has a firstname getter, delegating to the internal attributes table', ->
      assert.equal 'John', person.firstname

    it 'has a firstname setter, delegating to the internal attributes table', ->
      person.firstname = 'Axel'
      assert.equal 'Axel', person.firstname
      assert.equal 'Axel Eriksson', person.name

    it 'has a class method find', ->
      bob = Person\find('John')[1]
      assert.equal 'Bob Johnsson', bob.name
