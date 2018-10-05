C = require"configi"
S = {}
tostring = tostring
{:gsub} = string
{:file} = require"lib"
export _ENV = nil
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- sysctl.write
--
-- Kernel paramater modification through sysctl as implemented in procfs.d
-- Write value to a sysctl key.
--
-- Arguments:
--     (string) = The key to write to
--
-- Parameters:
--     (table)
--         value = Value to write to the sysctl key
--
-- Results:
--     Pass     = Value already set.
--     Repaired = Successfully wrote value.
--     Fail     = Failed to set value.
--
-- Examples:
--     sysctl.write("vm.swappiness"){
--        value = 0
--     }
write = (key) ->
    return (p) ->
        value = tostring p.value
        C["sysctl.write :: #{key} = #{value}"] = ->
            return C.fail "Required parameter key 'value' missing." unless p.value
            k = "/proc/sys/" .. gsub(key, "%.", "/")
            v = tostring value
            return C.fail "Sysctl key (#{k}) not found." unless file.stat(k)
            if v == file.read_line k
                return C.pass!
            else
                return C.is_true file.write_all(k, v)
S["write"] = write
S
