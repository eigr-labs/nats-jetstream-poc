defmodule ActorNatsPoc.Projection.StreamProducer do
  @moduledoc false
  use Broadway

  alias Broadway.Message

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    Broadway.start_link(
      __MODULE__,
      name: Module.concat(__MODULE__, Projection),
      producer: [
        module: {
          OffBroadway.Jetstream.Producer,
          connection_name: :gnat, stream_name: "newtest", consumer_name: "projectionviewertest"
        },
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 10]
      ],
      batchers: [
        default: [
          concurrency: 5,
          batch_size: 10,
          batch_timeout: 2_000
        ]
      ]
    )
  end

  @spec handle_message(any, Broadway.Message.t(), any) :: Broadway.Message.t()
  def handle_message(_processor_name, message, _context) do
    IO.puts("Processing message: #{inspect(message)}")

    message
    |> Message.update_data(&process_data/1)
    |> Message.configure_ack(on_success: :term)

    # |> case do
    #   "FOO" -> Message.configure_ack(message, on_success: :term)
    #   "BAR" -> Message.configure_ack(message, on_success: :nack)
    #   message -> message
    # end
  end

  defp process_data(data) do
    String.upcase(data)
  end

  def handle_batch(_, messages, _, _) do
    list = messages |> Enum.map(fn e -> e.data end)
    GenServer.cast(ActorNatsPoc.Projection, {:process_events, messages})
    IO.puts("Got a batch: #{inspect(list)}. Sending acknowledgements...")
    messages
  end
end
