tool
extends Spatial

## Documentation Notes:
# Please be aware of the parallel Mode:
# If 'parallelRail != ""' All local train Settings apart from 'railType' and 'distanceToParallelRail' are deprecated. The Rail gets the rest information from parallel rail.


export (String) var railTypePath = "res://Resources/Basic/RailTypes/Default.tscn"
export (float) var length
export (float) var radius
export (float) var buildDistance = 1
export (int) var visibleSegments
# warning-ignore:unused_class_variable
export (bool) var update setget _update

export (bool) var manualMoving = false
var fixedTransform

var trackObjects = []


var MAX_LENGTH = 1000

export (float) var startrot
export (float) var endrot
export (Vector3) var startpos
export (Vector3) var endpos

export (float) var othersDistance = -4.5
export (float) var otherRadius
export (float) var otherLength
# warning-ignore:unused_class_variable
export (bool) var calculate setget calcParallelRail

export (float) var InShift = 2.25
# warning-ignore:unused_class_variable
export (float) var InRadius = 400
export (float) var Outlength
# warning-ignore:unused_class_variable
export (bool) var calculateShift setget calcShift

## Steep
export (float) var startSlope = 0 # Degree
export (float) var endSlope = 0 # Degree

export (float) var startTend = 0
export (float) var tend1Pos = -1
export (float) var tend1 = 0
export (float) var tend2Pos = 0
export (float) var tend2 = 0
export (float) var endTend
export (float) var automaticTendency = false

export (String) var parallelRail = ""
export (float) var distanceToParallelRail = 0

export (bool) var overheadLine = false
var overheadLineHeight1 = 5.3
var overheadLineHeight2 = 6.85
var overheadLineThinkness = 0.02
var line2HeightChangingFactor = 0.9
var overheadLineBuilded = false

var parRail

var railTypeNode 



onready var world = find_parent("World")
onready var buildings = world.get_node("Buildings")


var attachedSignals = []

# Called when the node enters the scene tree for the first time.
func _ready():
	manualMoving = false
	_update(false)
	if not Engine.is_editor_hint():
		$Beginning.queue_free()
		$Ending.queue_free()
	pass # Replace with function body.

var EditorUpdateTimer = 0
func _process(delta):
	checkVisualInstance()
	if visible and not overheadLineBuilded:
		updateOverheadLine()
		overheadLineBuilded = true
	if Engine.is_editor_hint():
		EditorUpdateTimer += delta
		if EditorUpdateTimer < 0.25:
			return
		EditorUpdateTimer = 0
		## Disable moving in editor, if manual Moving is false:
#		print("checking transofrmation....")
		if fixedTransform == null:
			fixedTransform = transform
		if not manualMoving:
			transform = fixedTransform
		else:
			fixedTransform = transform
		if name.match(" "):
			name = name.replace(" ", "_")
		## Move Buildings to the Buildings Node
		for child in get_children():
			if not child.owner == self:
				remove_child(child)
				buildings.add_child(child)
				child.owner = world

func _update(newvar):
	if ResourceLoader.exists(railTypePath):
		railTypeNode = load(railTypePath).instance()
	if railTypeNode == null:
		railTypeNode = preload("res://Resources/Basic/RailTypes/Default.tscn").instance()
	buildDistance = railTypeNode.buildDistance
	overheadLineHeight1 = railTypeNode.overheadLineHeight1
	overheadLineHeight2 = railTypeNode.overheadLineHeight2
	overheadLineThinkness = railTypeNode.overheadLineThinkness
	line2HeightChangingFactor = railTypeNode.line2HeightChangingFactor
#	updateOverheadLine()
	world = find_parent("World")
	if world == null: return
	if parallelRail == "":
		updateAutomaticTendency()
	if parallelRail != "":
		parRail = world.get_node("Rails").get_node(parallelRail)
		if parRail == null:
			print("Cant find parallel rail. Updating Rail canceled..")
			return

		if parRail.radius == 0:
			radius = 0
			length = parRail.length
		else:
			radius = parRail.radius + distanceToParallelRail
			length = parRail.length * ((radius)/(parRail.radius))
		translation = parRail.get_shifted_pos_at_RailDistance(0, distanceToParallelRail) ## Hier verstehe ich das minus nicht
		rotation_degrees.y = parRail.rotation_degrees.y
		fixedTransform = transform
	

	if length > MAX_LENGTH:
		length = MAX_LENGTH
		print(self.name + ": The max length is " + String(MAX_LENGTH) + ". Shrinking the length to maximal length.")
	update_positions_and_rotations()
	visibleSegments = length / buildDistance +1

	buildRail()
	updateOverheadLine()

	if Engine.is_editor_hint():
		$Ending.translation = get_local_transform_at_rail_distance(length).origin


