# Godot Supabase Chat demo

# How to Use

See [here](https://supabase.io/docs/guides/local-development) for supabase local development.

```sh
# setup supabase
npm install -g supabase
supabase start

# setup DB Tables
brew install postgresql # for psql command
./create_tables.sh

# Launch Login scene
alias godot="path/to/godot/bin"
godot scenes/Login.tscn
```

# Recommended DB client

I'm using beekeeper studio.

https://www.beekeeperstudio.io

local supabases's default settings
- host: localhost
- port: 5432
- user: postgres
- password: postgres
- db: postgres