[![CircleCI](https://circleci.com/gh/johnae/classy.svg?style=svg)](https://circleci.com/gh/johnae/classy)

# Classy

https://github.com/johnae/classy

## Description
Classy is a class implementation for [MoonScript](https://github.com/leafo/moonscript) (and [Lua](http://www.lua.org)). It is mainly for MoonScript however since that allows a certain syntax which looks pretty good i.m.o. I haven't used it from Lua but I expect the syntax to become more verbose and definitely uglier.

## Lua compatibility

I know this works with LuaJIT 2.x+. It should work with other Lua implementations too - but I haven't tried. The CircleCI tests run on LuaJIT. Please test and help out if you feel like it.

## Performance

I haven't done any extensive performance tests but it seems to be slightly faster than MoonScript's built-in class implementation. Haven't compared to other implementations of which there are many.

## Why

Because MoonScript's built-in class implementation makes it difficult to use metamethods. It's also a bit verbose in it's compiled lua output. And, of course, because it's fun.

## Usage

See [spec/classy_spec.moon](spec/classy_spec.moon) and [spec/smoke_test_spec.moon](spec/smoke_test_spec.moon) for more examples.

```moonscript
define = require'classy'.define -- call the local whatever you like, I like 'define'
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

-- subclass of Person
Employee = define 'Employee', ->
  parent Person
  static
    from_person: (p, salary) =>
      {:firstname, :lastname, :birthdate} = p.attributes
      birthdate = tostring(birthdate)
      @.new :firstname, :lastname, :birthdate, :salary
  instance
    initialize: (opts={}) =>
      {:firstname, :lastname, :birthdate} = opts
      super @, firstname, lastname, birthdate
      @salary = opts.salary

d = Date.new 1978, 1, 5
print tostring(d) -- prints '1978-01-05'
new_year_1977 = d - 5
print tostring(new_year_1977) -- prints '1977-12-31'

p = Person.new 'John', 'Eriksson', '1978-01-05'
print p.firstname -- prints the firstname in the @attributes table
print p.age -- prints the calculated age
print p.birthdate -- print the birthdate
p.age = 37 -- changes the birthdate
print p.age -- prints 37
print p.birthdate -- prints the new birthdate
print p.name -- prints the name by concatenating firstname and lastname

bob = Person\find('john')[1] -- static method, finds Bob (his lastname is Johnsson)
print bob.name -- prints "Bob Johnsson"
print bob.age -- prints the calculated age

employee = Employee\from_person bob, 1000000
print employee.name -- prints "Bob Johnsson"
print employee.age -- prints calculated age
print employee.salary -- prints 1000000

-- some_table == some_table is true in lua, some_table == some_other_table is false in lua
print employee == employee -- prints true

cloned_employee = employee\dup!
print cloned_employee.name -- prints "Bob Johnsson"
print cloned_employee.age -- prints calculated age
print cloned_employee.salary -- prints 1000000
print cloned_employee == employee -- prints false
cloned_employee.salary = 100
print cloned_employee.salary -- prints 100
print employee.salary -- prints 1000000
```

Above demonstrates some of what this library can do. There is more, like missing_property for example. See [spec/classy_spec.moon](spec/classy_spec.moon).

## Development

Running the tests requires busted https://github.com/Olivine-Labs/busted and luassert https://github.com/Olivine-Labs/luassert.
Since luassert comes with busted, only busted needs to be installed really. It also requires that moonscript is installed.

On Ubuntu you might go about it like this:

```shell
sudo apt-get install luarocks luajit
sudo luarocks install busted
sudo luarocks install moonscript
```

To run the specs, run `busted spec`.


## Contributing

I appreciate all feedback and help. If there's a problem, create an issue or pull request. Thanks!
