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

Because MoonScript's built-in class implementation makes it difficult to use metamethods. It's also a bit verbose in it's compiled lua output. Also because it's fun.

## Usage

See spec/classy_spec.moon for more examples.

```moonscript
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


p = Person.new 'John', 'Eriksson', '1978-08-19'
print p.firstname -- prints the firstname in the @attributes table
print p.age -- prints the calculated age
print p.birthdate -- print the birthdate
p.age = 37 -- changes the birthdate
print p.age -- prints 37
print p.birthdate -- prints the new birthdate
print p.name -- prints the name by concatenating firstname and lastname

bob = Person\find('john')[1] -- static method, finds Bob (his lastname is Johnsson)
print bob.name -- prints Bob Johnsson"
print bob.age -- prints the calculated age
```

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
