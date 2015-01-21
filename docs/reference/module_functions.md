# Module Functions

This functions are available for modules.

They are usually returned by the `F` table as returned by `main()`. So `msg()` is `F.msg()`

---

#### msg(s, s, b)

Given a string as the first argument, it becomes the `item` field in the Configi messages. A string as second argument becomes the primary message for the operation as shown in the Configi messages and syslog. The boolean third argument indicates the operation status.

 Boolean | Status
 --------|--------
 true    | success
 false   | fail
 nil     | skip

---

#### run(f, a)

Wraps the function(argument) and modifies the execution depending on the status of the debug (-v) and/or test (-t) flags.

When debug is on, it add timing information for each operation. If test is on, operations are a noop.

---

#### xrun(f, a)

Same as `run` but always assumes that debug is on.

---

#### open(u)

Wraps `Cimicida.fopen` so the open operation is relative to the path of the policy location.

---

#### skip(s)

Usually used when returning from a module function eg. `return F.skip(s)`. Enables handling of the `notify_kept` parameter and returns the result as if the promise is kept.

---

#### result(b, s)

Usually used when returning from a module function eg. `return F.result(b, s)`. Depending on the boolean return value of the first argument. If `true` then it enables the handling of the `notify` parameter and returns the result as if the promise was repaired. If `false` then it enables the handling of the `notify_failed` parameter and returns the result as if the promise failed.
