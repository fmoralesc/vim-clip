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
  
    public override void activate( ) {
        //Gtk.TargetEntry t = { "_VIMENC_TEXT", 0, 0};
        //Gtk.TargetEntry[] targets = { t };
        this.clipboard = Gtk.Clipboard.get(this.clipboard_atom);
        this.clipboard.set_text(this.data, -1);
        /*
        clip.set_with_owner( targets,
                // get_func
                (clipboard, selection_data, info, owner) => {
                    Atom type;
                    var data = ((SetClip)owner).data;
                    //GLib.stdout.printf("%s", data);
                    //selection_data.set_text(data, -1);
                    type = Gdk.Atom.intern_static_string("_VIMENC_TEXT");
                    selection_data.set(type, 8, (uchar[]) data);
                },
                // clear_func
                (clipboard, user_data) => {
                },
                // owner
                this); 
        */
        this.clipboard.store();
        this.clipboard.owner_change.connect(Gtk.main_quit); // if someone else copies, we quit
        Gtk.main();
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