func checkVisualInstance():
	if visible:
		if get_node_or_null("MultiMeshInstance") == null:
			load_visible_Instance()
	else:
		if get_node_or_null("MultiMeshInstance") != null:
			unload_visible_Instance()

func get_track_object(track_object_name : String): # (Searches for the description of track objects
	for track_object in trackObjects:
		if track_object.description == track_object_name:
			return track_object
	return null

func buildRail():
	if get_node_or_null("MultiMeshInstance") == null:
		return
	get_node("MultiMeshInstance").set_multimesh(get_node("MultiMeshInstance").multimesh.duplicate(false))
	var multimesh = get_node("MultiMeshInstance").multimesh
	multimesh.mesh = railTypeNode.get_child(0).mesh.duplicate(true)
	for i in range(railTypeNode.get_child(0).get_surface_material_count()):
		multimesh.mesh.surface_set_material(i, railTypeNode.get_child(0).get_surface_material(i))

	multimesh.instance_count = length / buildDistance + 1
	multimesh.visible_instance_count = visibleSegments
	var distance = 0
	for i in range(0, multimesh.visible_instance_count):
		multimesh.set_instance_transform(i, get_local_transform_at_rail_distance(distance))
		distance += buildDistance

func get_transform_at_rail_distance(distance):
	var locTransform = get_local_transform_at_rail_distance(distance)
	return Transform(locTransform.basis.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) ,translation + locTransform.origin.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)))
func get_local_transform_at_rail_distance(distance):
	if parallelRail == "":
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(get_tend_at_rail_distance(distance))).rotated(Vector3(0,0,1), deg2rad(get_heightRot(distance))).rotated(Vector3(0,1,0), deg2rad(circle_get_deg(radius, distance))), get_local_pos_at_RailDistance(distance) )
	else:
		var parDistance = distance/length * parRail.length
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(parRail.get_tend_at_rail_distance(parDistance))).rotated(Vector3(0,0,1), deg2rad(parRail.get_heightRot(parDistance))).rotated(Vector3(0,1,0), deg2rad(parRail.circle_get_deg(parRail.radius, parDistance))), parRail.get_shifted_local_pos_at_RailDistance(parDistance, distanceToParallelRail)+ ((parRail.startpos-startpos).rotated(Vector3(0,1,0), deg2rad(-rotation_degrees.y))))#+(-translation+parRail.translation).rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) )

func speedToKmH(speed):
	return speed*3.6

# warning-ignore:unused_argument
func calcParallelRail(newvar):
	_update(true)
	if radius == 0:
		otherRadius = 0
		otherLength = length
		return
	var U = 2.0* PI * radius
	otherRadius = radius + othersDistance
	if U == 0:
		otherLength = length
	else:
		otherLength = (length / U) * (2.0 * PI * otherRadius)

# warning-ignore:unused_argument
func calcShift(newvar):
	_update(true)
	if radius == 0:
		Outlength = length
		return
	var angle = rad2deg(acos((radius-InShift)/radius))

	if String(angle) == "nan":
		Outlength = length
		return
	Outlength = 2.0 * PI * radius * angle / 360.0

func register_signal(name, distance):
	print("Signal " + name + " registered at rail.")
	attachedSignals.append({"name": name, "distance": distance})

func get_pos_at_RailDistance(distance):
	var circlePos = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y)).rotated(Vector3(0,1,0), deg2rad(startrot))+startpos

func get_local_pos_at_RailDistance(distance):
	var circlePos = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y))

func get_deg_at_RailDistance(distance):
	return circle_get_deg(radius, distance) + startrot
func get_local_deg_at_RailDistance(distance):
	return circle_get_deg(radius, distance)

func get_shifted_pos_at_RailDistance(distance, shift):
	return get_shifted_local_pos_at_RailDistance(distance, shift).rotated(Vector3(0,1,0),deg2rad(rotation_degrees.y)) + startpos
