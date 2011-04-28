#!/usr/bin/env python
# nasty equalizer gui by daniel svensson, gmail: dsvensson

# Cleaned up sligntly by Joel Irby: joel AT irbyengineering.com
# TODO:
#	fix slider packing and spacing issues
#	add slider labels
#	never speak of EQF again

# warning:
# the following code might cause religious wars, impaired vision,
# nightmares and in extreme cases even kill kittens.

import xmmsclient
import os
import sys
import pygtk
pygtk.require('2.0')
import gtk
import struct
import base64

import cPickle as pickle
import zlib

####
#
# A GLib connector for PyGTK - 
#	to use with your cool PyGTK xmms2 client.
# Tobias Rundstrom <tru@xmms.org)
#
# Just create the GLibConnector() class with a xmmsclient as argument
#
###

import gobject

class GLibConnector:
	def __init__(self, xmms):
		self.xmms = xmms
		xmms.set_need_out_fun(self.need_out)
		gobject.io_add_watch(self.xmms.get_fd(), gobject.IO_IN, self.handle_in)
		self.has_out_watch = False

	def need_out(self, i):
		if self.xmms.want_ioout() and not self.has_out_watch:
			gobject.io_add_watch(self.xmms.get_fd(), gobject.IO_OUT, self.handle_out)
			self.has_out_watch = True

	def handle_in(self, source, cond):
		if cond == gobject.IO_IN:
			return self.xmms.ioin()

		return True

	def handle_out(self, source, cond):
		if cond == gobject.IO_OUT:
			self.xmms.ioout()
		self.has_out_watch = self.xmms.want_ioout()
		return self.has_out_watch

