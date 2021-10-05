extends Reference
class_name SupabaseQuery

var query_struct : Dictionary = {
    table = "",
    select = PoolStringArray([]),
    order = PoolStringArray([]),
    Or = PoolStringArray([]),
    eq = PoolStringArray([]),
    neq = PoolStringArray([]),
    like = PoolStringArray([]),
    ilike = PoolStringArray([]),
    Is = PoolStringArray([]),
    in = PoolStringArray([]),
    fts = PoolStringArray([]),
    plfts = PoolStringArray([]),
    phfts = PoolStringArray([]),
    wfts = PoolStringArray([])
   }

var query : String = ""
var raw_query : String = ""
var header : PoolStringArray = []
var request : int
var body : String = ""


enum REQUESTS {
    NONE,
    SELECT,
    INSERT,
    UPDATE,
    DELETE
}

enum Directions {
    Ascending,
    Descending
   }

enum Nullsorder {
    First,
    Last
   }

enum Filters {
    EQUAL,
    NOT_EQUAL,
    GREATER_THAN
    LESS_THAN,
    GREATER_THAN_OR_EQUAL,
    LESS_THAN_OR_EQUAL,
    LIKE,
    ILIKE,
    IS,
    IN,
    FTS,
    PLFTS,
    PHFLTS,
    WFTS,
    OR,
    ORDER
   }

func _init(_raw_query : String = "", _raw_type : int = -1, _raw_header : PoolStringArray = [], _raw_body : String = ""):
    if _raw_query != "":
        raw_query = _raw_query
        query = _raw_query
        request = _raw_type
        header = _raw_header as PoolStringArray
        body = _raw_body

# Build the query from the scrut
func build_query() -> String:
    if raw_query == "" and query == raw_query:
        for key in query_struct:
            if query_struct[key].empty(): continue
            if query.length() > 0 : if not query[query.length()-1] in ["/","?"]: query+="&"
            match key:
                "table":
                    query += query_struct[key]
                "select", "order":
                    if query_struct[key].empty(): continue
                    query += (key + "=" + PoolStringArray(query_struct[key]).join(","))
                "eq", "neq", "lt", "gt", "lte", "gte", "like", "ilike", "Is", "in", "fts", "plfts", "phfts", "wfts":
                    query += PoolStringArray(query_struct[key]).join("&")
                "Or":
                    query += "or=(%s)"%[query_struct[key].join(",")]
    return query


func from(table_name : String) -> SupabaseQuery:
    query_struct.table = table_name+"?"
    return self

# Insert new Row
func insert(fields : Array, upsert : bool = false) -> SupabaseQuery:
    request = REQUESTS.INSERT
    body = to_json(fields)
    if upsert : header += PoolStringArray(["Prefer: resolution=merge-duplicates"])
    return self

# Select Rows
func select(columns : PoolStringArray = PoolStringArray(["*"])) -> SupabaseQuery:
    request = REQUESTS.SELECT
    query_struct.select += columns
    return self

# Update Rows
func update(fields : Dictionary) -> SupabaseQuery:
    request = REQUESTS.UPDATE
    body = to_json(fields)
    return self

# Delete Rows
func delete() -> SupabaseQuery:
    request = REQUESTS.DELETE
    return self

## [MODIFIERS] -----------------------------------------------------------------

func range(from : int, to : int) -> SupabaseQuery:
    header = PoolStringArray(["Range: "+str(from)+"-"+str(to)])
    return self

func order(column : String, direction : int = Directions.Ascending, nullsorder : int = Nullsorder.First) -> SupabaseQuery:
    var direction_str : String
    match direction:
        Directions.Ascending: direction_str = "asc"
        Directions.Descending: direction_str = "desc"
    var nullsorder_str : String
    match nullsorder:
        Nullsorder.First: nullsorder_str = "nullsfirst"
        Nullsorder.Last: nullsorder_str = "nullslast"
    query_struct.order += PoolStringArray([("%s.%s.%s" % [column, direction_str, nullsorder_str])])
    return self

## [FILTERS] --------------------------------------------------------------------

func filter(column : String, filter : int, value : String, _props : Dictionary = {}) -> SupabaseQuery:
    var filter_str : String = match_filter(filter)
    var array : PoolStringArray = query_struct[filter_str] as PoolStringArray
    var struct_filter : String = filter_str
    if _props.has("config"):
        struct_filter+= "({config})".format(_props)
    if _props.has("negate"):
        struct_filter = ("not."+struct_filter) if _props.get("negate") else struct_filter
    # Apply custom logic or continue with default logic
    match filter_str:
        "Or":
            if _props.has("queries"):
                for query in _props.get("queries"):
                    array.append(query.build_query().replace("=",".") if (not query is String) else query)
        _:
            array.append("%s=%s.%s" % [column, struct_filter.to_lower(), value])
    query_struct[filter_str] = array
    return self

