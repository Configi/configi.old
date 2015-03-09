# Configi

A minimalistic infrastructure automation and configuration management software. It is MIT licensed (including the core modules).

Configi can manage several aspects of system configuration, security and maintenance. Note that this well depend on the availability of Configi modules for your requirement.

For now Configi is Linux only. There are no plans to support Windows. *BSD support possibly in the future.

See [Wikipedia](http://en.wikipedia.org/wiki/Configuration_management) for more information on the topic of configuration management.

---

#### Why?

There are several configuration management software in existence but I find most are bloated both in resource usage and features. The others in the minimalist camp also fall short due to complicated module or extension writing. The latter are usually not far off from shell script wrappers.

Configi was inspired by CFEngine 3, Chef and Ansible. You may see some similarities with these configuration management software in Configi. Especially CFEngine 3, where we borrowed the concepts introduced by the Promise Theory and Computer Immunology.

Visit M. Burgess' [page](http://markburgess.org/sysadmin.html) for essays, articles and papers regarding Promise Theory and system administration. I do not claim full compliance to the theory so Configi should not be considered a complete replacement for CFEngine 3.

In my opinion Lua is the best configuration language. It's language features also lend to a concise core and module code. In the same spirit as Lua, the Configi core is very small.

Choosing the right tool is not a rational matter. If the design decisions outlined below aligns with your requirements then give Configi a try.

---

#### Design decisions

* **Compiled-in modules and policy**

Configi modules are compiled-in so you can choose the module apt for you policy or host. The Configi executable (cfg) with all modules (as of 0.9.0) compiled-in is less than 300KiB. You can also have your policy built-in during compilation of the executable.

* **Pull or push model**

The ideal system would be a pull-based system but if needed Configi can also emulate a push-based system.

* **Do not enforce a pure declarative policy**

Configi policies can be written as mixed declarative and imperative. As much as possible it is desired to write policies to be declarative but policy authors can take advantage of the imperative features of Lua.

* **No packaging required**

You can just copy the Configi (cfg) executable to a host and have it configuring the host in no time.

* **No parallel execution**

This requires adding features that complicates and bloats the runtime.

* **Minimal resource usage**

By avoiding parallel execution and being built in Lua we are guaranteeing very little resources required.

* **Deterministic ordering**

By avoiding parallel execution policies are evaluated from top to bottom.

* **Depend on existing host tooling**

As much as possible Configi makes use of host tools (e.g coreutils, busybox, native package manager, native process manager). If bypassing host tooling is required or there is none available, Configi modules has the capability to drop down to Lua and/or C for operations.

* **The only reporting mechanism is through Syslog**

To be light as possible, it makes sense to support the most widespread reporting facility. If you need to monitor or gather reports from all your hosts you will need to set up consolidated remote syslogging and automated reporting.

* **No operation should change the state of an external host**

We see more and more configuration management frameworks adding features such as cloud provisioning. I believe this goes against the principles introduced by Promise Theory.

---

#### Example policy

    file.directory [[
      comment "Create directory if running on Gentoo"
      context "fact.osfamily.gentoo"
      path "/tmp/dir"
      mode "0700"
      notify "touch"
    ]]

    yum.present [[
      context "fact.osfamily.centos"
      package "mtr"
    ]]

    file.absent [[
      path "/tmp/dir"
      notify "touch"
    ]]

    file.touch [[
      comment "Handle 'touch' notifications. This is only executed once."
      handle "touch"
      path "/tmp/dir"
    ]]

---

#### Mailing list

Join the mailing list if you need help or have Configi module requests. Bug reports and patches are also very much welcome.

To join, send an email to configi-request@freelists.org with 'subscribe' in the Subject field OR by
visiting the list page at [Freelists/Configi](http://www.freelists.org/list/configi).



