import pathlib
import sys

path = pathlib.Path(sys.argv[1])
source = path.read_text(encoding='utf-8')
for include in ('#include <gio/gio.h>', '#include <gdk-pixbuf/gdk-pixbuf.h>'):
    if include not in source:
        insertion = '#include <flutter_linux/flutter_linux.h>'
        if insertion not in source:
            raise SystemExit('Unsupported Linux runner template; required headers were not found.')
        source = source.replace(insertion, insertion + '\n' + include, 1)

marker = 'g_file_read_link("/proc/self/exe", NULL)'
if marker not in source:
    anchor = 'gtk_window_set_default_size(window, 1280, 720);'
    if anchor not in source:
        raise SystemExit('Unsupported Linux runner template; window icon patch was not applied.')
    icon_setup = '''gtk_window_set_default_size(window, 1280, 720);

  gchar* executable_path = g_file_read_link("/proc/self/exe", NULL);
  if (executable_path != NULL) {
    gchar* executable_dir = g_path_get_dirname(executable_path);
    gchar* icon_path = g_build_filename(
        executable_dir, "data", "flutter_assets", "assets", "icons",
        "keyfix.png", NULL);
    GError* icon_error = NULL;
    GdkPixbuf* icon = gdk_pixbuf_new_from_file(icon_path, &icon_error);
    if (icon != NULL) {
      gtk_window_set_icon(window, icon);
      g_object_unref(icon);
    }
    if (icon_error != NULL) {
      g_error_free(icon_error);
    }
    g_free(icon_path);
    g_free(executable_dir);
    g_free(executable_path);
  }'''
    source = source.replace(anchor, icon_setup, 1)
path.write_text(source, encoding='utf-8')
