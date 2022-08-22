tool
extends PopupPanel

onready var api_key_line_edit = $VBoxContainer/HBoxContainer/API_Key
onready var save_btn = $VBoxContainer/HBoxContainer3/Confirm_Button
onready var cancel_btn = $VBoxContainer/HBoxContainer3/Cancel_Button

var settings = null

func init(settings):
	self.settings = settings

func refresh():
	var api_key = settings.get_setting("WakaTime/API_Key")
	if api_key != null:
		api_key_line_edit.text = api_key

func _on_cancel():
	hide_popup()

func hide_popup():
	if self.visible:
		self.visible = false


func _on_Cancel_Button_pressed():
	hide_popup()


func _on_Confirm_Button_pressed(text=null):
	settings.set_setting("WakaTime/API_Key", api_key_line_edit.get_text())
	hide_popup()
