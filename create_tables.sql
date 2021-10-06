CREATE TABLE public.rooms (
  id serial NOT NULL PRIMARY KEY,
  name text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now()
);


CREATE TABLE public.chat_messages (
  id serial NOT NULL PRIMARY KEY,
  room_id integer NOT NULL REFERENCES public.rooms(id),
  user_id uuid NOT NULL,
  message text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now()
);


insert into rooms (name) values ('test_room_1'), ('test_room_2'), ('test_room_3'), ('test_room_4');