extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var player = get_parent()

var ready = false
# Called when the node enters the scene tree for the first time.
func ready():
	if player.ai: return
	get_node("../Cabin/DisplayMiddle").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = get_node("../Cabin/DisplayMiddle").get_texture()
	get_node("../Cabin/ScreenMiddle").material_override.emission_texture = texture
	get_node("../Cabin/DisplayMiddle/Display").blinkingTimer = player.get_node("HUD").get_node("IngameInformation/TrainInfo/Screen1").blinkingTimer
	
	get_node("../Cabin/DisplayLeft").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayLeft").get_texture()
	get_node("../Cabin/ScreenLeft").material_override.emission_texture = texture
	
	get_node("../Cabin/DisplayRight").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayRight").get_texture()
	get_node("../Cabin/ScreenRight").material_override.emission_texture = texture
	
	get_node("../Cabin/DisplayReverser").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayReverser").get_texture()
	get_node("../Cabin/ScreenReverser").material_override.emission_texture = texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player.ai: return
	if not ready: 
		ready = true
		ready()
	get_node("../Cabin/DisplayMiddle/Display").update_display(Math.speedToKmH(player.speed), player.technicalSoll, player.doorLeft, player.doorRight, player.doorsClosing, player.enforcedBreaking, player.sifa, player.automaticDriving, player.currentSpeedLimit, player.engine, player.reverser)

	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_time(player.time)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_voltage(player.voltage)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_command(player.command)
	
	var stations = player.stations
	get_node("../Cabin/DisplayRight/ScreenRight").update_display(stations["arrivalTime"], stations["departureTime"], stations["stationName"], stations["stopType"], stations["passed"], player.isInStation)
	
	update_Combi_Roll(player.soll_command, get_node("../Cabin/BrakeRoll"))
	update_reverser(player.reverser, get_node("../Cabin/Reverser"))


func update_reverser(command, node):
	match command:
		ReverserState.FORWARD:
			node.rotation_degrees.y = -120
		ReverserState.NEUTRAL:
			node.rotation_degrees.y = -90
		ReverserState.REVERSE:
			node.rotation_degrees.y = -60


func update_Combi_Roll(command, node):
	node.rotation_degrees.z = 45*command+1

func update_Brake_Roll(command, node):
	var rotation
	if command > 0:
		rotation = 45
	else:
		rotation = 45 + command*90
	node.rotation_degrees.z = rotation

func update_Acc_Roll(command, node):
	var rotation
	if command < 0:
		rotation = 45
	else:
		rotation = 45 - command*90
	node.rotation_degrees.z = rotation
