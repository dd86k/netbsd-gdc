$NetBSD$

Add pragma(mangle) for NetBSD renamed symbols in core.stdc.time.
NetBSD renamed the 64-bit time_t entry points with a 50 suffix during the
2008 ABI transition; <time.h> __RENAME()s to them and keeps the unsuffixed
symbols as 32-bit time_t compat stubs. Without these mangles, D code that
imports core.stdc.time binds to the compat stubs and misreads time_t.

Note localtime maps to __locatime50, not __localtime50 -- that missing l is
NetBSD's own spelling, see /usr/include/time.h.

--- libphobos/libdruntime/core/stdc/time.d.orig	2026-10-04 14:21:44.366656096 -0400
+++ libphobos/libdruntime/core/stdc/time.d	2026-10-04 14:21:44.371778814 -0400
@@ -24,31 +24,42 @@
 
 import core.stdc.config;
 
+// NetBSD's <time.h> __RENAME()s these to '50'-suffixed 64-bit time_t entry
+// points; the unsuffixed symbols are 32-bit time_t compat stubs, so binding
+// to them silently misinterprets the value.
+private template timeMangle(string name, string muslName, string netbsdName)
+{
+    version (NetBSD)
+        enum timeMangle = netbsdName;
+    else
+        enum timeMangle = muslRedirTime64Mangle!(name, muslName);
+}
+
 extern (C):
 @trusted: // There are only a few functions here that use unsafe C strings.
 nothrow:
 @nogc:
 
 ///
-pragma(mangle, muslRedirTime64Mangle!("difftime", "__difftime64"))
+pragma(mangle, timeMangle!("difftime", "__difftime64", "__difftime50"))
 pure double  difftime(time_t time1, time_t time0); // MT-Safe
 ///
-pragma(mangle, muslRedirTime64Mangle!("mktime", "__mktime64"))
+pragma(mangle, timeMangle!("mktime", "__mktime64", "__mktime50"))
 @system time_t  mktime(scope tm* timeptr); // @system: MT-Safe env locale
 ///
-pragma(mangle, muslRedirTime64Mangle!("time", "__time64"))
+pragma(mangle, timeMangle!("time", "__time64", "__time50"))
 time_t  time(scope time_t* timer);
 
 ///
 @system char*   asctime(const scope tm* timeptr); // @system: MT-Unsafe race:asctime locale
 ///
-pragma(mangle, muslRedirTime64Mangle!("ctime", "__ctime64"))
+pragma(mangle, timeMangle!("ctime", "__ctime64", "__ctime50"))
 @system char*   ctime(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf race:asctime env locale
 ///
-pragma(mangle, muslRedirTime64Mangle!("gmtime", "__gmtime64"))
+pragma(mangle, timeMangle!("gmtime", "__gmtime64", "__gmtime50"))
 @system tm*     gmtime(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf env locale
 ///
-pragma(mangle, muslRedirTime64Mangle!("localtime", "__localtime64"))
+pragma(mangle, timeMangle!("localtime", "__localtime64", "__locatime50")) // sic: NetBSD's own spelling
 @system tm*     localtime(const scope time_t* timer); // @system: MT-Unsafe race:tmbuf env locale
 ///
 @system size_t  strftime(scope char* s, size_t maxsize, const scope char* format, const scope tm* timeptr); // @system: MT-Safe env locale
