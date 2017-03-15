#!/usr/bin/env python2

# Imports
import os, sys, subprocess, procname, dbus, gobject
from dbus.mainloop.glib import DBusGMainLoop
DBusGMainLoop(set_as_default=True)
procname.setprocname(os.path.basename(sys.argv[0]))

# Configuration
CORE_PATH = "/org/pulseaudio/core1"
CORE_IFACE = "org.PulseAudio.Core1"
MEMBER = "VolumeUpdated"
MAINVOLUME_IFACE = "org.PulseAudio.Core1.Device"
MAINVOLUME_SIGNAL = MAINVOLUME_IFACE + "." + MEMBER
BASE_VOLUME_PATH = "/org/pulseaudio/core1/sink"
FREEDESKTOP_PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"

# DBus
bus = dbus.SessionBus()
def connect():
    if 'PULSE_DBUS_SERVER' in os.environ:
        address = os.environ['PULSE_DBUS_SERVER']
    else:
	# print bus
	# print bus.list_names()
        server_lookup = bus.get_object("org.PulseAudio1", "/org/pulseaudio/server_lookup1")
        address = server_lookup.Get("org.PulseAudio.ServerLookup1", "Address", dbus_interface="org.freedesktop.DBus.Properties")

    return dbus.connection.Connection(address)

# All D-Bus signals are handled here. The SignalMessage object is passed in
# the keyword arguments with key "msg". We expect only VolumeUpdated signals.
def dbus_signals_callback(*args, **keywords):
    # Get arguments
    args = args[0]
    sender = keywords["msg"]
    
    # Check that it's the signal we're looking for
    if BASE_VOLUME_PATH in sender.get_path() \
            and sender.get_interface() == MAINVOLUME_IFACE \
            and sender.get_member() == MEMBER:
        
        # Get the current step(volume)
        current_step = args[1]
        
        # Grab the sink
        sink = conn.get_object(object_path=sender.get_path())
        
        # Get the max step(volume)
        max_step = sink.Get(MAINVOLUME_IFACE, "VolumeSteps", dbus_interface=FREEDESKTOP_PROPERTIES_IFACE)
        
        # Calculate the percent
        percent = round(float(current_step) / float(max_step) * 100)
        
        # Print the volume
        # print percent, "%"
        
        # Notify Awesome
        # subprocess.Popen(sys.argv[1:])
        subprocess.call('awesome-client "widget_manager:displayVolume(' + str(percent) + ')"', shell=True) 

    else:
        # This code should not get executed, except when the connection dies
        # (pulseaudio exits or something), in which case we get
        # a org.freedesktop.DBus.Local.Disconnected signal.
        print "Unexpected signal:", sender.get_path(), sender.get_interface(), sender.get_member()

# TODO: Decide about this...
subprocess.call('pacmd load-module module-dbus-protocol', shell=True) 

# Connect to the PulseAudio bus
conn = connect()
# Register the signal callback
conn.add_signal_receiver(dbus_signals_callback, message_keyword="msg")

# Get the core object
core = conn.get_object(object_path=CORE_PATH)

# SEND US OUR SIGNAL!
core.ListenForSignal(MAINVOLUME_SIGNAL, dbus.Array(signature='o'), dbus_interface=CORE_IFACE)


# TODO: Ugh, got to fix this shit, or really just find a way to replace this script entirely
# for sinkPath in sinks:
#     sink = conn.get_object(object_path=sinkPath)
#     # sink.connect_to_signal(sig_name, sig_handler, sender_keyword='sender', dbus_interface="org.PulseAudio.Core1.Device")
#     core.ListenForSignal('org.PulseAudio.Core1.Device.{}'.format(sig_name), dbus.Array(signature='u'), dbus_interface="org.PulseAudio.Core1")

# # for sourcePath in sources:
# #     source = conn.get_object(object_path=sourcePath)
# #     # source.connect_to_signal(sig_name, sig_handler, sender_keyword='sender', dbus_interface="org.PulseAudio.Core1.Device")
# #     core.ListenForSignal('org.PulseAudio.Core1.Device.{}'.format(sig_name), dbus.Array(signature='o'))



# Main
loop = gobject.MainLoop()
loop.run()
