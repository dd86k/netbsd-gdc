$NetBSD$

Add pragma(mangle) for NetBSD renamed symbols.
NetBSD renamed these functions during ABI transitions;
without pragma(mangle), D bindings link against compat stubs.

--- libphobos/libdruntime/core/sys/posix/stdc/time.d.orig	2026-03-10 18:01:58.071927855 -0500
+++ libphobos/libdruntime/core/sys/posix/stdc/time.d	2026-03-10 18:03:46.067187797 -0500
@@ -139,6 +139,7 @@
 else version (NetBSD)
 {
     ///
+    pragma(mangle, "__tzset50")
     void tzset();                            // non-standard
     ///
     extern __gshared const(char)*[2] tzname; // non-standard
