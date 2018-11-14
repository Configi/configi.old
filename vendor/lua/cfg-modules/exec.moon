-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
C = require"configi"
E = {}
{:exec, :string} = require"lib"
table, require, type, io, tostring, pcall = table, require, type, io, tostring, pcall
stat = require"posix.sys.stat"
export _ENV = nil
----
--  #### exec.spawn
--
--  Run executable and arguments through posix_spawn(3).
--  A path can be checked before running the executable.
--
--  #### Arguments:
--      (string) = Complete path of executable.
--
--  #### Parameters:
--      (table)
--          args    = Arguments as a space delimited string.
--          expects = A precondition. Path MUST NOT exist before running the executable.
--
--  #### Results:
--      Repaired = Successfully executed.
--      Fail     = Error encountered when running executable+arguments.
--      Pass     = The specified path of file passed in the `expects` parameter already exists.
--
--  #### Examples:
--  ```
--      exec.spawn("/bin/touch"){
--        args = "/tmp/touch",
--        expects = "/tmp/touch"
--      }
--  ```
----
spawn = (exe) ->
    return (p) ->
        path = p.expects
        args = p.args
        C["exec.spawn :: #{exe}"] = ->
            return C.pass! if path and stat.stat path
            command = string.to_table args
            command.exe = exe
            C.equal(0, exec.qexec(command), "Failure executing command.")
----
--  ### exec.script
--
--  Runs a shell script through popen(3).
--  The script is passed to /bin/sh using the -c flag; interpretation, if any, is performed by the shell.
--
--  As a precondition, a path can be checked before running the script.
--
--  The Lua module should return the body of the script. Example:
--  ```
--     $ cat src/lua/scripts/script.lua
--     return [==[
--     echo "test"
--     touch "./file"
--     ]==]
--  ```
--  In the above example, the basename of the filename 'script' is the argument to exec.script()
--
--  #### Arguments:
--      (string) = Name of shell script sourced from `src/lua/scripts`
--
--  #### Parameters:
--      (table)
--          expects = A precondition. Path MUST NOT exist before running the executable (string)
--           ignore = if set to `true`, always run the script, the shell script's return result is ignored (boolean)
--           output = if set to `true`, show the popen(3) output (boolean)
--         register = Set this variable name to the output of the script (string)
--
--  #### Results:
--      Repaired = Successfully executed.
--      Fail     = Error encountered when running script.
--      Pass     = The specified path of file passed in the `expects` parameter already exists. Or the popen(3) result is ignored.
--
--  #### Examples:
--  ```
--     exec.script("script"){
--       expects = "/tmp/touch",
--       output = true,
--       ignore = true
--     }
--  ```
----
script = (str) ->
    popen = (s, i) ->
        r = {}
        r.exe = "io.popen"
        pipe = io.popen(s, "r")
        pipe\flush!
        r.output = [ln for ln in pipe\lines!]
        _, _, code = pipe\close!
        r.code = code
        if 0 == code or i
            return code, r
        else
            return nil, r
    return (p) ->
        C["exec.script :: #{str}"] = ->
            r, s = pcall(require, "scripts.#{str}")
            return C.fail "Script '#{str}' not found." if false == r
            local code, ret, expects, output, ignore
            {:register, :expects, :output, :ignore} = p if type(p) == table
            return C.pass! if expects and stat.stat expects
            if true == ignore
                code, ret = popen(s, true)
                -- Always succeed
                C.print("Script returned '#{code}'.")
                C.print(table.concat(ret.output, "\n")) if true == output
                C.equal(code, code)
                C.register(register, ret.output)
            else
                code, ret = popen(s)
                C.print(table.concat(ret.output, "\n")) if true == output and 0 == code
                C.equal(0, code, "Execution failure. Script returned non-zero code (#{code}).")
                C.register(register, ret.output)
E["spawn"] = spawn
E["simple"] = spawn
E["script"] = script
E
