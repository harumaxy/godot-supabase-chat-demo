class_name RoomItem
extends Control

signal selected(id, name)
signal deselected(id, name)


var id : int
var room_name : String
var created_at : String
var is_header : bool = false

var selected = false

func select():
  if !is_header:
    selected = true
    self.modulate = Color.aquamarine
    emit_signal("selected", id, room_name)

func deselect():
  if !is_header:
    selected = false
    self.modulate = Color.white
    emit_signal("deselected", id, room_name)

func split_datetime_format(datetime: String):
  var date = datetime.split("T")[0]
  var time = datetime.split("T")[1].split(".")[0]
  return date + "_" + time

func set_props(props: Dictionary):
  id = props.id
  room_name = props.name
  created_at = props.created_at
  $Id.text = str(id)
  $RoomName.text = room_name
  $CreatedAt.text = split_datetime_format(created_at)

func set_as_header():
  $Id.text = "Id"
  $RoomName.text = "Name"
  $CreatedAt.text = "CreatedAt"
  self.is_header = true


func _on_Control_gui_input(event):
  if event is InputEventMouseButton and event.pressed:
    select() if !selected else deselect()

