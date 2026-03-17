$NetBSD$

Add dirfd() declaration for all platforms. On NetBSD, dirfd is a macro
in <dirent.h> (#define dirfd(dirp) ((dirp)->dd_fd)), not a function,
so provide a D implementation that reads dd_fd (the first field of
struct _dirdesc) directly.

--- libphobos/libdruntime/core/sys/posix/dirent.d.orig	2025-07-02 02:58:14.000000000 +0000
+++ libphobos/libdruntime/core/sys/posix/dirent.d
@@ -303,6 +303,21 @@
     void    rewinddir(DIR*);
 }

+// Missing druntime declaration
+version (NetBSD)
+{
+    // On NetBSD, this is a macro in dirent.h, not a function.
+    extern (D) int dirfd(DIR* dir) nothrow @nogc
+    {
+        // ABI guarantees dd_fd remains the first field
+        return *(cast(int*) dir);
+    }
+}
+else
+{
+    pragma(mangle, "dirfd")
+    nothrow @nogc int dirfd(DIR* dir);
+}
+
 //
 // Thread-Safe Functions (TSF)
 //
