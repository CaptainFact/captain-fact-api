Regarding Phoenix 1.3 new best practices, all files in this module should be given a context.
 
We could for example imagine something like :

```
/lib/captain_fact
  | - accounts
  |   |- accounts.ex
  |   |- user.ex
  |   |- permissions.ex
  |   |- state.ex
  |   |- reputation.ex
  |   |- username.ex
  |   |- reset_password_request.ex
  | - video_debate
  |   |- video_hash_id.ex
  |   |- action_creator.ex
  | ...
/lib/captain_fact_web
```

See https://www.youtube.com/watch?v=tMO28ar0lW8 for more info