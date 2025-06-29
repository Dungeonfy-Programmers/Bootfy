extends Control


const SERVER = "https://github.com/Dungeonfy-Programmers/dfysp/archive/refs/heads/main.zip"
const JAVA_WIN = "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_windows-x64_bin.zip"
const JAVA_LINUX = "https://download.java.net/java/GA/jdk22/830ec9fcccef480bb3e73fb7ecafe059/36/GPL/openjdk-22_linux-x64_bin.tar.gz"
const JAVA_MACOS = "https://download.java.net/java/GA/jdk22/830ec9fcccef480bb3e73fb7ecafe059/36/GPL/openjdk-22_macos-x64_bin.tar.gz"
const PAPER = "https://fill-data.papermc.io/v1/objects/cabed3ae77cf55deba7c7d8722bc9cfd5e991201c211665f9265616d9fe5c77b/paper-1.20.4-499.jar"

var downloading = ""

func java_check() -> Array:
	if FileAccess.file_exists("user://dunegonfy/java.zip") || FileAccess.file_exists("user://java.tar.gz"):
		return ["", false]
	if OS.get_name() == "Windows":
		return [JAVA_WIN, true]
	elif OS.get_name() == "macOS":
		return [JAVA_MACOS, true]
	else:
		return [JAVA_LINUX, true]

func start_server() -> void:
	pass # TODO: Server Logic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !DirAccess.dir_exists_absolute("user://dungeonfy"):
		DirAccess.make_dir_absolute("user://dungeonfy")
	if !DirAccess.dir_exists_absolute("user://dungeonfy/dfysp-main"): # Temporary
		DirAccess.make_dir_absolute("user://dungeonfy/dfysp-main")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# TODO: Heavily clean up this code. (Rewrite)

	if $Button.disabled == true:
		if downloading == "Server":
			if $Server.get_body_size() != -1:
				$Download.text = "Downloading Server... " + str(int($Server.get_downloaded_bytes()*100/$Server.get_body_size())) + "% " + str($Server.get_downloaded_bytes()/1000000) + "MB"
			else:
				$Download.text = "Downloading Server... " + str($Server.get_downloaded_bytes()/1000000) + "MB"
		elif downloading == "Java":
			if $Java.get_body_size() != -1:
				$Download.text = "Downloading Java... " + str(int($Java.get_downloaded_bytes()*100/$Java.get_body_size())) + "% " + str($Java.get_downloaded_bytes()/1000000) + "MB"
			else:
				$Download.text = "Downloading Java... " + str($Java.get_downloaded_bytes()/1000000) + "MB"
		elif downloading == "Paper":
			if $Server.get_body_size() != -1:
				$Download.text = "Downloading Paper... " + str(int($Paper.get_downloaded_bytes()*100/$Paper.get_body_size())) + "% " + str($Paper.get_downloaded_bytes()/1000000) + "MB"
			else:
				$Download.text = "Downloading Paper... " + str($Paper.get_downloaded_bytes()/1000000) + "MB"


func _on_button_pressed() -> void:
	if !FileAccess.file_exists("user://dungeonfy/server.zip"):
		$Button.disabled = true 
		$AnimationPlayer.play("slide")
		downloading = "Server"
		$Server.request(SERVER)
	elif !java_check()[1]:
		$Button.disabled = true
		$AnimationPlayer.play("slide")
		downloading = "Java"
		$Java.request(java_check()[0])
	elif !FileAccess.file_exists("user://dungeonfy/dfysp-main/paper.jar"):
		$Button.disabled = true
		$AnimationPlayer.play("slide")
		downloading = "Paper"
		$Paper.request(PAPER)


func _on_server_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var file = FileAccess.open("user://dungeonfy/server.zip", FileAccess.WRITE)
	var success = file.store_buffer(body)
	if success:
		print("Server saved.")
	else:
		print("Server not saved.")
	file.close()
	if java_check()[1]:
		downloading = "Java"
		$Java.request(java_check()[0])
	else:
		$Button.disabled = false
		$AnimationPlayer.play("slide_back")
		start_server()


func _on_java_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if OS.get_name() == "Windows":
		var file = FileAccess.open("user://dungeonfy/java.zip", FileAccess.WRITE)
		file.store_buffer(body)
		file.close()
	else:
		var file = FileAccess.open("user://dungeonfy/java.tar.gz", FileAccess.WRITE)
		file.store_buffer(body)
		file.close()
	
	if !FileAccess.file_exists("user://dungeonfy/dfysp-main/paper.jar"):
		downloading = "Paper"
		$Paper.request(PAPER)
	else:
		$Button.disabled = false
		$AnimationPlayer.play("slide_back")
		start_server()


func _on_paper_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var file = FileAccess.open("user://dungeonfy/dfysp-main/paper.jar", FileAccess.WRITE)
	file.store_buffer(body)
	file.close()

	$Button.disabled = false
	$AnimationPlayer.play("slide_back")
	start_server()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slide":
		$AnimationPlayer.play("loading")
		$AnimationPlayer2.play("fade_in")
		$AnimationPlayer3.play("fade_in_2")
	if anim_name == "slide_back":
		$AnimationPlayer.play("RESET")
		$AnimationPlayer2.play("RESET")
		$AnimationPlayer3.play("RESET")
