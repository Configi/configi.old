# About Modules

---

Configi modules are simply Lua modules which return a table. It was decided to call them a *module* too since they are essentially the same as Lua modules. The module terminology is also very common and easily understood in the software industry.


Here is an example module to demonstrate the parts:

    local Lua = {}
    local Func = {}
    local Configi = require"configi"
    local Lc = require"cimicida"
    local Px = require"px"
    local Cmd = Px.cmd
    local example = {}
    local ENV = {}
    _ENV = ENV

    local main = function (S, M, G)
      local C = Configi.start(S, M, G)
      C.required = { "what" }
      C.alias.task = { "work" }
      return Configi.finish(C)
    end

    Func.done = function ()
    end

    function example.present (S)
      local M = { "task" }
      local G = {
   	repaired = "example.present: Ok",
        kept = "example.present: Skipped",
        failed = "example.presnet: Error"
      }
      local F, P, R = main(S, M, G)
      if Func.done() then
        return F.kept(P.task)
      end
      return F.result(P.task, F.run(Cmd.something{ action = P.task }))
    end

    example.done = example.present
    return example

### Anatomy of a module
___
__Header and loaded Lua modules__

    local Lua = {}
    local Func = {}
    local Configi = require"configi"
    local Lc = require"cimicida"
    local Px = require"px"
    local Cmd = Px.cmd
    local example = {}
    local ENV = {}
    _ENV = ENV

The Lua table is used to localize core Lua functions. For example, if we want to localize table.insert and call it as Lua.insert inside the module:

    local Lua = {
      insert = table.insert
    }

The Func table is used to contain functions local to the module (except for `main`). You can see it in practice in the above module when Func.done was assigned a function.

___
__Required Modules__

The rest of the header specifies the Lua modules that are required. If you look at the example above or at the existing Configi modules you will notice that the following Lua modules are usually *required*.

  Module       | Description
:--------------|-------------------------------------------------------------------------------
__configi__    | The core Lua module of Configi. It is the **only** required Lua module.
__cimicida__   | The official standard library / utility belt / batteries of Configi.
__px__         | Mostly extensions to the luaposix module and functions used for system operations.

Feel free to submit patches to extend these modules.

___
__Initialization__

    local main = function (S, M, G)
      local C = Configi.start(S, M, G)
      C.required = { "what" }
      C.alias.task = { "work" }
      return Configi.finish(C)
    end

The local function `main` is called by each module function to initialize the tables and values required to execute a call to a script function. For more information on the `S`,`M`,`G` arguments see the following section about functions.

The `required` key of the table returned by `Configi.start` is a table that list the required parameter(s) by *all* functions of the module. `alias` is for specifying aliases to the required or valid parameters.

The `main` function returns a table (C) that contains the functions (F), parameters (P) and results (R) table that are used inside the module functions.

Local or internal functions can be declared before or after `main`.

___
__Functions__

    function example.present (S)
      local M = { "task" }
      local G = {
        repaired = "example.present: Ok",
        kept = "example.present: Skipped",
        failed = "example.presnet: Error"
      }
      local F, P, R = main(S, M, G)
      if Func.done() then
        return F.kept(P.task)
      end
      return F.result(P.task, F.run(Cmd.something, { action = P.task }))
    end

Functions does the actual execution of commands or call operations that change the state of a host. The structure of a function follows the `skip or execute or fail` pattern.

When naming the function, keep in mind that you are going to describe the state of a promise.

The `S` argument to the function is the string of parameter-arguments. They are written as `parameter "argument"` in policies. The `main` functions passes this string to load() for evaluation.

The `M` table is a string array of valid parameters that the function can take.

`G` is the table of strings used for messages, debugging and logging. G.repaired is used for successful operations, G.failed for failures or errors, G.kept for no-change or no-action conditions.

`S`, `M` and `G` are passed to the `main` function which returns: `F` a table that contains Configi functions, `P` a table that contains the parameter-arguments, `R` a table that is used to store results

Configi has support for handlers. The argument to the `notify_kept` parameter is called when a function is skipped. The argument to `notify` when the function succeeds with the prescribed operation. The argument to `notify_failed` when the operation fails.

Some modules require you to micromanage operations, messages and results. Here's an equivalent of the function above:

    function example.present (S)
      local M = { "task" }
      local G = {
	repaired = "example.present: Ok",
        kept = "example.present: Skipped",
        failed = "example.presnet: Error"
      }
      local F, P, R = main(S, M, G)
      if Func.done() then
        F.msg(P.task, G.kept, nil)
        R.notify_kept = P.notify_kept
        return R
      end
      if F.run(Cmd.something, { action = P.task }) then
        F.msg(P.task, G.repaired, true)
        R.notify = P.notify
        R.changed = true
      else
        R.notify_failed = P.notify_failed
        R.failed = true
      end
      return R
    end

___
__Footer__

    example.done = example.present
    return example

This is where function aliases are declared and the table return statement of a Lua module.

### Notes

* The list of reserved parameters:
    1. comment
    1. debug
    1. test
    1. syslog
    1. log
    1. handle
    1. register
    1. context
    1. notify
    1. notify_failed
    1. notify_kept

* It is the module's responsibility to determine whether anything needs to be done. An operation that modifies the system state should be convergent.

* Modules are auto-loaded based on the name of the called module function. For example in a script containing the following snippet, module `example` is auto-loaded.

    example.present [[
      task "yes"
    ]]

* When writing modules run it through the excellent linting tool, Luacheck <https://github.com/mpeterv/luacheck/>.

* Remember that a configuration management software's real strength comes from the quality of its modules.

### Documentation

Module and function documentation is generated using [LDoc](https://github.com/stevedonovan/LDoc). See the existing modules for examples.
