Regarding Phoenix 1.3 new best practices, all files in this module should be given a context.
 
We could for example imagine something like :

```
/lib/captain_fact
  | - user_state
  |   |- permissions.ex
  |   |- state.ex
  |   |- reputation.ex
  |   |- username.ex
  | - user_state.ex
  | - video_debate
  |   |- video_hash_id.ex
  |   |- action_creator.ex
  | - video_debate.ex
  | ...
  | - web
```

See https://www.youtube.com/watch?v=tMO28ar0lW8 for more info