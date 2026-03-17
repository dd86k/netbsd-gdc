$NetBSD$

NetBSD defines dirfd() as a macro in <dirent.h>, not as a function.
There is no dirfd symbol in libc. Provide a D implementation that
reads dd_fd (the first field of struct _dirdesc) directly.

--- libphobos/src/std/process.d.orig	2025-07-02 02:58:14.000000000 +0000
+++ libphobos/src/std/process.d
@@ -1048,9 +1048,20 @@

                         immutable maxDescriptors = cast(int) r.rlim_cur;

-                        // Missing druntime declaration
-                        pragma(mangle, "dirfd")
-                        extern(C) nothrow @nogc int dirfd(DIR* dir);
+                        // dirfd: on NetBSD this is a macro, not a function,
+                        // so provide a D implementation instead.
+                        version (NetBSD)
+                        {
+                            static int dirfd(DIR* dir) nothrow @nogc
+                            {
+                                return *(cast(int*) dir);
+                            }
+                        }
+                        else
+                        {
+                            pragma(mangle, "dirfd")
+                            extern(C) nothrow @nogc int dirfd(DIR* dir);
+                        }

                         DIR* dir = null;

