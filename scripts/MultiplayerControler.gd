extends Control

@export var ADDRESS = "127.0.0.1"
@export var PORT = 8010
var peer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(player_connected_to_server)
	multiplayer.connection_failed.connect(player_failed_to_connect)
	if "--server" in OS.get_cmdline_args():
		host_game()

# Called on the server and client
func player_connected(id) -> void:
	print("Player " + str(id) + " connected")
	
# Called on the server and client
func player_disconnected(id) -> void:
	print("Player " + str(id) + " has left ")
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
	
# Called only from client
func player_connected_to_server() -> void:
	print("Player has connected to the server")
	send_player_info.rpc_id(1, $Panel/PlayerName.text, multiplayer.get_unique_id())
	
# Called only from client
func player_failed_to_connect(id) -> void:
	return print("Player " + str(id) + " failed to connect")

# ---------------------- Menu -----------------------
func _on_host_button_down() -> void:
	host_game()

func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ADDRESS, PORT)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func _on_start_game_button_down() -> void:
	start_game.rpc()
# ----------------------------------------------------

func host_game() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	if error != OK:
		print("cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	send_player_info($Panel/PlayerName.text, multiplayer.get_unique_id())
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")
	

@rpc("any_peer", "call_local" )
func start_game() -> void:
	var scene = load("res://scenes/testScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	
@rpc("any_peer")
func send_player_info(name, id) -> void:
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"id": id,
			"name": name,
			"score": 0
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			send_player_info.rpc(GameManager.Players[i].name, i)
