# Policy Functions

These functions are available for all policies.

---

#### ipairs(t)

Same as Lua ipairs(). From the Lua Reference Manual:

Returns three values: an iterator function, the table t, and 0, so that the construction

    for i,v in ipairs(t) do body end

will iterate over the pairs (1,t[1]), (2,t[2]), ..., up to the first integer key absent from the table.

---

#### pairs(t)

Same as Lua pairs(). From the Lua Reference Manual:

Returns three values: the next function, the table t, and nil, so that the construction

     for k,v in pairs(t) do body end

will iterate over all key–value pairs of table t.

---

#### list(t)

Given a table `t`, iterate over this table and return a line terminated `field "value"` pair.

For instance the following snippet

    d = {
      { comment = "one", path = "tmp/one" },
      { comment = "two", path = "tmp/two" }
    }

    for dirs in list(d) do
      file.absent(dirs)
    end

is equivalent to

    file.absent[[
      comment "one"
      path "tmp/one"
    ]]

    file.absent[[
      comment "two"
      path "tmp/two"
    ]]

---

#### sub(s, t)

Simple string interpolation.

Given a table `t`, interpolate the string `s` by replacing corresponding field names with the respective value.

    tbl = { "field" = "value" }
    str = [[ this is the {{ field }} ]]

If passed with these arguments, a new string is returned as

    'this is the value'

---

#### format(s, ...)

Same as Lua string.format(). From the Lua Reference Manual:

Returns a formatted version of its variable number of arguments following the description given in its first argument (which must be a string). The format string follows the same rules as the ANSI C function sprintf. The only differences are that the options/modifiers *, h, L, l, n, and p are not supported and that there is an extra option, q. The q option formats a string between double quotes, using escape sequences when necessary to ensure that it can safely be read back by the Lua interpreter. For instance, the call

    string.format('%q', 'a string with "quotes" and \n new line')

may produce the string:

    "a string with \"quotes\" and \
      new line"

Options A and a (when available), E, e, f, G, and g all expect a number as argument. Options c, d, i, o, u, X, and x also expect a number, but the range of that number may be limited by the underlying C implementation. For options o, u, X, and x, the number cannot be negative. Option q expects a string; option s expects a string without embedded zeros. If the argument to option s is not a string, it is converted to one following the same rules of tostring.

---

#### debug(s)

Turn on debugging if passed any of the strings `yes`, `Yes`, `true,` or `True`.

---

#### test(s)

Turn on dry-run mode if passed any of the strings `yes`, `Yes`, `true`, or `True`.

---

#### syslog(s)

Turn on syslogging if passed any of the strings `yes`, `Yes`, `true`, or `True`.


---

#### log(s)

Turn on logging to a file.

The string `s` is the path to a file.

---

#### include(s)

Include another Configi policy. The string `s` is the path to a file.

Included policies are stacked, for example the following policy inserts the contents of `test1.lua` then `test2.lua` at the top.

    include "test1.lua"
    include "test2.lua"
    file.touch [[ path "/etc/passwd" ]]

---

### each(t, f)

Run a function `f` against each item from table `t`.

The following:

    t = {
      { path = "test.xxx", comment = "test" },
      { path = "test.yyy", comment = "test" }
    }

    each(t, file.absent)

is equivalent to

    file.absent[[
      comment "test"
      path "test.xxx"
    ]]

    file.absent[[
      comment "test"
      path "test.yyy"
    ]]

