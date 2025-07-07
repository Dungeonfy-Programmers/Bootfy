extends Window

var skripts_dir_url = "https://dungeonfy-programmers.github.io/Bootfy-Skripts-Repository/list.json"
var skripts_download_path = OS.get_user_data_dir() + "/dungeonfy/dfysp-main/plugins/Skript/scripts/bootfy/"
var map_download_path = OS.get_user_data_dir() + "/dungeonfy/dfysp-main/mappacks/"

var folder_queue: Array = []
var download_queue: Array = []
var skript_info: Dictionary = {}

var current_download: Dictionary = {}
var skript_download: Dictionary = {}


func _ready() -> void:
	$SkriptRepo.request(skripts_dir_url)

func _populate_item_list(filter=null):
	$ui/ItemList.clear()
	$ui/InstalledList.clear()
	var installed = []
	
	var files = get_all_files_in_dir(skripts_download_path)
	var maps = get_all_files_in_dir(map_download_path)
			
	
	if filter == null:
		for map in maps:
			if str(map).ends_with('.zip'):
				$ui/InstalledList.add_item(str(map))
				installed.append(str(map).split('.')[0])
		for file in files:
			if str(file).ends_with('.sk'):
				$ui/InstalledList.add_item(str(file))
				installed.append(str(file).split('.')[0])
		for key in skript_info["mappacks"].keys():
			$ui/ItemList.add_item(key + " (Map Pack): " + skript_info["mappacks"][key]['description'])
			$ui/ItemList.set_item_custom_fg_color($ui/ItemList.item_count - 1, Color('#80ffff'))
			if key + " (Map Pack)" in installed:
				$ui/ItemList.set_item_custom_bg_color($ui/ItemList.item_count -1, Color('#00af6e55'))
		for key in skript_info.keys():
			if key == "mappacks":
				return # skip map packs for listing skripts
			$ui/ItemList.add_item(key + ": " + skript_info[key]['description'])
			if key in installed:
				$ui/ItemList.set_item_custom_bg_color($ui/ItemList.item_count -1, Color('#00af6e55'))
	else:
		for map in maps:
			if str(map).ends_with(".zip"):
				if str(map).contains(filter):
					$ui/InstalledList.add_item(str(map))
					installed.append(str(map).split('.')[0])
		for file in files:
			if str(file).ends_with('.sk'):
				if str(file).contains(filter):
					$ui/InstalledList.add_item(str(file))
					installed.append(str(file).split('.')[0])
		for key in skript_info["mappacks"].keys():
			if str(key).contains(filter):
				$ui/ItemList.add_item(key + " (Map Pack): " + skript_info["mappacks"][key]['description'])
				$ui/ItemList.set_item_custom_fg_color($ui/ItemList.item_count - 1, Color('#80ffff'))
				if key + " (Map Pack)" in installed:
					$ui/ItemList.set_item_custom_bg_color($ui/ItemList.item_count -1, Color('#00af6e55'))
		for key in skript_info.keys():
			if key == "mappacks":
				return # skip map packs for listing skripts
			if str(key).contains(filter):
				$ui/ItemList.add_item(key + ": " + skript_info[key]['description'])
				if key in installed:
					$ui/ItemList.set_item_custom_bg_color($ui/ItemList.item_count -1, Color('#00af6e55'))
			
func _on_item_list_item_selected(index: int) -> void:
	if $ui/ItemList.get_item_text(index).split(':')[0].split('(').has("Map Pack)"): # weird regex-ish stuff. Don't mess with too much please
		for i in DirAccess.get_files_at(map_download_path):
			if i.ends_with(".zip"):
				_populate_item_list() # screen refresh so the user sees an animation
				return # don't bother with changing the map if you already have one installed
		if FileAccess.file_exists(skripts_download_path + $ui/ItemList.get_item_text(index).split('(')[0].strip_edges() + ".sk"):
			DirAccess.remove_absolute(skripts_download_path + $ui/ItemList.get_item_text(index).split('(')[0].strip_edges() + ".sk")
		var map_key = $ui/ItemList.get_item_text(index).split('(')[0].strip_edges()
		var map_url = skript_info["mappacks"][map_key]["map_url"]
		download_map(map_url, map_download_path + map_key + " (Map Pack).zip")
		# download skript if available
		if skript_info["mappacks"][map_key]["skript_url"]:
			var skript_url = skript_info["mappacks"][map_key]["skript_url"]
			download_silent(skript_url, skripts_download_path + map_key + ".sk")
		return
	var key = $ui/ItemList.get_item_text(index).split(':')[0]
	var url = skript_info[key]['url']
	_download_file(url, skripts_download_path + key +".sk")
	
func _on_installed_list_selected(index: int) -> void:
	if $ui/InstalledList.get_item_text(index).split(':')[0].split('(').has("Map Pack)"):
		print($ui/InstalledList.get_item_text(index).split(':')[0].split('('))
		var map = $ui/InstalledList.get_item_text(index).split('(')[0].strip_edges()
		var map_path = map_download_path + map
		if DirAccess.dir_exists_absolute(OS.get_user_data_dir().path_join("dungeonfy/dfysp-main/ul_void/playerdata")):
			print("zoinks!!!! jinkies!!!")
			rmdir(OS.get_user_data_dir().path_join("dungeonfy/dfysp-main/ul_void/playerdata"))
		DirAccess.rename_absolute(map_download_path.path_join("ul_void/playerdata"), OS.get_user_data_dir().path_join("dungeonfy/dfysp-main/ul_void/playerdata"))
		print("aaaa")
		rmdir(map_download_path.path_join("ul_void"))
		DirAccess.remove_absolute(map_path + " (Map Pack).zip")
		if FileAccess.file_exists(skripts_download_path + map + ".sk"):
			DirAccess.remove_absolute(skripts_download_path + map + ".sk")
		_populate_item_list()
		$ui/SearchBar.text = ""
		return
	var file = $ui/InstalledList.get_item_text(index)
	
	var file_path = skripts_download_path + file
	var err = DirAccess.remove_absolute(file_path)
	if err == OK:
		print("File deleted successfully.")
	else:
		print("Failed to delete file. Error code: ", err)
		
	_populate_item_list()
	$ui/SearchBar.text = ''

	
