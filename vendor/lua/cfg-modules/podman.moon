C = require "configi"
P = {}
{:exec, :table} = require "lib"
export _ENV = nil
-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
--
-- podman.image
--
-- Ensure that a container image is pulled locally.
-- Does not update the existing local image.
--
-- Arguments:
--     #1 (string) = The url of the image.
--
-- Results:
--     Pass     = Image already pulled.
--     Repaired = Successfully pulled image.
--     Fail     = Failed to pull the image.
--
-- Examples:
--     podman.image("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
image = (i) ->
    C["podman.image :: #{i}"] = ->
        return C.fail "podman(1) executable not found." unless exec.path "podman"
        unless nil == exec.popen "podman history #{i}"
            return C.pass!
        else
            return C.equal(0, exec.popen("podman pull #{i}"), "Unable to pull container image (#{i}).")
-- podman.update(string)
--
-- Ensure that a container image is up-to-date.
--
-- Arguments:
--     #1 (string) = The url of the image.
--
-- Results:
--     Pass     = Image up-to-date.
--     Repaired = Successfully updated image.
--     Fail     = Failed to update the image.
--
-- Examples:
--     podman.update("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
update = (i) ->
    C["podman.update :: #{i}"] = ->
        return C.fail "podman(1) executable not found." unless exec.path "podman"
        r, t = exec.popen "podman pull #{i}"
        return C.fail "Failed to update container image. podman(1) returned '#{t.code}'." unless r
        if nil == table.find(t.output, "Copying blob", true)
            return C.pass!
        else
            return C.equal(0, r)
P["image"] = image
P["pull"] = image
P["update"] = update
P
