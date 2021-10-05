extends Control

onready var line_edit = $HBoxContainer/CenterContainer/HBoxContainer/LineEdit
onready var send_button = $HBoxContainer/CenterContainer/HBoxContainer/SendButton
onready var chat_messages = $HBoxContainer/VBox/TextEdit


var room_info : Dictionary
var channel : RealtimeChannel

func _ready():
  print(room_info)
  print(GlobalState.login_info.user)
  # Join Room
  if GlobalState.chat_room_id == null: return
  var room_info_query = SupabaseQuery.new().from("rooms").select().In("id", [GlobalState.chat_room_id])
  var result: DatabaseTask = yield(Supabase.database.query(room_info_query), "completed")
  if result.error:
    print(result.error)
    return
  room_info = result.data[0]
  $HBoxContainer/VBox/RoomName.text = "id:" + str(room_info.id) + "   " +  room_info.name

  # Get All Room chat_messages
  var all_messages_query = SupabaseQuery.new().from("chat_messages").select().In("room_id", [GlobalState.chat_room_id])
  var result2: DatabaseTask = yield(Supabase.database.query(all_messages_query), "completed")
  if result2.error:
    print(result2.error)
    return
  for msg in result2.data:
    chat_messages.text += msg.message + "\n"

  # Listen Realtime Message Post
  var client = Supabase.realtime.client()
  var connect_result = client.connect_client()
  if connect_result != OK:
    print("realtime client error")
  else:
    # Websocket Client 接続に成功してからじゃないと channel を取得しようとしてもうまく行かない
    client.connect("error", self, "_on_realtime_client_error")
    channel = client.channel("public", "chat_messages", "room_id=eq.{room_id}".format({room_id=GlobalState.chat_room_id}))
    channel.connect("insert", self, "_on_message")
    channel.subscribe()



func _on_realtime_client_error(err):
  print(err)

func _on_message(new_record, channel):
  print(new_record.message)
  chat_messages.text += new_record.message + "\n"
  pass




func _on_SendButton_pressed():
  var post_message_query = SupabaseQuery.new().from("chat_messages").insert([
    {
      room_id=GlobalState.chat_room_id,
      user_id=GlobalState.login_info.user.id,
      message=line_edit.text
    }
  ])
  var result: DatabaseTask = yield(Supabase.database.query(post_message_query), "completed")
  if result.error:
    print(result.error)
    return
  line_edit.text = ""
