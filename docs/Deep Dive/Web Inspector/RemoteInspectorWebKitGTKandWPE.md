# Using the Remote Inspector with WebKitGTK+ and WPE

The remote inspector enables debugging of web pages in environment where you might not be able to run the web inspector directly, such as WPE running in embedded targets.

To run the remote inspector, you need to:

- set the environment variable `WEBKIT_INSPECTOR_SERVER=ip:port` before running jsc or a browser/launcher powered by WPE or WebKitGTK+
- enable the WebKitSettings `enable-developer-extras`

For example:

```
export WEBKIT_INSPECTOR_SERVER=192.168.0.50:5000
MiniBrowser --enable-developer-extras=true https://wpewebkit.org
```

Then, open another browser with the same version of WebKitGTK+ (matching the WPE version if it's the case) and open `inspector://ip:port`:


```
MiniBrowser inspector://192.168.0.50:5000
```
