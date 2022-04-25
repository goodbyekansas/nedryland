--- a/setup.py
+++ b/setup.py
@@ -52,7 +52,7 @@
     install_requires=[
         "flask>=1.0,<3.0",
         "click>=7.0,<9.0",
-        "watchdog>=1.0.0,<2.0.0",
+        "watchdog>=1.0.0,<2.2.0",
         "gunicorn>=19.2.0,<21.0; platform_system!='Windows'",
         "cloudevents>=1.2.0,<2.0.0",
     ],