#	var railpos = get_pos_at_RailDistance(distance)
#	return railpos + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), deg2rad(get_deg_at_RailDistance(distance)+90))*shift)

func get_shifted_local_pos_at_RailDistance(distance, shift):
	var newRadius = radius + shift
	if radius == 0:
		newRadius = 0
	var newDistance = distance
	if radius != 0:
		newDistance = distance * ((newRadius)/(radius))
	var circlePos = circle_get_pos(newRadius, newDistance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y+shift))

func unload_visible_Instance():
	print("Unloading visible Instance for Rail "+name)
	visible = false
	$MultiMeshInstance.queue_free()

func load_visible_Instance():
	visible = true
	if get_node_or_null("MultiMeshInstance") != null: return
	print("Loading visible Instance for Rail "+name)
	var multimeshI = MultiMeshInstance.new()#
	multimeshI.multimesh = MultiMesh.new().duplicate(true)
	multimeshI.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimeshI.name = "MultiMeshInstance"
	add_child(multimeshI)
	multimeshI.owner = self
	_update(true)
	print("Loading of visual instance complete")

################################################### Easy Circle Functions:
func circle_get_pos(radius, distance):
	if radius == 0:
		return Vector2(distance, 0)
	## Calculate: Coordinate:
	var degree = circle_get_deg(radius, distance)
	var middleOfCircle = Vector2(0, radius)
	var a = cos(deg2rad(degree)) * radius
	var b = sin(deg2rad(degree)) * radius
	return middleOfCircle + Vector2(b, -a)  ## See HowACircleIsCalculated.pdf in github repository


func circle_get_deg(radius, distance):
	if radius == 0:
		return 0

	# Calculate needed degree:
	var extend = radius * 2.0 * PI
	return float(distance / extend * 360)

#### Height Functions:
func get_height(distance):
	if parRail != null:
		var newRadius = radius - distanceToParallelRail
		if radius == 0:
			newRadius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * ((newRadius)/(radius))
		return parRail.get_height(newDistance)
	var startGradient = rad2deg(atan(startSlope/100))
	var endGradient = rad2deg(atan(endSlope/100))

	var basicHeight = float(tan(deg2rad(startGradient)) * distance)
	if endGradient - startGradient == 0:
		return basicHeight
	var heightRadius = (360*length)/(2*PI*(endGradient - startGradient))
	return circle_get_pos(heightRadius, distance).y + basicHeight

func get_heightRot(distance): ## Get Slope
	if parRail != null:
		var newRadius = radius - distanceToParallelRail
		if radius == 0:
			newRadius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * ((newRadius)/(radius))
		return parRail.get_heightRot(newDistance)
	var startGradient = rad2deg(atan(startSlope/100))
	var endGradient = rad2deg(atan(endSlope/100))

	var basicRot = startGradient
	if endGradient - startGradient == 0:
		return basicRot
	var heightRadius = (360*length)/(2*PI*(endGradient - startGradient))
	return circle_get_deg(heightRadius, distance) + basicRot


func get_tend_at_rail_distance(distance):
	if parRail != null:
		var newRadius = radius - distanceToParallelRail
		if radius == 0:
			newRadius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * ((newRadius)/(radius))
		return parRail.get_tend_at_rail_distance(newDistance)
	if distance >= tend1Pos and distance < tend2Pos:
		return -(tend1 + (tend2-tend1) * (distance - tend1Pos)/(tend2Pos - tend1Pos))
	if distance <= tend1Pos:
		return -(startTend + (tend1-startTend) * (distance)/(tend1Pos))
	if tend2Pos > 0 and distance >= tend2Pos:
		return -(tend2 + (endTend-tend2) * (distance -tend2Pos)/(length-tend2Pos))
	return -(startTend + (endTend-startTend) * (distance/length))
	return 0

func get_tendSlopeData():
	var d = {}
	var s = self
	d.startSlope = s.startSlope
	d.endSlope = s.endSlope
	d.startTend = s.startTend
	d.endTend = s.endTend
	d.tend1Pos = s.tend1Pos
	d.tend1 = s.tend1
	d.tend2Pos = s.tend2Pos
	d.tend2 = s.tend2
	d.automaticTendency = s.automaticTendency
	return d

