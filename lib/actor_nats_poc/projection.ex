defmodule ActorNatsPoc.Projection do
  @moduledoc false
  use GenServer
  require Logger

  alias Gnat.Jetstream.API.Stream
  alias Gnat.Jetstream.API.Consumer

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def replay(opts \\ []) do
    GenServer.cast(__MODULE__, {:replay, opts})
  end

  @impl true
  @spec init(Keyword.t()) :: {:ok, map()}
  def init(opts) do
    name = Keyword.get(opts, :name)

    with {:create_stream, :ok} <- {:create_stream, create_stream(opts)},
         {:create_consumer, :ok} <- {:create_consumer, create_consumer(opts)},
         {:start_pipeline, {:ok, pid}} <- {:start_pipeline, start_pipeline(opts)} do
      {:ok, %{pipeline_pid: pid, opts: opts}}
    else
      {:create_stream, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [create_stream] Details: #{inspect(error)}"
        )

        {:stop, :shutdown}

      {:create_consumer, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [create_consumer] Details: #{inspect(error)}"
        )

        {:stop, :shutdown}

      {:start_pipeline, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [start_pipeline] Details: #{inspect(error)}"
        )

        {:stop, :shutdown}
    end
  end

  @impl true
  def handle_cast({:replay, call_opts}, %{pipeline_pid: pid, opts: opts} = state)
      when not is_nil(pid) and is_pid(pid) do
    opts = Keyword.merge(opts, call_opts)
    name = Keyword.get(opts, :name)

    with {:stop_pipeline, :ok} <- {:stop_pipeline, Broadway.stop(pid)},
         {:destroy_consumer, :ok} <- {:destroy_consumer, destroy_consumer(opts)},
         {:recreate_consumer, :ok} <- {:recreate_consumer, create_consumer(opts)},
         {:start_pipeline, {:ok, newpid}} <- {:start_pipeline, start_pipeline(opts)} do
      {:noreply, %{state | pipeline_pid: newpid}}
    else
      {:stop_pipeline, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [stop_pipeline] Details: #{inspect(error)}"
        )

        {:stop, :shutdown, state}

      {:destroy_consumer, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [destroy_consumer] Details: #{inspect(error)}"
        )

        {:stop, :shutdown, state}

      {:recreate_consumer, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [recreate_consumer] Details: #{inspect(error)}"
        )

        {:stop, :shutdown, state}

      {:start_pipeline, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [start_pipeline] Details: #{inspect(error)}"
        )

        {:stop, :shutdown, state}
    end
  end

  @impl true
  def handle_cast({:process_events, messages}, state) do
    Enum.each(messages, fn msg ->
      Logger.info("Projection Process event: #{inspect(msg)}")
    end)

    {:noreply, state}
  end

  defp create_stream(opts) do
    name = Keyword.get(opts, :stream_name)
    subjects = Keyword.get(opts, :subjects, ["*"])

    case Stream.info(:gnat, name) do
      {:ok, _info} ->
        :ok

      {:error, %{"code" => 404, "description" => "stream not found", "err_code" => 10059}} ->
        {:ok, %{created: _}} = Stream.create(:gnat, %Stream{name: name, subjects: subjects})
        :ok

      error ->
        error
    end
  end

  defp create_consumer(opts) do
    stream_name = Keyword.get(opts, :stream_name)
    consumer_name = Keyword.get(opts, :consumer_name)

    case Consumer.info(:gnat, stream_name, consumer_name) do
      {:ok, _info} ->
        :ok

      {:error, %{"code" => 404, "description" => "consumer not found", "err_code" => 10014}} ->
        {:ok, %{created: _}} =
          Consumer.create(:gnat, %Consumer{stream_name: stream_name, durable_name: consumer_name})

        :ok

      error ->
        error
    end
  end

  defp destroy_consumer(opts) do
    stream_name = Keyword.get(opts, :stream_name)
    consumer_name = Keyword.get(opts, :consumer_name)

    case Consumer.info(:gnat, stream_name, consumer_name) do
      {:ok, _info} ->
        Consumer.delete(:gnat, stream_name, consumer_name)

      {:error, %{"code" => 404, "description" => "consumer not found", "err_code" => 10014}} ->
        :ok

      error ->
        error
    end
  end

  defp start_pipeline(opts), do: ActorNatsPoc.Projection.StreamProducer.start_link(opts)
end
