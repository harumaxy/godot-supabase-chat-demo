extends Control

var user_mail := "harumaxy@gmail.com"
var user_pwd := "password"

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



func try_login() -> bool:
  if GlobalState.login_info != null:
    print("already login")
    return true
  else:
    var email = $VBoxContainer/Email/LineEdit.text
    var password = $VBoxContainer/Password/LineEdit.text
    var result: AuthTask = yield(Supabase.auth.sign_in(user_mail, user_pwd), "completed")
    if result.user != null:
      GlobalState.login_info = result
      return true
  return false

func try_sign_up() -> bool:
  var email = $VBoxContainer/Email/LineEdit.text
  var password = $VBoxContainer/Password/LineEdit.text
  var result: AuthTask = yield(Supabase.auth.sign_up(user_mail, user_pwd), "completed")
  if result.user != null:
    print("sign_up")
    GlobalState.login_info = result
    return true
  return false

func _on_Button_pressed():
  var login_result = yield(self.try_login(), "completed")
  if login_result == false:
    login_result = yield(try_sign_up(), "completed")

  if login_result == false:
    print("login failed")
    return
  else:
    get_tree().change_scene_to(select_room_scene)





