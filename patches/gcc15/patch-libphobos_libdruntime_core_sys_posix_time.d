$NetBSD$

Add pragma(mangle) for NetBSD renamed symbols.
NetBSD renamed these functions during ABI transitions;
without pragma(mangle), D bindings link against compat stubs.

--- libphobos/libdruntime/core/sys/posix/time.d.orig	2026-03-10 18:01:58.069437664 -0500
+++ libphobos/libdruntime/core/sys/posix/time.d	2026-03-10 18:03:08.178571996 -0500
@@ -63,6 +63,7 @@
 }
 else version (NetBSD)
 {
+    pragma(mangle, "__timegm50")
     time_t timegm(tm*); // non-standard
 }
 else version (OpenBSD)
@@ -373,14 +374,20 @@
     alias int clockid_t; // <sys/_types.h>
     alias int timer_t;
 
+    pragma(mangle, "__clock_getres50")
     int clock_getres(clockid_t, timespec*);
+    pragma(mangle, "__clock_gettime50")
     int clock_gettime(clockid_t, timespec*);
+    pragma(mangle, "__clock_settime50")
     int clock_settime(clockid_t, const scope timespec*);
+    pragma(mangle, "__nanosleep50")
     int nanosleep(const scope timespec*, timespec*);
     int timer_create(clockid_t, sigevent*, timer_t*);
     int timer_delete(timer_t);
+    pragma(mangle, "__timer_gettime50")
     int timer_gettime(timer_t, itimerspec*);
     int timer_getoverrun(timer_t);
+    pragma(mangle, "__timer_settime50")
     int timer_settime(timer_t, int, const scope itimerspec*, itimerspec*);
 }
 else version (OpenBSD)
@@ -568,8 +575,11 @@
 else version (NetBSD)
 {
     char* asctime_r(const scope tm*, char*);
+    pragma(mangle, "__ctime_r50")
     char* ctime_r(const scope time_t*, char*);
+    pragma(mangle, "__gmtime_r50")
     tm*   gmtime_r(const scope time_t*, tm*);
+    pragma(mangle, "__localtime_r50")
     tm*   localtime_r(const scope time_t*, tm*);
 }
 else version (OpenBSD)
