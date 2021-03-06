using Gtk;
using Gdk;
using Posix;

enum OperationMode {
    GET,
    SET
}

enum SelectionKind {
    NORMAL,
    BLOCK
}

class GetClip : Gtk.Application {
    Gdk.Atom clipboard;

    public GetClip(Gdk.Atom clipboard) {
        Object( application_id : "clip.neovim.org",
                flags: ApplicationFlags.NON_UNIQUE );
        this.clipboard = clipboard;
    }

    public override void activate( ) {
        var vimenc_target = Gdk.Atom.intern("_VIMENC_TEXT", false);
        var clip = Gtk.Clipboard.get(this.clipboard);
        if (clip != null) {
            Gdk.Atom[] targets;
            clip.wait_for_targets(out targets); // do we have _VIMENC_TEXT data?
            if (vimenc_target in targets) { // if so...
                var data = clip.wait_for_contents(vimenc_target); // get the SelectionData
                uchar[] target_data = data.get_data_with_length();
                GLib.stdout.write(target_data);
            } else { // retrieve normal text
                var data = clip.wait_for_text();
                if (data != null) {
                    GLib.stdout.printf("%s", data);
                }
            }
        }
    }
}

class SetClip : Gtk.Application {
    Gdk.Atom clipboard_atom;
    Gtk.Clipboard clipboard;
    SelectionKind kind;
    string data;

    public SetClip(Gdk.Atom clipboard, string data, SelectionKind kind) {
        Object( application_id : "clip.neovim.org",
                flags: ApplicationFlags.NON_UNIQUE );
        this.clipboard_atom = clipboard;
        this.data = data;
        this.kind = kind;
    }
    
    public static void get_func(Gtk.Clipboard clipboard, Gtk.SelectionData selection_data, uint info, void* data) {
        selection_data.set_text(((SetClip)data).data, ((SetClip)data).data.length);
        // TODO: this should be encoded
        selection_data.set(Gdk.Atom.intern_static_string("_VIMENC_TEXT"), 8, (uchar[])((SetClip)data).data.data);
    }

    public static void clear_func(Gtk.Clipboard c, void* data) {
        return; 
    }

    public override void activate( ) {
        // would prefer to call gtk_target_list_add_text_targets
        Gtk.TargetEntry t1 = { "TEXT", 0, 0};
        Gtk.TargetEntry t2 = { "STRING", 0, 0};
        Gtk.TargetEntry t3 = { "COMPOUND_TEXT", 0, 0};
        Gtk.TargetEntry t4 = { "UTF8_STRING", 0, 0};
        Gtk.TargetEntry t5 = { "_VIMENC_TEXT", 0, 0};
        Gtk.TargetEntry[] targets = { t1, t2, t3, t4, t5};
        this.clipboard = Gtk.Clipboard.get(this.clipboard_atom);
        this.clipboard.set_with_owner(targets, get_func, clear_func, this); 
        this.clipboard.set_can_store(targets);
        this.clipboard.store();
        // we don't need to fork() anymore, the clipboard is properly stored
        //Gtk.main();
    }
}

public static int main(string[] args) {
    OperationMode mode;
    SelectionKind selection_kind;
    Gdk.Atom clipboard;
    char data[256];

    if ("-s" in args) {
        mode = OperationMode.SET;
    } else {
        mode = OperationMode.GET;
    }
    if ("-p" in args) {
        clipboard = Gdk.SELECTION_PRIMARY;
    } else {
        clipboard = Gdk.SELECTION_CLIPBOARD;
    }
    
    if (mode == OperationMode.GET) {
        var app = new GetClip(clipboard);
        app.run();
    } else {
        if ("-b" in args) {
            selection_kind = SelectionKind.BLOCK;
        } else {
            selection_kind = SelectionKind.NORMAL;
        }
        if (!Posix.isatty(0)) {
            GLib.stdin.gets(data);
            var app = new SetClip(clipboard, (string)data, selection_kind);
            app.run();
        }
    }

    return 0;
}
