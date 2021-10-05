class_name SupabaseStorage
extends Node

signal listed_buckets(buckets)
signal got_bucket(details)
signal created_bucket(details)
signal updated_bucket(details)
signal emptied_bucket(details)
signal deleted_bucket(details)
signal error(error)

const _rest_endpoint : String = "/storage/v1/"

var _config : Dictionary
var _header : PoolStringArray = ["Content-type: application/json"]
var _bearer : PoolStringArray = ["Authorization: Bearer %s"]

var _pooled_tasks : Array = []


func _init(config : Dictionary) -> void:
    _config = config
    name = "Storage"

func list_buckets() -> StorageTask:
    _bearer = Supabase.auth._bearer
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "bucket"
    var task : StorageTask = StorageTask.new()
    task._setup(
        task.METHODS.LIST_BUCKETS,
        endpoint,
        _header + _bearer)
    _process_task(task)
    return task


func get_bucket(id : String) -> StorageTask:
    _bearer = Supabase.auth._bearer
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "bucket/" + id
    var task : StorageTask = StorageTask.new()
    task._setup(
        task.METHODS.GET_BUCKET,
        endpoint,
        _header + _bearer)
    _process_task(task)
    return task


func create_bucket(_name : String, id : String, public : bool = false) -> StorageTask:
    _bearer = Supabase.auth._bearer
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "bucket"
    var task : StorageTask = StorageTask.new()
    task._setup(
        task.METHODS.CREATE_BUCKET,
        endpoint,
        _header + _bearer,
        to_json({"name" : _name, id = id, public = public}))
    _process_task(task)
    return task


func update_bucket(id : String, public : bool) -> StorageTask:
    _bearer = Supabase.auth._bearer
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "bucket/" + id
    var task : StorageTask = StorageTask.new()
    task._setup(
        task.METHODS.UPDATE_BUCKET,
        endpoint,
        _header + _bearer,
        to_json({public = public}))
    _process_task(task)
    return task


func empty_bucket(id : String) -> StorageTask:
    _bearer = Supabase.auth._bearer
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "bucket/" + id + "/empty"
    var task : StorageTask = StorageTask.new()
    task._setup(
        task.METHODS.EMPTY_BUCKET,
        endpoint,
        _bearer)
    _process_task(task)
    return task


func delete_bucket(id : String) -> StorageTask:
    _bearer = Supabase.auth._bearer
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "bucket/" + id
    var task : StorageTask = StorageTask.new()
    task._setup(
        task.METHODS.DELETE_BUCKET,
        endpoint,
        _bearer)
    _process_task(task)
    return task


func from(id : String) -> StorageBucket:
    for bucket in get_children():
        if bucket.id == id:
            return bucket
    var storage_bucket : StorageBucket = StorageBucket.new(id, _config)
    add_child(storage_bucket)
    return storage_bucket

# ---

func _process_task(task : StorageTask) -> void:
    var httprequest : HTTPRequest = HTTPRequest.new()
    add_child(httprequest)
    task.connect("completed", self, "_on_task_completed")
    task.push_request(httprequest)
    _pooled_tasks.append(task)

# .............. HTTPRequest completed
func _on_task_completed(task : StorageTask) -> void:
    if task._handler : task._handler.queue_free()
    if task.data!=null and not task.data.empty():
        match task._code:
            task.METHODS.LIST_BUCKETS: emit_signal("listed_buckets", task.data)
            task.METHODS.GET_BUCKET: emit_signal("got_bucket", task.data)
            task.METHODS.CREATE_BUCKET: emit_signal("created_bucket", from(task.data.name))
            task.METHODS.UPDATE_BUCKET: emit_signal("updated_bucket", from(task.data.name))
            task.METHODS.EMPTY_BUCKET: emit_signal("emptied_bucket", from(task.data.name))
            task.METHODS.DELETE_BUCKET: emit_signal("deleted_bucket", task.data)
    elif task.error != null:
        emit_signal("error", task.error)
    _pooled_tasks.erase(task)
