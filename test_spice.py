#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('SpiceClientGtk', '3.0')
from gi.repository import Gtk, SpiceClientGtk

def main():
    print("Testing Spice-GTK installation...")
    
    # Test basic Gtk functionality
    win = Gtk.Window(title="Spice-GTK Test")
    win.connect("destroy", Gtk.main_quit)
    
    # Test Spice-GTK
    try:
        display = SpiceClientGtk.Display()
        print("✓ SpiceClientGtk.Display initialized successfully")
    except Exception as e:
        print(f"✗ Failed to initialize SpiceClientGtk.Display: {e}")
    
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
