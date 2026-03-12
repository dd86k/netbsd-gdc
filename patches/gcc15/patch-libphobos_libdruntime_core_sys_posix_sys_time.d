$NetBSD$

Add pragma(mangle) for NetBSD renamed symbols.
NetBSD renamed these functions during ABI transitions;
without pragma(mangle), D bindings link against compat stubs.

--- libphobos/libdruntime/core/sys/posix/sys/time.d.orig	2026-03-10 18:01:58.070266611 -0500
+++ libphobos/libdruntime/core/sys/posix/sys/time.d	2026-03-10 18:03:46.058557162 -0500
@@ -160,9 +160,13 @@
         timeval it_value;
     }
 
+    pragma(mangle, "__getitimer50")
     int getitimer(int, itimerval*);
+    pragma(mangle, "__gettimeofday50")
     int gettimeofday(timeval*, void*); // timezone_t* is normally void*
+    pragma(mangle, "__setitimer50")
     int setitimer(int, const scope itimerval*, itimerval*);
+    pragma(mangle, "__utimes50")
     int utimes(const scope char*, ref const(timeval)[2]);
 }
 else version (OpenBSD)
