tool
extends EditorPlugin

const HeartBeat = preload('res://addons/wakatime/heartbeat.gd')
const MODIFIED_DELAY = 120

var options_popup = preload('res://addons/wakatime/options.tscn')

var wakatime_cli = null
var config_path = null
var is_windows = false

var last_heartbeat = HeartBeat.new()

func _enter_tree():
	pass

func _ready():
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.call_deferred('connect', 'editor_script_changed', self, '_on_script_changed')

	open_options_popup()

func _exit_tree():
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.disconnect('editor_script_changed', self, '_on_script_changed')


func send_heartbeat(file, is_write = false):
	# Setting these early to test if valid to send
	var entity = ProjectSettings.globalize_path(file.resource_path)
	var timestamp = OS.get_unix_time()
	var heartbeat = HeartBeat.new(entity, timestamp, is_write)
	
	if not is_write or entity == last_heartbeat.entity or not enough_time_has_passed(last_heartbeat.timestamp):
		return
	
	# Setting CLI Path here because Godot Plugins suck
	if get_editor_interface().get_editor_settings().has_setting("WakaTime/CLI_Path"):
		wakatime_cli = get_editor_interface().get_editor_settings().get_setting("WakaTime/CLI_Path")
	else:
		push_warning ("WakaTime CLI Path not found, Resorting to Linux default")
		wakatime_cli = OS.get_environment("HOME") + "/.wakatime/wakatime-cli"
		
	if get_editor_interface().get_editor_settings().has_setting("WakaTime/Config_Path"):
		config_path = get_editor_interface().get_editor_settings().get_setting("WakaTime/Config_Path")
	else:
		push_warning ("WakaTime Config Path not found, Resorting to Linux default")
		config_path = OS.get_environment("HOME") + "/.wakatime.cfg"
	
	if OS.get_name() == "Windows":
		is_windows = true
	
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
	OS.execute(wakatime_cli, PoolStringArray(cmd), false, [], false, false)

func _on_script_changed(file):
	send_heartbeat(file)

func _unhandled_key_input(ev):
	var file = get_current_file()
	send_heartbeat(file, true)

func save_external_data():
	var file = get_current_file()
	send_heartbeat(file, true)


func open_options_popup():
	var popup_window = options_popup.instance()
	var settings = get_editor_interface().get_editor_settings()
	popup_window.init(settings)
	add_child(popup_window)
	popup_window.refresh()
	popup_window.popup_centered()
	yield(popup_window, 'popup_hide')
	popup_window.queue_free()


func enough_time_has_passed(last_sent_time):
	return OS.get_unix_time() - last_heartbeat.timestamp >= HeartBeat.FILE_MODIFIED_DELAY

func get_current_file():
	return get_editor_interface().get_script_editor().get_current_script()

func get_user_agent():
	return 'Godot/%s %s/%s' % [get_engine_version(), get_plugin_name(), get_plugin_version()]

func get_plugin_name():
	return 'godot-wakatime'


func get_plugin_version():
	return '0.1'


func get_engine_version():
	return '%s.%s.%s' % [	Engine.get_version_info()['major'],
							Engine.get_version_info()['minor'],
							Engine.get_version_info()['patch']]