func _search_filter_submit(new_text: String) -> void:
	if new_text.strip_edges() != '':
		_populate_item_list(new_text.strip_edges())
		return
	_populate_item_list()
	
func get_all_files_in_dir(path: String) -> Array:
	var files := []
	var dir := DirAccess.open(path)
	if dir == null:
		print("Failed to open directory:", path)
		return files
	
	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue 
		files.append(file_name)
	dir.list_dir_end()
	return files



#--------- Getting Files -------------------#
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		print("Request failed, code:", response_code)
		return

	var text := body.get_string_from_utf8()
	var json := JSON.new()
	var err := json.parse(text)

	if err != OK:
		print("json parse error")
	
	skript_info = parse_json_to_dict(str(json.get_data()))
	
	_populate_item_list()
	
func _download_file(url, path):
	for i in range($ui/ItemList.get_item_count()):
		$ui/ItemList.set_item_disabled(i, true)
	print("Starting download from:", url, " -> will save as:", path)

	current_download = {
		"url": url,
		"location": path
	}
	$SkriptDownloader.request(url)

func download_map(url, path):
	for i in range($ui/ItemList.get_item_count()):
		$ui/ItemList.set_item_disabled(i, true)
	print("Starting map download from ", url, " -> will save as ", path)
	current_download = {
		"url": url, 
		"location": path
	}
	$MapDownloader.request(url)

func download_silent(url, path):
	print("Starting silent download from ", url, " -> will save as ", path)
	skript_download = {
		"url": url,
		"location": path
	}
	$SkriptMapDownloader.request(url)
	
func _on_skript_downloader_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		print("Download failed, code:", response_code)
		current_download = {}
		return
	var dir_path = current_download['location'].get_base_dir()
	var dir = DirAccess.open(dir_path)
	if dir == null:
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			print("Failed to create directory:", dir_path)
			current_download = {}
			return

	var file = FileAccess.open(current_download["location"], FileAccess.WRITE)
	if file == null:
		print("Failed to open file for writing:", current_download["location"])
		current_download = {}
		return
	
	file.store_buffer(body)
	file.close()
	print("File downloaded and saved to:", current_download["location"])
	current_download = {}
	for i in range($ui/ItemList.get_item_count()):
		$ui/ItemList.set_item_disabled(i, false)
	_populate_item_list()
	


func parse_json_to_dict(json_text: String) -> Dictionary:
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		print("Failed to parse JSON! Error code:", err)
		return {}
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		print("Expected a dictionary in the JSON data")
		return {}
	
	return data
	


func _on_map_downloader_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		print("Download failed, code:", response_code)
		current_download = {}
		return
	var dir_path = current_download['location'].get_base_dir()
	var dir = DirAccess.open(dir_path)
	if dir == null:
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			print("Failed to create directory:", dir_path)
			current_download = {}
			return

	var file = FileAccess.open(current_download["location"], FileAccess.WRITE)
	if file == null:
		print("Failed to open file for writing:", current_download["location"])
		current_download = {}
		return
	
	file.store_buffer(body)
	file.close()
	
	if OS.get_name() == "Windows":
		# Windows is the most annoying operating system I've ever had the displeasure of interacting with
		OS.execute("powershell.exe", ["-Command", "Expand-Archive -Path '%s' -DestinationPath '%s' -Force" % [current_download['location'].replace("/", "\\").replace("'", "''"), OS.get_user_data_dir().path_join("dungeonfy\\dfysp-main\\mappacks").replace("'", "''")]])
	else:
		OS.execute("unzip", ["-o", current_download['location'], "-d", OS.get_user_data_dir().path_join("dungeonfy/dfysp-main/mappacks")])
	if DirAccess.dir_exists_absolute(map_download_path.path_join("ul_void/playerdata")):
		rmdir(map_download_path.path_join("ul_void/playerdata"))
	DirAccess.rename_absolute(OS.get_user_data_dir().path_join("dungeonfy/dfysp-main/ul_void/playerdata"), map_download_path.path_join("ul_void/playerdata"))
	print("File downloaded and saved to:", current_download["location"])
	current_download = {}
	for i in range($ui/ItemList.get_item_count()):
		$ui/ItemList.set_item_disabled(i, false)
	_populate_item_list()


# steal a function from a random Godot plugin 
func rmdir(directory: String) -> void:
	for file in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	for dir in DirAccess.get_directories_at(directory):
		rmdir(directory.path_join(dir))
	DirAccess.remove_absolute(directory)


func _on_skript_map_downloader_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		print("Download failed, code:", response_code)
		skript_download = {}
		return
	var dir_path = skript_download['location'].get_base_dir()
	var dir = DirAccess.open(dir_path)
	if dir == null:
		var err = DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			print("Failed to create directory:", dir_path)
			skript_download = {}
			return

	var file = FileAccess.open(skript_download["location"], FileAccess.WRITE)
	if file == null:
		print("Failed to open file for writing:", skript_download["location"])
		skript_download = {}
		return
	
	file.store_buffer(body)
	file.close()
	print("File downloaded and saved to:", skript_download["location"])
	skript_download = {}
