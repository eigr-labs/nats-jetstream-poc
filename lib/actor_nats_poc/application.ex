defmodule ActorNatsPoc.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Create NATS connection
      {Gnat.ConnectionSupervisor,
       %{
         name: :gnat,
         connection_settings: [
           %{host: "localhost", port: 4222}
         ]
       }},
      # Create Nats Jetstream Broadway pipeline
      {ActorNatsPoc.Projection.StreamProducer, []}
    ]

    opts = [strategy: :one_for_one, name: ActorNatsPoc.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
