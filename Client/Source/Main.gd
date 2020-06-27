extends Control


func _ready():
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_success")
	network.connect("game_ended", self, "_on_game_ended")
	network.connect("game_error", self, "_on_game_error")
	
#	for ip in IP.get_local_addresses():
#		if str(ip).split(".")[0] == "192":
#			$IP/Value.text = str(ip)
	
	if OS.has_environment("USERNAME"):
		$Name/Value.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Name/Value.text = desktop_path[desktop_path.size()-2]


func _on_quit_button_pressed():
	get_tree().quit()


func _on_join_button_pressed():
	var player_name = $Name/Value.text
	if $Name/Value.text == "":
		$Info.text = "Invalid name"
		return
	
	var ip = $IP/Value.text
	if !ip.is_valid_ip_address():
		$Info.text = "Invalid IP!"
		return
	
	var port = $Port/Value.value
	
	disable_ui("Connecting to the server...")
	network.join_game(ip, port, player_name)


func disable_ui(message=""):
	$Buttons/join_button.disabled = true
	$Name/Value.editable = false
	$IP/Value.editable = false
	$Port/Value.editable = false
	$Info.text = message


func enable_ui(message="", connected=false):
	$Buttons/join_button.disabled = false
	$Name/Value.editable = true
	$IP/Value.editable = true
	$Port/Value.editable = true
	$Info.text = message
	if connected:
		return
	yield(get_tree().create_timer(3.0), "timeout")
	$Info.text = ""


func _on_game_error(error_text):
	enable_ui(error_text)


func _on_game_ended():
	show()
	enable_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_connection_failed():
	enable_ui("connection failed")


func _on_connection_success():
	enable_ui("connected!", true)