func match_filter(filter : int) -> String:
    var filter_str : String
    match filter:
        Filters.EQUAL: filter_str = "eq"
        Filters.FTS: filter_str = "fts"
        Filters.ILIKE: filter_str = "ilike"
        Filters.IN: filter_str = "in"
        Filters.IS: filter_str = "Is"
        Filters.GREATER_THAN: filter_str = "gt"
        Filters.GREATER_THAN_OR_EQUAL: filter_str = "gte"
        Filters.LIKE: filter_str = "like"
        Filters.LESS_THAN: filter_str = "lt"
        Filters.LESS_THAN_OR_EQUAL: filter_str = "lte"
        Filters.NOT_EQUAL: filter_str = "neq"
        Filters.OR: filter_str = "Or"
        Filters.PLFTS: filter_str = "plfts"
        Filters.PHFTS: filter_str = "phfts"
        Filters.WFTS: filter_str = "wfts"
    return filter_str

# Finds all rows whose value on the stated columns match the specified values.
func match(query_dict : Dictionary) -> SupabaseQuery:
    for key in query_dict.keys():
        eq(key, query_dict[key])
    return self

# Finds all rows whose value on the stated column match the specified value.
func eq(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.EQUAL, value)
    return self

# Finds all rows whose value on the stated column doesn't match the specified value.
func neq(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.NOT_EQUAL, value)
    return self

# Finds all rows whose value on the stated column is greater than the specified value
func gt(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.GREATER_THAN, value)
    return self

# Finds all rows whose value on the stated column is less than the specified value
func lt(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.LESS_THAN, value)
    return self

# Finds all rows whose value on the stated column is greater than or equal to the specified value
func gte(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.GREATER_THAN_OR_EQUAL, value)
    return self

# Finds all rows whose value on the stated column is less than or equal to the specified value
func lte(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.LESS_THAN_OR_EQUAL, value)
    return self

# Finds all rows whose value in the stated column matches the supplied pattern (case sensitive).
func like(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.LIKE, "*%s*"%value)
    return self

# Finds all rows whose value in the stated column matches the supplied pattern (case insensitive).
func ilike(column : String, value : String) -> SupabaseQuery:
    filter(column, Filters.ILIKE, value)
    return self

# A check for exact equality (null, true, false), finds all rows whose value on the stated column exactly match the specified value.
func Is(column : String, value, negate : bool = false) -> SupabaseQuery:
    filter(column, Filters.IS, str(value), {negate = negate})
    return self

# Finds all rows whose value on the stated column is found on the specified values.
func In(column : String, array : PoolStringArray) -> SupabaseQuery:
    filter(column, Filters.IN, "("+array.join(",")+")")
    return self

func Or(queries : Array) -> SupabaseQuery:
    filter("", Filters.OR, "", {queries = queries})
    return self

# Text Search
func text_seach(column : String, query : String, type : String = "", config : String = "") -> SupabaseQuery:
    var filter : int
    match type:
        "plain": filter = Filters.PLFTS
        "phrase": filter = Filters.PHFLTS
        "websearch": filter = Filters.WFTS
        _: filter = Filters.FTS
    query = query.replacen(" ", "%20")
    filter(column, filter, query, {config = config} if config != "" else {})
    return self

func clean() -> void:
    query = ""
    body = ""
    header = []
    request = 0

    query_struct.table = ""
    query_struct.select = PoolStringArray([])
    query_struct.order = PoolStringArray([])
    query_struct.eq = PoolStringArray([])
    query_struct.neq = PoolStringArray([])
    query_struct.gt = PoolStringArray([])
    query_struct.lt = PoolStringArray([])
    query_struct.gte = PoolStringArray([])
    query_struct.lte = PoolStringArray([])
    query_struct.like = PoolStringArray([])
    query_struct.ilike = PoolStringArray([])
    query_struct.IS = PoolStringArray([])
    query_struct.in = PoolStringArray([])
    query_struct.fts = PoolStringArray([])
    query_struct.plfts = PoolStringArray([])
    query_struct.phfts = PoolStringArray([])
    query_struct.wfts = PoolStringArray([])


func _to_string() -> String:
    return build_query()
