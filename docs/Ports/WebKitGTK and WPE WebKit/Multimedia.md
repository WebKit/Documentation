# Multimedia

The WPE and GTK ports depend on the
[GStreamer](https://gstreamer.freedesktop.org) multimedia framework for their
multimedia-related features, such as video playback (with or without MediaSource
Extensions and Encrypted Media Extensions), WebRTC, WebAudio, WebCodecs and
MediaRecorder.

## Gathering logs

GStreamer logs are often useful to help diagnose issues. Depending on the
browser used, the procedure might slightly change, but the general idea is to
set a few environment variables (mainly `GST_DEBUG` and `GST_DEBUG_FILE`) as
shown below for a couple runtime scenarios.

GStreamer pipeline graph dumps can also be useful for debugging purposes. They
can be enabled by setting the `GST_DEBUG_DUMP_DOT_DIR` environment variable to
an existing filesystem folder path.

Once gathered, the log file and pipeline graph dumps can be zipped together and
uploaded online. Assuming the commands are executed as shown in the next
sections, the log file will be `$HOME/gst.log` and the pipeline graph dumps will
be present in the `$HOME/dots` folder.

## Flatpak apps

In this section we take the example of the [GNOME
Web](https://flathub.org/apps/org.gnome.Epiphany) app, a.k.a. Epiphany.

```shell
mkdir -p $HOME/dots
flatpak run --filesystem=home \
    --env="GST_DEBUG=3,webkit*:6" --env="GST_DEBUG_FILE=$HOME/gst.log" \
    --env="GST_DEBUG_DUMP_DOT_DIR=$HOME/dots" org.gnome.Epiphany -p "https://..."
```

Note: If this command does not produce files as expected and you are using a
WebKitGTK version below 2.50, you will need to add
`--env="WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1"` to the
command-line. See also this [pull request scheduled to ship in
2.50](https://github.com/WebKit/WebKit/pull/43116)

GNOME Web has [three different
flavours](https://gitlab.gnome.org/GNOME/epiphany#download-and-install). The
command above is for the stable version (`org.gnome.Epiphany`). The Tech Preview
application name is `org.gnome.Epiphany.Devel` and the Canary version is called
`org.gnome.Epiphany.Canary`. So depending on which version you test, the
command line will need to be adapted accordingly.

## MiniBrowser

The WPE and GTK ports ship a sample web browser application called MiniBrowser.
Its availability might depend on your Linux distro. If you built a development
version of the WPE or GTK ports, you can start MiniBrowser as shown below, with
the necessary GStreamer environment variables:

```shell
mkdir -p $HOME/dots
export GST_DEBUG="3,webkit*:6" GST_DEBUG_FILE=$HOME/gst.log GST_DEBUG_DUMP_DOT_DIR=$HOME/dots
Tools/Scripts/run-minibrowser --gtk "https://..."
```

## Layout tests

When debugging multimedia layout tests on a developer build of the WPE or GTK
port, the procedure is similar:

```shell
mkdir -p $HOME/dots
export GST_DEBUG="3,webkit*:6" GST_DEBUG_FILE=$HOME/gst.log GST_DEBUG_DUMP_DOT_DIR=$HOME/dots
Tools/Scripts/run-webkit-tests --gtk --no-retry-failures --no-show-results http/tests/media/video-play-stall.html
```