class Equalizer:
	def __init__(self):
		self.enabled = False
		self.chained = False

		# hack to mostly get rid of jump sliders
		self.moving = False

		self.window = gtk.Window(gtk.WINDOW_TOPLEVEL)

		self.xmms = xmmsclient.XMMS("eq")

		try:
			self.xmms.connect("tcp://10.0.0.5:9090")
		except IOError:
			try:
				self.xmms.connect(os.getenv("XMMS_PATH"))
			except IOError, detail:
				print "Connection failed:", detail
				sys.exit(1)
		GLibConnector(self.xmms)
		self.xmms.configval_list(self.handle_configval_list)
		self.xmms.broadcast_configval_changed(self.handle_configval_update)

		vbox = gtk.VBox ()
		hbox = gtk.HBox ()

		self.enable = gtk.CheckButton("enabled")
		self.enable.connect("toggled", self.handle_eq_toggle,
		                    "equalizer.enabled")
		hbox.pack_start(self.enable, expand=False, fill=False, padding=0)

		self.legacy = gtk.CheckButton("legacy")
		self.legacy.connect("toggled", self.handle_eq_toggle,
		                    "equalizer.use_legacy")
		hbox.pack_start(self.legacy, expand=False, fill=False, padding=0)

		self.extra_filter = gtk.CheckButton("extra filtering")
		self.extra_filter.connect("toggled", self.handle_eq_toggle,
		                    "equalizer.extra_filtering")
		hbox.pack_start(self.extra_filter, expand=False, fill=False, padding=0)


		self.bands_combo = gtk.ComboBox()
		self.bands_combo = gtk.combo_box_new_text()
		for val in ["10","15","25","31"]:
			self.bands_combo.append_text(val)
		self.bands_combo.set_active(1)
		self.bands_combo.connect("changed", self.handle_bands_changed)
		hbox.pack_start(self.bands_combo, expand=False, fill=False, padding=0)

		button = gtk.Button("Save EQ")
		button.connect("clicked", self.handle_save_eqp)
		hbox.pack_start(button, expand=False, fill=False, padding=0)

		button = gtk.Button("Load EQ")
		button.connect("clicked", self.handle_load_eqp)
		hbox.pack_start(button, expand=False, fill=False, padding=0)

		button = gtk.Button("reset")
		button.connect("clicked", self.handle_reset)
		hbox.pack_start(button, expand=False, fill=False, padding=0)

		vbox.pack_start(hbox, expand=False, fill=True, padding=0)

		hbox = gtk.HBox()
		self.preamp = gtk.VScale()
		self.preamp.set_inverted(True)
		self.preamp.set_range(-20.0,20.0)
		self.preamp.set_increments(0.1,1.0)
		self.preamp.connect("value-changed",
		                    self.handle_band_changed,
		                    "equalizer.preamp")
		self.preamp.connect("button-press-event",self.handle_update,True)
		self.preamp.connect("button-release-event",self.handle_update,False)
		hbox.pack_start(self.preamp, expand=False, fill=True, padding=10)

		self.bands_box = gtk.HBox()
		hbox.pack_start(self.bands_box, expand=True, fill=True, padding=20)

		vbox.add(hbox)

		#color = gtk.gdk.color_parse("#e91500")
		#self.window.modify_bg(gtk.STATE_NORMAL, color)
		#self.window.set_title("it's what you make of it...")

		self.window.add(vbox)

		self.window.connect("destroy", self.destroy)
		self.window.resize(400,150)
		self.window.show_all ()

	def handle_save_eqp(self, widget):
		dlg = gtk.FileChooserDialog("save preset", self.window,
									action=gtk.FILE_CHOOSER_ACTION_SAVE,
									buttons=(gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
											gtk.STOCK_SAVE, gtk.RESPONSE_OK))
		filter = gtk.FileFilter()
		filter.set_name("EQ Pickle")
		filter.add_pattern("*.eqp")
		dlg.add_filter(filter)
		resp = dlg.run()
		if resp == gtk.RESPONSE_OK:
			filename = dlg.get_filename()
			filename = filename.rstrip(" .")
			if not filename.endswith(".eqp"):
				filename = filename + ".eqp"
			self.eqp_filename = filename
			self.xmms.configval_list(self.save_eqp)
		dlg.destroy()

	def save_eqp(self, res):
		dict = res.value()
		pickle_dict = {}
		pickle_dict["equalizer.bands"] = dict["equalizer.bands"]
		pickle_dict["equalizer.extra_filtering"] = dict["equalizer.extra_filtering"]
		pickle_dict["equalizer.preamp"] = dict["equalizer.preamp"]
		pickle_dict["equalizer.use_legacy"] = dict["equalizer.use_legacy"]
		if dict["equalizer.use_legacy"] == "0":
			for i in range(int(dict["equalizer.bands"])):
				pickle_dict["equalizer.gain%02d" % i] = dict["equalizer.gain%02d" % i]
		else:
			for i in range(10):
				pickle_dict["equalizer.legacy%d" % i] = dict["equalizer.legacy%d" % i]
		output = open(self.eqp_filename, 'wb')
		string = pickle.dumps(pickle_dict)
		try:
			string = zlib.compress(string)
		except:
			pass
		output.write(string)
		output.close()
		self.eqp_filename = None

	def handle_load_eqp(self, widget):
		dlg = gtk.FileChooserDialog("load preset",self.window,
		                            action=gtk.FILE_CHOOSER_ACTION_OPEN,
		                            buttons=(gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
		                                     gtk.STOCK_OPEN, gtk.RESPONSE_OK))
		filter = gtk.FileFilter()
		filter.set_name("EQ Pickle")
		filter.add_pattern("*.eqp")
		dlg.add_filter(filter)
		resp = dlg.run()
		if resp == gtk.RESPONSE_OK:
			filename = dlg.get_filename()
			input = open(filename, "rb")
			string = input.read()
			try:
				string = zlib.decompress(string)
			except:
				pass
			dict = pickle.loads(string)
			input.close()
			try:
				self.xmms.configval_set("equalizer.bands", dict["equalizer.bands"])
				self.xmms.configval_set("equalizer.extra_filtering", dict["equalizer.extra_filtering"])
				self.xmms.configval_set("equalizer.preamp", dict["equalizer.preamp"])
				self.xmms.configval_set("equalizer.use_legacy", dict["equalizer.use_legacy"])
				if dict["equalizer.use_legacy"] == "0":
					for i in range(int(dict["equalizer.bands"])):
						self.xmms.configval_set("equalizer.gain%02d" % i, dict["equalizer.gain%02d" % i])
				else:
					for i in range(10):
						self.xmms.configval_set("equalizer.legacy%d" % i, dict["equalizer.legacy%d" % i])
			except:
				pass
		dlg.destroy()

	# exit app
	def destroy(self, widget, data=None):
		gtk.main_quit()

	# reset all bands to 0
	def handle_reset(self, widget):
		for i in range(0,31):
			self.xmms.configval_set("equalizer.gain%02d" % i, "0")
		for i in range(0,10):
			self.xmms.configval_set("equalizer.legacy%d" % i, "0")
		self.xmms.configval_set("equalizer.preamp", "0")

	# hack to mostly get rid of jump sliders
	def handle_update(self, widget, event, data=None):
		self.moving=data
	
	# set equalizer.gainXX or equalizer.legacyX to some value
	def handle_band_changed(self, widget, data=None):
		self.xmms.configval_set(data, str(widget.get_value()))

	# set number of bands
	def handle_bands_changed(self, widget):
		val = widget.get_active()
		if val == 0:
			self.xmms.configval_set("equalizer.bands","10")
		if val == 1:
			self.xmms.configval_set("equalizer.bands","15")
		if val == 2:
			self.xmms.configval_set("equalizer.bands","25")
		if val == 3:
			self.xmms.configval_set("equalizer.bands","31")

	# handle diffrent xmms2 config <-> gui connections
	def handle_configval_update(self,res,init=False):
		dict = res.value()
		order = 0
		for key in dict:
			if key.startswith("equalizer.bands"):
				val = int(dict[key])
				if val == 10:
					self.bands_combo.set_active(0)
				elif val == 15:
					self.bands_combo.set_active(1)
				elif val == 25:
					self.bands_combo.set_active(2)
				elif val == 31:
					self.bands_combo.set_active(3)

				if not init:
					self.xmms.configval_list(self.populate)

			elif key.startswith("equalizer.enabled"):
				if dict[key] == "1":
					self.enable.set_active(True)
				else:
					self.enable.set_active(False)
			elif key == "equalizer.use_legacy":
				if dict[key] == "1":
					self.legacy.set_active(True)
				else:
					self.legacy.set_active(False)

				if not init:
					self.xmms.configval_list(self.populate)
			elif key == "equalizer.extra_filtering":
				if dict[key] == "1":
					self.extra_filter.set_active(True)
				else:
					self.extra_filter.set_active(False)

			elif key == "equalizer.preamp" and not self.moving:
				self.preamp.set_value(float(dict[key]))

			elif key.startswith("equalizer.gain") and not init and not self.moving:
				band = int(key[-2:])
				try: # this looks funny but shouldn't break anything
					scale = self.bands_box.get_children()[band]
					val = float(dict[key])
					scale.set_value(float(dict[key]))
				except:
					pass
			elif key.startswith("equalizer.legacy") and not init and not self.moving:
				band = int(key[-1:])
				try: # this looks funny but shouldn't break anything
					scale = self.bands_box.get_children()[band]
					val = float(dict[key])
					scale.set_value(float(dict[key]))
				except:
					pass


	# toggle some configval
	def handle_eq_toggle(self, widget, data=None):
		if widget.get_active():
			self.xmms.configval_set (data, "1")
		else:
			self.xmms.configval_set (data, "0")
		if data == "equalizer.use_legacy":
			self.bands_combo.set_sensitive(not widget.get_active())

	def handle_configval_list(self, res):
		dict = res.value()
		order = 0
		for key in dict:
			# check if equalizer is in the chain already
			# and if it's not then find out the position
			# to put it in.
			if key.startswith("effect.order"):
				if dict[key] == "equalizer":
					self.chained = True
				elif len(dict[key]) == 0:
					pass
				else:
					order += 1

		if not self.chained:
			val = "effect.order.%d" % order
			self.xmms.configval_set(val, "equalizer")
			self.chained = True
			# make sure equalizer is in the chain somewhere
			self.xmms.playback_stop()
			self.xmms.playback_start()
			self.xmms.playback_stop()

		self.handle_configval_update(res,init=True)

		self.populate(res)

	# add sliders for all the bands
	def populate(self, res):
		dict = res.value()

		# check for winamp/xmms1 legacy mode
		if self.legacy.get_active():
			bands = 10
		else:
			bands = int(dict["equalizer.bands"])

		# remove old children
		for child in self.bands_box.get_children():
			self.bands_box.remove(child)

		for i in range(0,bands):
			scale= gtk.VScale()
			scale.set_inverted(True)
			scale.set_range(-20.0,20.0)
			scale.set_increments(0.1,1.0)

			if self.legacy.get_active():
				name = "equalizer.legacy%d" % i
			else:
				name = "equalizer.gain%02d" % i

			scale.set_value(float(dict[name]));
			scale.connect("button-press-event",self.handle_update,True)
			scale.connect("button-release-event",self.handle_update,False)
			scale.connect("value-changed", self.handle_band_changed, name)

			self.bands_box.pack_start(scale, expand=True, fill=True, padding=0)
		self.bands_box.show_all()
		self.window.resize(100,150)

	def main(self):
		gtk.main()

if __name__ == "__main__":
		eq = Equalizer()
		eq.main()
