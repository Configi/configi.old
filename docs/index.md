# Configi

A minimalistic infrastructure automation and configuration management software. It is MIT licensed (including the core modules).

Configi can manage several aspects of system configuration and maintenance. Note that this well depend on the availability of Configi modules for your requirement.

For now Configi is Linux only. There are no plans to support Windows. *BSD support possibly in the future.

See [Wikipedia](http://en.wikipedia.org/wiki/Configuration_management) for more information on the topic of configuration management.

---

#### Why?

There are numerous configuration management software in existence but I find most are bloated both in resource usage and features. The others in the minimalist camp also fall short due to complicated module or extension writing. They are usually not far off from shell script wrappers.

Configi was inspired by CFEngine 3, Chef and Ansible. You may see some similarities with these configuration management software in Configi. Especially CFEngine 3, where we borrowed the concepts introduced by the Promise Theory. Visit M. Burgess' [page](http://markburgess.org/sysadmin.html) for essays, articles and papers regarding Promise Theory and system administration.

In my opinion Lua is the ultimate configuration language. It's language features also lend to a concise core and module code. In the same spirit as Lua, the Configi core is very small. I guess this what happens when a system administrator discovers the elegance of Lua.

Choosing the right tool is not a rational matter. If the design decisions outlined below aligns with your requirements then give Configi a try.

---

#### Design decisions

* **Compiled-in modules**

Configi modules are compiled-in so you can choose the module apt for you policy or host. The Configi executable (cfg) with all modules (as of 0.9.0) compiled-in is less than 300KiB.

* **Pull or push system**

The ideal system would be a pull-based system but if needed Configi can also do push-based. In the future we may add a built-in feature that supports a pull-based system.

* **Do not enforce a pure declarative policy**

Configi policies can be written as mixed declarative and imperative. As much as possible it is desired to write policies to be declarative but policy authors can take advantage of the imperative features of Lua.

* **No packaging required**

You can just copy the Configi (cfg) binary and a Configi policy to a host and have it configuring the host in no time.

* **No parallel execution**

This requires adding features that complicates and bloats the runtime.

* **Minimal resource usage**

By avoiding parallel execution and being built in Lua we are guaranteeing very little resources required.

* **Sequential**

By avoiding parallel execution policies are evaluated from top to bottom.

* **Depend on existing host tooling**

As much as possible Configi makes use of host tools (e.g coreutils, busybox, native package manager, native process manager). If bypassing host tooling is required or there is none available, Configi modules has the capability to drop down to Lua and/or C for operations.

* **The only reporting mechanism is through Syslog**

To be light as possible, it makes sense to support the most widespread reporting facility. If you need to monitor or gather reports from all your hosts you will need to set up consolidated remote syslogging and automated reporting.

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