func set_tendSlopeData(data):
	var d = self
	var s = data
	d.startSlope = s.startSlope
	d.endSlope = s.endSlope
	d.startTend = s.startTend
	d.endTend = s.endTend
	d.tend1Pos = s.tend1Pos
	d.tend1 = s.tend1
	d.tend2Pos = s.tend2Pos
	d.tend2 = s.tend2
	d.automaticTendency = s.automaticTendency

var automaticPointDistance = 50
func updateAutomaticTendency():
	if automaticTendency and radius != 0 and length > 3*automaticPointDistance:
		tend1Pos = automaticPointDistance
		tend2Pos = length -automaticPointDistance
		var tendency = 300/radius * 5
		tend1 = tendency
		tend2 = tendency
	elif automaticTendency and radius == 0:
		tend1 = 0
		tend2 = 0





###############################################################################
## Overhad Line
var vertices
var indices
func updateOverheadLine():
	if get_node_or_null("OverheadLine") != null:
		$OverheadLine.free()
	
	if not overheadLine: 
		return
		
	var overheadLineMeshInstance = MeshInstance.new()
	overheadLineMeshInstance.name = "OverheadLine"
	self.add_child(overheadLineMeshInstance)
	overheadLineMeshInstance.owner = self
	
	vertices = PoolVector3Array()
	indices = PoolIntArray()

	## Get Pole Points:
	var polePositions = []
	polePositions.append(0)
	
	for trackObject in trackObjects:
		if trackObject == null:
			continue
		print(trackObject.description)
		if trackObject.description.begins_with("Pole"):
			var pos = 0
			if trackObject.onRailPosition == 0:
				pos += trackObject.distanceLength
			while pos <= trackObject.length:
				polePositions.append(pos + trackObject.onRailPosition)
				pos += trackObject.distanceLength
			if not trackObject.placeLast and polePositions.size() > 1:
				polePositions.remove(polePositions.size()-1)
			## Maybe here comes a break in. (If we only want to search for one trackobkject which begins with "pole"
	polePositions.append(length)
	polePositions = jEssentials.remove_duplicates(polePositions)
	for i in range (polePositions.size()-2):
		buildOverheadLineSegment(polePositions[i], polePositions[i+1])
		
	if polePositions[polePositions.size()-2] != length:
		buildOverheadLineSegment(polePositions[polePositions.size()-2], length)
		
		
	
	var mesh = ArrayMesh.new()

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, preload("res://Resources/Basic/Materials/Black_Plastic.tres"))
	$OverheadLine.mesh = mesh

func buildOverheadLineSegment(start, end):
	var startPos = get_local_pos_at_RailDistance(start)+Vector3(0,overheadLineHeight1,0)
	var endPos = get_local_pos_at_RailDistance(end)+Vector3(0,overheadLineHeight1,0)
	var directVector = (endPos-startPos).normalized()
	var directDistance = startPos.distance_to(endPos)
	
	create3DLine(get_local_pos_at_RailDistance(start)+Vector3(0,overheadLineHeight1,0), get_local_pos_at_RailDistance(end)+Vector3(0,overheadLineHeight1,0), overheadLineThinkness)
	
	var segments = int(directDistance/10)
	if segments == 0:
		segments = 1
	var segmentDistance = directDistance/segments
	var currentPos1 = startPos
	var currentPos2 = startPos + directVector*segmentDistance
	for i in range(segments):
		create3DLine(currentPos1+Vector3(0,overheadLineHeight2-overheadLineHeight1-sin(i*segmentDistance/directDistance*PI)*line2HeightChangingFactor,0), currentPos2+Vector3(0,overheadLineHeight2-overheadLineHeight1-sin((i+1)*segmentDistance/directDistance*PI)*line2HeightChangingFactor,0), overheadLineThinkness)

		var lineHeight2ChangingAtHalf = sin((i+1)*segmentDistance/directDistance*PI)*line2HeightChangingFactor - (sin((i+1)*segmentDistance/directDistance*PI)*line2HeightChangingFactor - sin(i*segmentDistance/directDistance*PI)*line2HeightChangingFactor)/2.0
		create3DLineUp(currentPos1+directVector*segmentDistance/2, currentPos1+directVector*segmentDistance/2+Vector3(0,overheadLineHeight2-overheadLineHeight1-lineHeight2ChangingAtHalf,0), overheadLineThinkness)
		currentPos1+=directVector*segmentDistance
		currentPos2+=directVector*segmentDistance
	return {"vertices" : vertices, "indices" : indices}
	
	
	

