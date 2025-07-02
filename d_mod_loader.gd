extends Window

var skripts_dir_url = "https://dungeonfy-programmers.github.io/Bootfy-Skripts-Repository/list.json"
var download_path = OS.get_data_dir() + "/bootfy/dungeonfy/dfysp-main/plugins/Skript/scripts/bootfy/"

var folder_queue: Array = []
var download_queue: Array = []
var skript_info: Dictionary = {}

var current_download: Dictionary = {}


func _ready() -> void:
	$SkriptRepo.request_completed.connect(_on_request_completed)
	$SkriptRepo.request(skripts_dir_url)

func _populate_item_list(filter=null):
	$ui/ItemList.clear()
	$ui/InstalledList.clear()
	var installed = []
	
	var files = get_all_files_in_dir(download_path)
			
	
	if filter == null:
		for file in files:
			if str(file).ends_with('.sk'):
				$ui/InstalledList.add_item(str(file))
				installed.append(str(file).split('.')[0])
		for key in skript_info.keys():
			$ui/ItemList.add_item(key + ": " + skript_info[key]['description'])
			if key in installed:
				$ui/ItemList.set_item_custom_bg_color($ui/ItemList.item_count -1, Color('#00af6e55'))
	else:
		for file in files:
			if str(file).ends_with('.sk'):
				if str(file).contains(filter):
					$ui/InstalledList.add_item(str(file))
					installed.append(str(file).split('.')[0])
		for key in skript_info.keys():
			if str(key).contains(filter):
				$ui/ItemList.add_item(key + ": " + skript_info[key]['description'])
				if key in installed:
					$ui/ItemList.set_item_custom_bg_color($ui/ItemList.item_count -1, Color('#00af6e55'))
			
func _on_item_list_item_selected(index: int) -> void:
	var key = $ui/ItemList.get_item_text(index).split(':')[0]
	var url = skript_info[key]['url']
	_download_file(url, download_path + key +".sk")
	
func _on_installed_list_selected(index: int) -> void:
	var file = $ui/InstalledList.get_item_text(index)
	
	var file_path = download_path + file
	var err = DirAccess.remove_absolute(file_path)
	if err == OK:
		print("File deleted successfully.")
	else:
		print("Failed to delete file. Error code:", err)
		
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
	
func _on_skript_downloader_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		print("Download failed, code:", response_code)
		current_download = {}
		return

	var dir_path = current_download['location'].get_base_dir()
	print(dir_path)
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
	
