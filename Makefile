all:
	valac --pkg gdk-3.0 --pkg gtk+-3.0 --pkg gio-2.0 --pkg posix vim-clip.vala

32bit:
	valac --pkg gdk-3.0 --pkg gtk+-3.0 --pkg gio-2.0 --pkg posix -X -m32 -o vim-clip.32 vim-clip.vala
