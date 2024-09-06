# Actor Nats Poc

1. Start Nats with Jetstream enabled

```shell
docker-compose up
```

2. Start application

```shell
iex -S mix
```

3. Create a bucket and start a jetstream replication

```elixir
alias ActorNatsPoc.Statestore.KV, as: StatestoreKV
StatestoreKV.create_replication_bucket("test", "actors.mike")
```

4. Start Projection

```elixir
opts = [name: "test", stream_name: "newtest", subjects: ["actors.*"], consumer_name: "projectionviewertest"]
```

```elixir
ActorNatsPoc.Projection.start_link(opts)
```

5. Put new key value into bucket

```elixir
StatestoreKV.put("test", "mykey", "myvalue")
```

6. See the follow consumer logs in the iex console

```elixir
Processing message: %Broadway.Message{data: "{\"action\":\"key_added\",\"key\":\"mykey\",\"value\":\"myvalue\"}", metadata: %{headers: [], topic: "actors.mike"}, acknowledger: {OffBroadway.Jetstream.Acknowledger, #Reference<0.4061493138.1171259399.101594>, %{reply_to: "$JS.ACK.newtest.projectionviewertest.1.161067.161063.1725488338796149600.5"}}, batcher: :default, batch_key: :default, batch_mode: :bulk, status: :ok}
```

7. To replay events do:

```elixir
ActorNatsPoc.Projection.replay([])
```