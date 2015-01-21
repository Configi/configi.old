
#### Policy

  A specification of a hosts desired state. Technically Configi policies are executable Lua scripts.

####Promise

  The building blocks of policies. A promised describes the state of a specific aspect of a host.

#### Operation

  An operation is a unit of execution that may comprise a promise. There can be several operations to satisfy a promise.

  For example calling `mkdir` from a Configi module function is an operation.

#### Module

  Configi modules are simply Lua modules that provides the functions required to deliver a promise.
