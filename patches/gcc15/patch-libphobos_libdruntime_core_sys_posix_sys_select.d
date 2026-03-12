$NetBSD$

Add pragma(mangle) for NetBSD renamed symbols.
NetBSD renamed these functions during ABI transitions;
without pragma(mangle), D bindings link against compat stubs.

--- libphobos/libdruntime/core/sys/posix/sys/select.d.orig	2026-03-10 18:01:58.072712732 -0500
+++ libphobos/libdruntime/core/sys/posix/sys/select.d	2026-03-10 18:03:46.070844617 -0500
@@ -268,7 +268,9 @@
             _p.fds_bits[--_n] = 0;
     }
 
+    pragma(mangle, "__pselect50")
     int pselect(int, fd_set*, fd_set*, fd_set*, const scope timespec*, const scope sigset_t*);
+    pragma(mangle, "__select50")
     int select(int, fd_set*, fd_set*, fd_set*, timeval*);
 }
 else version (OpenBSD)
