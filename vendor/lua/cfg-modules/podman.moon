-- Author: Eduardo Tongson <propolice@gmail.com>
-- License: MIT <http://opensource.org/licenses/MIT>
tostring = tostring
C = require "configi"
P = {}
{:exec, :table} = require "lib"
export _ENV = nil
----
--  ### podman.image
--
--  Ensure that a container image is pulled locally.
--  Does not update the existing local image.
--
--  #### Arguments:
--      #1 (string) = The url of the image.
--
--  #### Results:
--      Pass     = Image already pulled.
--      Repaired = Successfully pulled image.
--      Fail     = Failed to pull the image.
--
--  #### Examples:
--  ```
--  podman.image("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
--  ```
----
image = (i) ->
    C["podman.image :: #{i}"] = ->
        return C.fail "podman(1) executable not found." unless exec.path "podman"
        return C.pass! if exec.popen "podman history #{i}"
        C.equal(0, exec.popen("podman pull #{i}"), "Unable to pull container image (#{i}).")
----
--  ### podman.update(string)
--
--  Ensure that a container image is up-to-date.
--
--  #### Arguments:
--      #1 (string) = The url of the image.
--
--  #### Results:
--      Pass     = Image up-to-date.
--      Repaired = Successfully updated image.
--      Fail     = Failed to update the image.
--
--  #### Examples:
--  ```
--  podman.update("docker.elastic.co/elasticsearch/elasticsearch:6.3.0")
--  ```
----
update = (i) ->
    C["podman.update :: #{i}"] = ->
        return C.fail "podman(1) executable not found." unless exec.path "podman"
        r, t = exec.popen "podman pull #{i}"
        return C.pass! if not table.find(t.output, "Copying blob", true) and 0 == r
        C.equal(0, r, "Failed to update container image. podman(1) retured '#{t.code}'.")
P["image"] = image
P["pull"] = image
P["update"] = update
P
