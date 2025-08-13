extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_delete_pressed() -> void:
	rmdir(OS.get_user_data_dir().path_join("dungeonfy"))


func _on_folder_pressed() -> void:
	OS.shell_open(OS.get_user_data_dir().path_join("dungeonfy"))


# modified this time
func rmdir(directory: String) -> void:
	var dir = DirAccess.open(directory)
	if dir:
		dir.include_hidden = true
		
		for file in dir.get_files():
			dir.remove(file)
			
		for subdir in dir.get_directories():
			rmdir(directory.path_join(subdir))
	
	DirAccess.remove_absolute(directory)
