# The final shipping manifest is linked separately, so keep component names.
-keep class com.lal.rebuild.manager.HomeActivity { *; }
-keep class com.lal.rebuild.manager.MainActivity { *; }
-keep class com.lal.rebuild.manager.ServerService { *; }
-keep class com.lal.rebuild.manager.BootReceiver { *; }
# Python invokes these three callback methods by their Java names.
-keep class com.lal.rebuild.manager.PythonBridge$Callback { public *; }
# Preserve runtime string decoding, while allowing class/member renaming.
-keep,allowobfuscation class com.lal.rebuild.manager.ProjectNotice { *; }
-keepattributes InnerClasses,EnclosingMethod

-keep class com.lal.rebuild.manager.ModImportActivity { *; }