func create3DLine(start, end, thinkness):
	var x = vertices.size()
	vertices.push_back(start + Vector3(0,thinkness,0))
	vertices.push_back(start + Vector3(0,0,-thinkness))
	vertices.push_back(start + Vector3(0,-thinkness,0))
	vertices.push_back(start + Vector3(0,0,thinkness))
	
	vertices.push_back(end + Vector3(0,thinkness,0))
	vertices.push_back(end + Vector3(0,0,-thinkness))
	vertices.push_back(end + Vector3(0,-thinkness,0))
	vertices.push_back(end + Vector3(0,0,thinkness))
	
	var indices_array = PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)
	
func create3DLineUp(start, end, thinkness):
	var x = vertices.size()
	vertices.push_back(start + Vector3(thinkness,0,0))
	vertices.push_back(start + Vector3(0,0,-thinkness))
	vertices.push_back(start + Vector3(-thinkness,0,0))
	vertices.push_back(start + Vector3(0,0,thinkness))
	
	vertices.push_back(end + Vector3(thinkness,0,0))
	vertices.push_back(end + Vector3(0,0,-thinkness))
	vertices.push_back(end + Vector3(-thinkness,0,0))
	vertices.push_back(end + Vector3(0,0,thinkness))
	
	var indices_array = PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)

###############################################################################
func update_positions_and_rotations():
	startpos = self.get_translation()
	startrot = self.rotation_degrees.y
	endrot = get_deg_at_RailDistance(length)
	endpos = get_pos_at_RailDistance(length)

export var isSwitchPart = ["", ""]
# 0: is Rail at beginning part of switch? 1: is the rail at end part of switch if not 
# It is saved the name of the other rail which is part of switch
func update_is_switch_part():
	isSwitchPart = ["", ""]
	var foundRailsAtBeginning = []
	var foundRailsAtEnding = []
	for rail in world.get_node("Rails").get_children():
		if rail == self:
			continue
		# Check for beginning
		if startpos.distance_to(rail.startpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.startrot)) < 1:
			foundRailsAtBeginning.append(rail.name)
		elif startpos.distance_to(rail.endpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.endrot+180)) < 1:
			foundRailsAtBeginning.append(rail.name)
		#check for ending
		if endpos.distance_to(rail.startpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.startrot+180))) < 1:
			foundRailsAtEnding.append(rail.name)
		elif endpos.distance_to(rail.endpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.endrot))) < 1:
			foundRailsAtEnding.append(rail.name)
			
	if foundRailsAtBeginning.size() > 0:
		isSwitchPart[0] = foundRailsAtBeginning[0]
		pass
	
	if foundRailsAtEnding.size() > 0:
		isSwitchPart[1] = foundRailsAtEnding[0]
		pass


var _connected_rails_at_beginning = [] # Array of rail nodes
var _connected_rails_at_ending = [] # Array of rail nodes
# The code of update_connections and update_is_switch_part can't be summarized, because 
# we are searching for different rails in these functions. (Rotation of searched 
# rails differs by 180 degrees)

# This function should be called before get_connected_rails_at_beginning() 
# or get_connected_rails_at_ending once.
func update_connections():
	print("HUHU")
	_connected_rails_at_beginning = []
	_connected_rails_at_ending = []
	for rail in world.get_node("Rails").get_children():
		if rail == self:
			continue
		# Check for beginning
		if startpos.distance_to(rail.startpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.startrot+180)) < 1:
			_connected_rails_at_beginning.append(rail)
		elif startpos.distance_to(rail.endpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.endrot)) < 1:
			_connected_rails_at_beginning.append(rail)
		#check for ending
		if endpos.distance_to(rail.startpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.startrot))) < 1:
			_connected_rails_at_ending.append(rail)
		elif endpos.distance_to(rail.endpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.endrot+180))) < 1:
			_connected_rails_at_ending.append(rail)

# Returns array of rail nodes
func get_connected_rails_at_beginning():
	return _connected_rails_at_beginning

# Returns array of rail nodes
func get_connected_rails_at_ending():
	return _connected_rails_at_ending

