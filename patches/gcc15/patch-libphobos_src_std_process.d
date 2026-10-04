$NetBSD$

Replace inline dirfd declaration with import from core.sys.posix.dirent,
where the proper platform-aware definition now lives.

--- libphobos/src/std/process.d.orig	2026-10-04 09:38:53.957328654 -0400
+++ libphobos/src/std/process.d	2026-10-04 09:38:53.967433849 -0400
@@ -1036,7 +1036,7 @@
                 {
                     void fallback (int lowfd)
                     {
-                        import core.sys.posix.dirent : dirent, opendir, readdir, closedir, DIR;
+                        import core.sys.posix.dirent : dirfd, dirent, opendir, readdir, closedir, DIR;
                         import core.sys.posix.unistd : close;
                         import core.sys.posix.stdlib : atoi, malloc, free;
                         import core.sys.posix.sys.resource : rlimit, getrlimit, RLIMIT_NOFILE;
@@ -1048,10 +1048,6 @@
 
                         immutable maxDescriptors = cast(int) r.rlim_cur;
 
-                        // Missing druntime declaration
-                        pragma(mangle, "dirfd")
-                        extern(C) nothrow @nogc int dirfd(DIR* dir);
-
                         DIR* dir = null;
 
                         // We read from /dev/fd or /proc/self/fd only if the limit is high enough
