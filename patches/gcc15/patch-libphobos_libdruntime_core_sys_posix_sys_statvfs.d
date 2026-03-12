$NetBSD$

Add pragma(mangle) for NetBSD renamed symbols.
NetBSD renamed these functions during ABI transitions;
without pragma(mangle), D bindings link against compat stubs.

--- libphobos/libdruntime/core/sys/posix/sys/statvfs.d.orig	2026-03-10 18:01:58.071178458 -0500
+++ libphobos/libdruntime/core/sys/posix/sys/statvfs.d	2026-03-10 18:03:46.063206915 -0500
@@ -180,7 +180,9 @@
         ST_NOSUID = 2
     }
 
+    pragma(mangle, "__statvfs90")
     int statvfs (const char * file, statvfs_t* buf);
+    pragma(mangle, "__fstatvfs90")
     int fstatvfs (int fildes, statvfs_t *buf) @trusted;
 }
 else version (OpenBSD)
