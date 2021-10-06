extends Control

var select_room_scene = preload("res://scenes/SelectRoom.tscn")

#func _ready():
#  var result: AuthTask = yield(Supabase.auth.sign_in(user_mail, user_pwd), "completed")
#  if result.user != null:
#    var query = SupabaseQuery.new().from("test-table").select().In("name", ["Test"])
#    var task2: DatabaseTask = yield(Supabase.database.query(query), "completed")
#    if task2.error == null:
#      print(task2.data)
#    else:
#      print("error")
#


onready var email_edit = $VBoxContainer/Email/LineEdit
onready var password_edit = $VBoxContainer/Password/LineEdit

func try_login() -> SupabaseUser:
  if GlobalState.user != null:
    print("already login")
    return null
  var result: AuthTask = yield(Supabase.auth.sign_in(email_edit.text, password_edit.text), "completed")
  if result.user != null:
    GlobalState.user = result.user
    return result.user
  return null

func try_sign_up() -> SupabaseUser:
  var result: AuthTask = yield(Supabase.auth.sign_up(email_edit.text, password_edit.text), "completed")
  if result.user != null:
    GlobalState.user = result.user
    return result.user
  return null

func _on_Button_pressed():
  var login_result = yield(self.try_login(), "completed")
  if !login_result:
    login_result = yield(try_sign_up(), "completed")
  if !login_result:
    print("login failed")
    return
  else:
    get_tree().change_scene_to(select_room_scene)





