extends Control


const SERVER = "https://github.com/Dungeonfy-Programmers/dfysp/archive/refs/heads/main.zip"
const JAVA_WIN = "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_windows-x64_bin.zip"
const JAVA_LINUX = "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz"
const JAVA_MACOS = "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_macos-x64_bin.tar.gz"
const PAPER = "https://fill-data.papermc.io/v1/objects/cabed3ae77cf55deba7c7d8722bc9cfd5e991201c211665f9265616d9fe5c77b/paper-1.20.4-499.jar"

var downloading = ""
var server_up = false
var server_pid: int

var server_log_path = OS.get_data_dir() + "/bootfy/dungeonfy/server_log.output"

var CommandExecutorFile = OS.get_user_data_dir() + "/dungeonfy/dfysp-main/plugins/CommandExecutor/commands.txt"


func java_check() -> Array:
	if DirAccess.dir_exists_absolute("user://dungeonfy/jdk-21.0.2") || DirAccess.dir_exists_absolute("user://dungeonfy/jdk-21.0.2.jdk"):
		return ["", false]
	if OS.get_name() == "Windows":
		return [JAVA_WIN, true]
	elif OS.get_name() == "macOS":
		return [JAVA_MACOS, true]
	else:
		return [JAVA_LINUX, true]
		


func start_server() -> void:
	$AnimationPlayer.play("button_stop")
	$Button.text = "Stop Server"
	server_up = true

	print("Log path:", server_log_path)

	if FileAccess.file_exists(server_log_path):
		var da  = DirAccess
		da.remove_absolute(server_log_path)
	var log_dir = OS.get_data_dir() + "/bootfy/dungeonfy"
	if not DirAccess.dir_exists_absolute(log_dir):
		var da = DirAccess.open(OS.get_data_dir())
		var err = da.make_dir_recursive(log_dir)
		if err != OK:
			print("Failed to create log directory! Error code:", err)

	var test = []
	OS.execute("ls", [], test)
	print(test)

	var java_path = ""
	if OS.get_name() == "macOS":
		java_path = OS.get_user_data_dir() + "/dungeonfy/jdk-21.0.2.jdk/Contents/Home/bin/java"
	else:
		java_path = OS.get_user_data_dir() + "/dungeonfy/jdk-21.0.2/bin/java"

	var java_cmd = (
		"\"" + java_path + "\" " +
		"-Duser.dir=" + OS.get_user_data_dir() + "/dungeonfy/dfysp-main " +
		"-jar " + OS.get_user_data_dir() + "/dungeonfy/dfysp-main/paper.jar " +
		"-nogui " +
		"-P " + OS.get_user_data_dir() + "/dungeonfy/dfysp-main/plugins " +
		"-S " + OS.get_user_data_dir() + "/dungeonfy/dfysp-main/spigot.yml " +
		"-W " + OS.get_user_data_dir() + "/dungeonfy/dfysp-main " +
		"--config " + OS.get_user_data_dir() + "/dungeonfy/dfysp-main/server.properties " +
		"-b " + OS.get_user_data_dir() + "/dungeonfy/dfysp-main/bukkit.yml " +
		"-w ul_void " +
		"--paper-dir " + OS.get_user_data_dir() + "/dungeonfy/dfysp-main/config " +
		"> \"" + server_log_path + "\" 2>&1"
	)

	#print("Full command:", java_cmd)

	var shell = ""
	var shell_args = []

	if OS.get_name() == "macOS" or OS.get_name() == "Linux":
		shell = "/bin/sh"
		shell_args = ["-c", java_cmd]
	else:
		shell = "cmd.exe"
		shell_args = ["/c", java_cmd]

	server_pid = OS.create_process(shell, shell_args)
	if server_pid == -1:
		print("Failed to start server process!")
	else:
		if OS.get_name() != "Windows":
			server_pid += 1
		print("Server started with PID:", server_pid)

func stop_server() -> void:
	$AnimationPlayer.play("button_go")
	$Button.text = "Start Server"
	server_up = false
	var file = FileAccess.open(CommandExecutorFile, FileAccess.WRITE)
	if file:
		file.store_string("stop\n")
		file.close()
	else:
		print("Failed to open command file!")
	OS.kill(server_pid)
	_close_console_window()
	_close_dmod_window()

func manage_server() -> void:
	if server_up:
		stop_server()
	else:
		start_server()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	print("Server Directory: " + OS.get_data_dir() + "/bootfy/dungeonfy")
	if !DirAccess.dir_exists_absolute("user://dungeonfy"):
		DirAccess.make_dir_absolute("user://dungeonfy")
	print("User Data Dir: " +OS.get_user_data_dir())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:

	# TODO: Heavily clean up this code. (Rewrite)
	
	if server_up:
		$Console_Button.visible = true
	else:
		$Console_Button.visible = false
	if server_up and DirAccess.dir_exists_absolute(OS.get_user_data_dir() + "/dungeonfy/dfysp-main/plugins/Skript/scripts"):
		$D_mod_loader.visible = true
	else:
		$D_mod_loader.visible = false

	if $Button.disabled == true:
		if downloading == "Server":
			if $Server.get_body_size() != -1:
				$Download.text = "Downloading Server... " + str(int($Server.get_downloaded_bytes()*100/$Server.get_body_size())) + "% " + str($Server.get_downloaded_bytes()/1000000) + "MB 1/3"
			else:
				$Download.text = "Downloading Server... " + str($Server.get_downloaded_bytes()/1000000) + "MB 1/3"
		elif downloading == "Java":
			if $Java.get_body_size() != -1:
				$Download.text = "Downloading Java... " + str(int($Java.get_downloaded_bytes()*100/$Java.get_body_size())) + "% " + str($Java.get_downloaded_bytes()/1000000) + "MB 2/3"
			else:
				$Download.text = "Downloading Java... " + str($Java.get_downloaded_bytes()/1000000) + "MB 2/3"
		elif downloading == "Paper":
			if $Server.get_body_size() != -1:
				$Download.text = "Downloading Paper... " + str(int($Paper.get_downloaded_bytes()*100/$Paper.get_body_size())) + "% " + str($Paper.get_downloaded_bytes()/1000000) + "MB 3/3"
			else:
				$Download.text = "Downloading Paper... " + str($Paper.get_downloaded_bytes()/1000000) + "MB 3/3"


