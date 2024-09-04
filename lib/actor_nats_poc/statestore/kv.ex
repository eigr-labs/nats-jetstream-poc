defmodule ActorNatsPoc.Statestore.KV do
  @moduledoc false

  alias Gnat.Jetstream.API.KV

  @spec create_bucket(binary, Keyword.t()) :: {:ok, map()} | {:error, any()}
  def create_bucket(bucket, opts \\ []) do
    KV.create_bucket(:gnat, bucket, opts)
  end

  def create_and_watch_bucket(bucket, opts \\ [], func) when is_function(func, 3) do
    with {:ok, _map} <- create_bucket(bucket, opts),
         {:ok, _watcher_pid} <- watch(bucket, func) do
      :ok
    else
      unexpect ->
        unexpect
    end
  end

  def create_replication_bucket(bucket, subject, opts \\ []) do
    with {:ok, _map} <- create_bucket(bucket, opts),
         {:ok, _watcher_pid} <-
           watch(bucket, fn action, key, value ->
             # encode payload and send
             payload = Jason.encode!(%{action: action, key: key, value: value})
             Gnat.pub(:gnat, subject, payload)
           end) do
      :ok
    else
      unexpect ->
        unexpect
    end
  end

  @spec destroy_bucket(binary) :: :ok | {:error, any()}
  def destroy_bucket(bucket) do
    KV.delete_bucket(:gnat, bucket)
  end

  @spec put(binary, binary, any) :: :ok | {:error, :no_responders | :timeout}
  def put(bucket, key, value) do
    # in spawn case we need to replicate this action in database
    KV.put_value(:gnat, bucket, key, value)
  end

  @spec get(binary, any) :: nil | binary | {:error, any}
  def get(bucket, key) do
    # in spawn case we need to search in the databas in case of this returns nil
    KV.get_value(:gnat, bucket, key)
  end

  @spec watch(binary, (:key_added | :key_deleted, binary, any -> nil)) ::
          :ignore | {:error, any} | {:ok, pid}
  def watch(bucket, func) when is_function(func, 3) do
    KV.watch(:gnat, bucket, func)
  end
end
