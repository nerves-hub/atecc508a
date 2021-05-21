defmodule ATECC508A.Transport.Cache do
  @moduledoc """
  Simple cache for reducing unnecessary traffic to the ATECC508A
  """

  use GenServer

  @atecc508a_op_read 0x02
  @atecc508a_op_genkey 0x40
  @atecc508a_op_random 0x1B

  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc """
  Check if the specified request is in the cache
  """
  @spec get(GenServer.server(), binary()) :: binary() | nil
  def get(pid, request) do
    GenServer.call(pid, {:get, request})
  end

  @doc """
  Save a response back to the cache
  """
  @spec put(GenServer.server(), binary(), any()) :: any()

  # Cache all reads
  def put(pid, <<@atecc508a_op_read, _::binary>> = request, response) do
    GenServer.call(pid, {:put, request, response})
  end

  # Cache the response to getting a public key
  def put(pid, <<@atecc508a_op_genkey, 0, _key_id::little-16>> = request, response) do
    GenServer.call(pid, {:put, request, response})
  end

  # Don't cache random numbers
  def put(_pid, <<@atecc508a_op_random, _::binary>>, response), do: response

  # Flush the cache on everything else:
  #   writes, locks, etc.
  #
  # This is overkill, but safe.
  def put(pid, _request, response) do
    GenServer.call(pid, :flush)
    response
  end

  @impl true
  def init(_) do
    cache = %{}
    {:ok, cache}
  end

  @impl true
  def handle_call({:get, request}, _from, cache) do
    result = Map.get(cache, request)
    {:reply, result, cache}
  end

  @impl true
  def handle_call({:put, request, response}, _from, cache) do
    new_cache = Map.put(cache, request, response)
    {:reply, response, new_cache}
  end

  @impl true
  def handle_call(:flush, _from, _cache) do
    {:reply, :ok, %{}}
  end
end
