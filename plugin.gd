@tool
extends EditorPlugin

const HeartBeat = preload('res://addons/wakatime/heartbeat.gd')
const MODIFIED_DELAY = 120

var options_popup = preload('res://addons/wakatime/options.tscn')

var wakatime_cli = null
var config_path = null

var last_heartbeat = HeartBeat.new()
var _current_scene_type: String
var _current_scene_path: String
var _current_script_path: String

func _enter_tree():
	pass

func _ready():
	connect("main_screen_changed",Callable(self,"_on_main_scene_changed"))
	connect("scene_changed",Callable(self,"_on_scene_changed"))
	connect("resource_saved",Callable(self,"_on_resource_saved"))
	get_editor_interface().get_script_editor().connect("editor_script_changed",Callable(self,"_on_editor_script_changed"))
	add_tool_menu_item("WakaTime Settings", open_options_popup)

func _exit_tree():
	disconnect("main_screen_changed",Callable(self,"_on_main_scene_changed"))
	disconnect("scene_changed",Callable(self,"_on_scene_changed"))
	disconnect("resource_saved",Callable(self,"_on_resource_saved"))
	get_editor_interface().get_script_editor().disconnect("editor_script_changed",Callable(self,"_on_editor_script_changed"))
	remove_tool_menu_item("WakaTime Settings")

func _on_editor_script_changed(script: Script) -> void:
	if script:
		var _current_script_path = script.get_path()
		send_heartbeat(_current_script_path)

# Scene here means 2D, 3D, Script, ETC
func _on_main_scene_changed(screen_name: String) -> void:
	_current_scene_type = screen_name
	#print(screen_name)

func _on_scene_changed(screen_root: Node) -> void:
	if is_instance_valid(screen_root):
		_current_scene_path = screen_root.filename
		send_heartbeat(_current_scene_path)

func _on_script_changed(file):
	send_heartbeat(file)

func _save_external_data():
	print("Scene Saved")

func _on_resource_saved(resource):
	print("Resource Saved!")
	send_heartbeat(resource.resource_path, true)

func send_heartbeat(file, is_write = false):
	# Setting these early to test if valid to send
	# Note this must be a full filesystem path for WakaTime (I think...)
	var entity = ProjectSettings.globalize_path(file)
	#print(entity)
	var timestamp = Time.get_unix_time_from_system()
	var heartbeat = HeartBeat.new(entity, timestamp, is_write)
	
	if not enough_time_has_passed(last_heartbeat.timestamp):
		return
	
	# Setting CLI Path3D here because Godot Plugins suck
	if get_editor_interface().get_editor_settings().has_setting("WakaTime/CLI_Path"):
		wakatime_cli = get_editor_interface().get_editor_settings().get_setting("WakaTime/CLI_Path")
	else:
		push_warning ("WakaTime CLI Path3D not found, Resorting to Linux default")
		wakatime_cli = OS.get_environment("HOME") + "/.wakatime/wakatime-cli"
		
	if get_editor_interface().get_editor_settings().has_setting("WakaTime/Config_Path"):
		config_path = get_editor_interface().get_editor_settings().get_setting("WakaTime/Config_Path")
	else:
		push_warning ("WakaTime Config Path3D not found, Resorting sto Linux default")
		config_path = OS.get_environment("HOME") + "/.wakatime.cfg"

	var project = ProjectSettings.get('application/config/name')
	
	var cmd = []
	
	# Prepare Command Arguments
	cmd  = ['--config', config_path, '--entity', entity, '--time', timestamp, '--plugin', get_user_agent()]
	
	if is_write:
		cmd.append_array(['--write'])
	
	if get_editor_interface().get_editor_settings().has_setting("WakaTime/Hide_Project_Name") && get_editor_interface().get_editor_settings().get_setting("WakaTime/Hide_Project_Name"):
		print("Hiding Project Name")
	else:
		cmd.append_array(['--project', project])

	if get_editor_interface().get_editor_settings().has_setting("WakaTime/Hide_Filenames") && get_editor_interface().get_editor_settings().get_setting("WakaTime/Hide_Filenames"):
		print("Hiding Filenames")
		cmd.append_array(['--hidefilenames'])
	
	if get_editor_interface().get_editor_settings().has_setting("WakaTime/Hide_Project_Folder") && get_editor_interface().get_editor_settings().get_setting("WakaTime/Hide_Project_Folder"):
		print("Hiding Project Folder")
		cmd.append_array(['--project-folder'])
	
	last_heartbeat = heartbeat
	
	#print(cmd)
	#print(wakatime_cli)
	OS.execute(wakatime_cli, PackedStringArray(cmd), [], false, false)

func open_options_popup():
	var popup_window = options_popup.instantiate()
	var settings = get_editor_interface().get_editor_settings()
	popup_window.init(settings)
	add_child(popup_window)
	popup_window.refresh()
	popup_window.popup_centered()
	await popup_window.popup_hide
	popup_window.queue_free()


func enough_time_has_passed(last_sent_time):
	return Time.get_unix_time_from_system() - last_heartbeat.timestamp >= HeartBeat.FILE_MODIFIED_DELAY

func get_user_agent():
	return 'Godot/%s %s/%s' % [get_engine_version(), _get_plugin_name(), get_plugin_version()]

func _get_plugin_name():
	return 'godot-wakatime'


func get_plugin_version():
	return '0.2'


func get_engine_version():
	return '%s.%s.%s' % [	Engine.get_version_info()['major'],
							Engine.get_version_info()['minor'],
							Engine.get_version_info()['patch']]
