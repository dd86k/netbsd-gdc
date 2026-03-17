$NetBSD$

NetBSD renamed passwd functions during its ABI transitions:
getpwnam -> __getpwnam50, getpwuid -> __getpwuid50,
getpwent -> __getpwent50.  D's extern(C) bypasses C header
__RENAME() macros, linking against old compat stubs.

--- libphobos/libdruntime/core/sys/posix/pwd.d.orig	2025-07-02 02:58:14.000000000 +0000
+++ libphobos/libdruntime/core/sys/posix/pwd.d
@@ -201,8 +201,16 @@
     static assert(false, "Unsupported platform");
 }

-passwd* getpwnam(const scope char*);
-passwd* getpwuid(uid_t);
+version (NetBSD)
+{
+    pragma(mangle, "__getpwnam50") passwd* getpwnam(const scope char*);
+    pragma(mangle, "__getpwuid50") passwd* getpwuid(uid_t);
+}
+else
+{
+    passwd* getpwnam(const scope char*);
+    passwd* getpwuid(uid_t);
+}

 //
 // Thread-Safe Functions (TSF)
@@ -301,7 +309,7 @@
 else version (NetBSD)
 {
     void    endpwent();
-    passwd* getpwent();
+    pragma(mangle, "__getpwent50") passwd* getpwent();
     void    setpwent();
 }
 else version (OpenBSD)
