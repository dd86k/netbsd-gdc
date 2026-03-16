$NetBSD$

Fix POSIX type aliases for NetBSD.
NetBSD's time_t is __int64_t (always 64-bit), not c_long.
NetBSD's clock_t is unsigned int, not c_long.
NetBSD's suseconds_t is int, not c_long.

--- libphobos/libdruntime/core/sys/posix/sys/types.d.orig	2026-03-16 13:39:49.076551209 -0500
+++ libphobos/libdruntime/core/sys/posix/sys/types.d	2026-03-16 13:39:53.179729755 -0500
@@ -202,7 +202,7 @@
     alias int       pid_t;
     //size_t (defined in core.stdc.stddef)
     alias c_long      ssize_t;
-    alias c_long      time_t;
+    alias long        time_t;
     alias uint        uid_t;
 }
 else version (OpenBSD)
@@ -339,10 +339,10 @@
 {
     alias ulong     fsblkcnt_t;
     alias ulong     fsfilcnt_t;
-    alias c_long    clock_t;
+    alias uint      clock_t;
     alias long      id_t;
     alias c_long    key_t;
-    alias c_long    suseconds_t;
+    alias int       suseconds_t;
     alias uint      useconds_t;
 }
 else version (OpenBSD)
