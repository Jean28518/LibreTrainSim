extends Control

func _ready():
	$"VBoxContainer/Forward".set_text(TranslationServer.translate("FORWARD"))
	$"VBoxContainer/Neutral".set_text(TranslationServer.translate("NEUTRAL"))
	$"VBoxContainer/Reverse".set_text(TranslationServer.translate("REVERSE"))
