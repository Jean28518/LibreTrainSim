extends CanvasLayer

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
################################################################################

onready var player = get_parent()

func _ready():
	$MobileHUD.visible = Root.mobile_version
	if Root.mobile_version:
		$IngameInformation/Next.rect_position.y += 100
		$TextBox/RichTextLabel.hide()
		$TextBox/RichTextLabelMobile.show()
		$TextBox/Ok.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))

	
func _process(delta):
	if $TextBox.visible:
		if Input.is_action_just_pressed("ui_accept"):
			_on_OkTextBox_pressed()
	
	check_escape(delta)
	
	check_trainInfoAbove(delta)
	
	check_nextTable(delta)
	
	check_trainInfo(delta)
	
	if sending:
		messaget += delta
		if messaget > 4:
			$Message.play("FadeOut")
			sending = false
	$FPS.text = String(Engine.get_frames_per_second())
	
#	$IngameInformation/Speed/Speed.text = "Speed: " + String(int(Math.speedToKmH((get_parent().speed)))) + " km/h"
#	$IngameInformation/Speed/CurrentLimit.text = "Speed Limit: " + String(get_parent().currentSpeedLimit) + " km/h"
	
#	var alpha = (Math.speedToKmH(get_parent().speed)/get_parent().currentSpeedLimit)*2 -1
#	if alpha < 0:
#		alpha = 0
#	$IngameInformation/Speed/CurrentLimit.modulate.a = alpha
	
	if $Pause.visible or $TextBox.visible or $MobileHUD/Pause.visible:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_tree().paused = false
		
	update_nextTable(delta)
	
	$IngameInformation/TrainInfo/Screen1.update_display(Math.speedToKmH(player.speed), player.technicalSoll, player.doorLeft, player.doorRight, player.doorsClosing, player.enforcedBreaking, player.sifa, player.automaticDriving, player.currentSpeedLimit, player.engine, player.reverser)
		


var sending = false
var messaget = 0
func send_Message(text):
	$MarginContainer/Label.text = text
	$Message.play("FadeIn")
	$Bling.play()
	messaget = 0
	sending = true
	
func check_escape(delta):
	if Input.is_action_just_pressed("Escape"):
		get_tree().paused = true
		$Pause.visible = true


func _on_Back_pressed():
	get_tree().paused = false
	$Pause.visible = false


func _on_Quit_pressed():
	get_tree().quit()
	

func show_textbox_message(string):
	$TextBox/RichTextLabel.text = string
	$TextBox/RichTextLabelMobile.text = string
	get_tree().paused = true
	$TextBox.visible = true
	


func _on_OkTextBox_pressed():
	get_tree().paused = false
	$TextBox.visible = false
	if $Black.visible:
		$Black/AnimationPlayer.play("FadeOut")
	
var modulation = 0
func check_trainInfo(delta):
	if Input.is_action_just_pressed("trainInfo"):
		modulation += 0.5
		if modulation > 1: 
			modulation = 0
		$IngameInformation/TrainInfo.modulate = Color( 1, 1, 1, modulation)

func check_nextTable(delta):
	if Input.is_action_just_pressed("nextTable"):
		$IngameInformation/Next.visible = !$IngameInformation/Next.visible



func _on_QuitMenu_pressed():
	get_tree().paused = false
	jAudioManager.clear_all_sounds()
	jEssentials.remove_all_pending_delayed_calls()
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")
	pass # Replace with function body.

func check_trainInfoAbove(delta):
	if Input.is_action_just_pressed("trainInfoAbove"):
		$IngameInformation/TrainInfoAbove.visible = not $IngameInformation/TrainInfoAbove.visible
	if $IngameInformation/TrainInfoAbove.visible:
		$IngameInformation/TrainInfoAbove.update_info(get_parent())

var redSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/RedSignal.png")
var greenSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/GreenSignal.png")
var orangeSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/OrangeSignal.png")
func update_nextTable(delta):
	## Update Next Signal:
	$IngameInformation/Next/GridContainer/DistanceToSignal.text = Math.distance2String(player.distanceToNextSignal)
	if player.nextSignal != null:
		match player.nextSignal.status:
			0:
				$IngameInformation/Next/GridContainer/Signal.texture = redSignal
			1:
				if player.nextSignal.orange:
					$IngameInformation/Next/GridContainer/Signal.texture = orangeSignal
				else:
					$IngameInformation/Next/GridContainer/Signal.texture = greenSignal
			
				
	
	## Update next Speedlimit
	
	if player.nextSpeedLimitNode != null:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = Math.distance2String(player.distanceToNextSpeedLimit)
		$IngameInformation/Next/GridContainer/SpeedLimit.text = String(player.nextSpeedLimitNode.speed) + " km/h"
	else:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = "-"
	
	## Update Next Station 
	var stations = player.stations
	if stations.passed.size() == 0 or (player.endStation and player.isInStation):
		$IngameInformation/Next/GridContainer/Arrival.text = "-"
		$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
	else:
		if player.isInStation:
			for i in range (0, stations.passed.size()):
				if stations.passed[i]: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time2String(player.stations["departureTime"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
				
				break
		else:
			for i in range (0, stations.passed.size()):
				
				if stations.passed[i] or stations.nodeName[i] != player.nextStation: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time2String(player.stations["arrivalTime"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = Math.distance2String(player.distanceToNextStation)
				
				break
				

	

