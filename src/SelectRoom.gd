extends Control

var rooms: Array


const RoomItem := preload("res://scenes/RoomItem.tscn")
const ChatScene := preload("res://scenes/Chat.tscn")

var selected_room_id = null


func async_create_room(name: String) -> DatabaseTask:
  var query = SupabaseQuery.new().from("rooms").insert([{name=name}])
  return Supabase.database.query(query)

func async_list_rooms() -> DatabaseTask:
  var query = SupabaseQuery.new().from("rooms").select()
  return Supabase.database.query(query)


func _ready():
#  print(Supabase.auth._auth) # _auth はログイン時のレスポンスのjsonをそのまま格納。"" のときは未ログインと判定。他の機能もログインしないと使えない(状態をモジュール側で持つ)
  var result: DatabaseTask = yield(async_list_rooms(), "completed")
  if !result.error:
    print(result.data)
    rooms = result.data
    update_rooms_ui(rooms)
  else:
    print("not login yet")

func update_rooms_ui(rooms: Array):
  for item in $VBoxContainer.get_children():
    item.queue_free()
  var header: RoomItem = RoomItem.instance()
  header.set_as_header()
  $VBoxContainer.add_child(header)
  for r in rooms:
    var new: RoomItem = RoomItem.instance()
    new.set_props(r)
    $VBoxContainer.add_child(new)
    new.connect("selected", self, "_on_RoomItem_selected")

func _on_RoomItem_selected(id: int, name: String):
  selected_room_id = id
  $HBoxContainer/JoinButton.disabled = false
  for ri in $VBoxContainer.get_children():
    if ri.id != id:
      ri.deselect()

func _on_RoomItem_deselected(id: int, name: String):
  if id == selected_room_id:
    selected_room_id = null
    $HBoxContainer/JoinButton.disabled = true




func _on_JoinButton_pressed():
  GlobalState.chat_room_id = selected_room_id
  get_tree().change_scene_to(ChatScene)
