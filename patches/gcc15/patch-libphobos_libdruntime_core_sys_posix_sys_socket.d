$NetBSD$

NetBSD renamed socket() to __socket30 during an ABI transition.
D's extern(C) bypasses C header __RENAME() macros, linking
against the old compat stub.

--- libphobos/libdruntime/core/sys/posix/sys/socket.d.orig	2025-07-02 02:58:14.000000000 +0000
+++ libphobos/libdruntime/core/sys/posix/sys/socket.d
@@ -1704,7 +1704,7 @@
     ssize_t sendto(int, const scope void*, size_t, int, const scope sockaddr*, socklen_t);
     int     setsockopt(int, int, int, const scope void*, socklen_t);
     int     shutdown(int, int) @safe;
-    int     socket(int, int, int) @safe;
+    pragma(mangle, "__socket30") int     socket(int, int, int) @safe;
     int     sockatmark(int) @safe;
     int     socketpair(int, int, int, ref int[2]) @safe;
 }
