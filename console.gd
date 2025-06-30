extends Window

var Server_PID: int
var Server_Log
var CommandExecutorFile = OS.get_data_dir() + "/bootfy/dungeonfy/dfysp-main/plugins/CommandExecutor/commands.txt"

var log_file: FileAccess = null
var last_read_pos: int = 0

func _ready() -> void:
	print("PID: " + str(Server_PID))
	open_log_file(Server_Log)
	var contents = read_all_log()
	$UI/TextEdit.text += contents

func _process(_delta: float) -> void:
	var new_lines = read_new_log_lines()
	if new_lines != "":
		$UI/TextEdit.text += new_lines
		$UI/TextEdit.scroll_vertical = $UI/TextEdit.get_line_count()

func open_log_file(log_path: String) -> void:
	if FileAccess.file_exists(log_path):
		log_file = FileAccess.open(log_path, FileAccess.READ)
		if log_file:
			last_read_pos = 0
	else:
		print("Log file not found:", log_path)

func read_all_log() -> String:
	if not log_file:
		return ""
	log_file.seek(0)
	var file_len = log_file.get_length()
	var all_data = log_file.get_buffer(file_len).get_string_from_utf8()
	last_read_pos = file_len
	return all_data

func read_new_log_lines() -> String:
	if not log_file:
		return ""
	var file_len = log_file.get_length()
	if file_len < last_read_pos:
		last_read_pos = 0
	log_file.seek(last_read_pos)
	var new_data = log_file.get_buffer(file_len - last_read_pos).get_string_from_utf8()
	last_read_pos = log_file.get_position()
	return new_data

func _on_line_edit_submit(new_text: String ) -> void:
	print(CommandExecutorFile)
	var file := FileAccess.open(CommandExecutorFile, FileAccess.WRITE)
	if file:
		file.store_string(new_text + "\n")
		file.close()
		print("Command: ", new_text)
	else:
		print("Failed to open command file!")
	$UI/LineEdit.text = ""
