$NetBSD$

Replace inline dirfd declaration with import from core.sys.posix.dirent,
where the proper platform-aware definition now lives.

--- libphobos/src/std/process.d.orig	2025-07-02 02:58:14.000000000 +0000
+++ libphobos/src/std/process.d
@@ -1029,15 +1029,12 @@
                     void fallback (int lowfd)
                     {
-                        import core.sys.posix.dirent : dirent, opendir, readdir, closedir, DIR;
+                        import core.sys.posix.dirent : dirfd, dirent, opendir, readdir, closedir, DIR;
                         import core.sys.posix.unistd : close;
                         import core.sys.posix.stdlib : atoi, malloc, free;
                         import core.sys.posix.sys.resource : rlimit, getrlimit, RLIMIT_NOFILE;

                         // Get the maximum number of file descriptors that could be open.
                         rlimit r;
                         if (getrlimit(RLIMIT_NOFILE, &r) != 0)
                             abortOnError(forkPipeOut, InternalError.getrlimit, .errno);

                         immutable maxDescriptors = cast(int) r.rlim_cur;

-                        // Missing druntime declaration
-                        pragma(mangle, "dirfd")
-                        extern(C) nothrow @nogc int dirfd(DIR* dir);
-
                         DIR* dir = null;