func _on_button_pressed() -> void:
	if !DirAccess.dir_exists_absolute("user://dungeonfy/dfysp-main"):
		$Button.disabled = true 
		$AnimationPlayer.play("slide")
		downloading = "Server"
		$Server.request(SERVER)
	elif java_check()[1]:
		$Button.disabled = true
		$AnimationPlayer.play("slide")
		downloading = "Java"
		$Java.request(java_check()[0])
	elif !FileAccess.file_exists("user://dungeonfy/dfysp-main/paper.jar"):
		$Button.disabled = true
		$AnimationPlayer.play("slide")
		downloading = "Paper"
		$Paper.request(PAPER)
	else:
		manage_server()


func _on_server_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var file = FileAccess.open("user://dungeonfy/server.zip", FileAccess.WRITE)
	var success = file.store_buffer(body)
	if success:
		print("Server saved.")
	else:
		print("Server not saved.")
	file.close()
	if OS.get_name() == "Windows":
		OS.execute("tar", ["-xf", OS.get_user_data_dir() + "/dungeonfy/server.zip", "-C", OS.get_user_data_dir() + "/dungeonfy"])
	else:
		var zip_path = OS.get_user_data_dir() + "/dungeonfy/server.zip"
		var extract_path = OS.get_user_data_dir() + "/dungeonfy/"
		var cmd = "unzip '%s' -d '%s'" % [zip_path, extract_path]
		print("Running:", cmd)

		OS.execute("/bin/sh", ["-c", cmd])
	if java_check()[1]:
		downloading = "Java"
		$Java.request(java_check()[0])
	else:
		$Button.disabled = false
		$AnimationPlayer.play("slide_back")
		manage_server()


func _on_java_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if OS.get_name() == "Windows":
		var file = FileAccess.open("user://dungeonfy/java.zip", FileAccess.WRITE)
		file.store_buffer(body)
		file.close()
		OS.execute("tar", ["-xf", OS.get_data_dir() + "/bootfy/dungeonfy/java.zip", "-C", OS.get_data_dir() + "/bootfy/dungeonfy"])
	else:
		var file = FileAccess.open("user://dungeonfy/java.tar.gz", FileAccess.WRITE)
		file.store_buffer(body)
		file.close()
		OS.execute("tar", ["xf", OS.get_data_dir() + "/bootfy/dungeonfy/java.tar.gz", "--directory=" + OS.get_data_dir() + "/bootfy/dungeonfy"])
	
	if !FileAccess.file_exists("user://dungeonfy/dfysp-main/paper.jar"):
		downloading = "Paper"
		$Paper.request(PAPER)
	else:
		$Button.disabled = false
		$AnimationPlayer.play("slide_back")
		manage_server()


func _on_paper_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var file = FileAccess.open("user://dungeonfy/dfysp-main/paper.jar", FileAccess.WRITE)
	file.store_buffer(body)
	file.close()

	$Button.disabled = false
	$AnimationPlayer.play("slide_back")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slide":
		$AnimationPlayer.play("loading")
		$AnimationPlayer2.play("fade_in")
		$AnimationPlayer3.play("fade_in_2")
	if anim_name == "slide_back":
		$AnimationPlayer.play("RESET")
		$AnimationPlayer2.play("RESET")
		$AnimationPlayer3.play("RESET")
		manage_server()
		
#----- Console Button Function ------#

var ConsoleWindow = preload("res://Console.tscn")
var ConsoleWindowInstance

func _on_console_button_pressed() -> void:
	if ConsoleWindowInstance == null:
		ConsoleWindowInstance = ConsoleWindow.instantiate()
	
	ConsoleWindowInstance.Server_PID = server_pid
	ConsoleWindowInstance.Server_Log = server_log_path
	add_child(ConsoleWindowInstance)
	ConsoleWindowInstance.show()
	ConsoleWindowInstance.close_requested.connect(_close_console_window)
	
func _close_console_window() -> void:
	if ConsoleWindowInstance == null:
		return
	ConsoleWindowInstance.visible = false
	remove_child(ConsoleWindowInstance)
	ConsoleWindowInstance = null
		
#----- dModLoader function ---------#

var dModWindow = preload("res://dModLoader.tscn")
var dModWindowInstance = null

func _on_D_mod_pressed() -> void:
	if dModWindowInstance == null:
		dModWindowInstance = dModWindow.instantiate()
	
	add_child(dModWindowInstance)
	dModWindowInstance.show()
	dModWindowInstance.close_requested.connect(_close_dmod_window)
	
func _close_dmod_window() -> void:
	if dModWindowInstance == null:
		return
	dModWindowInstance.visible = false
	remove_child(dModWindowInstance)


	
# Handle closing
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if server_pid:
			var file = FileAccess.open(CommandExecutorFile, FileAccess.WRITE)
			if file:
				file.store_string("stop\n")
				file.close()
			else:
				print("Failed to open command file!")
			OS.kill(server_pid)
		get_tree().quit()
