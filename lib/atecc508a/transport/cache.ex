defmodule ATECC508A.Transport.Cache do
  @moduledoc """
  Simple cache for reducing unnecessary traffic to the ATECC508A
  """

  @type state() :: map()

  @atecc508a_op_read 0x02
  @atecc508a_op_genkey 0x40
  @atecc508a_op_random 0x1B

  @doc """
  Initialize the cache for one ATECC508A
  """
  @spec init() :: state()
  def init() do
    %{}
  end

  @doc """
  Check if the specified request is in the cache
  """
  @spec get(state(), binary()) :: binary() | nil
  def get(cache, request) do
    Map.get(cache, request)
  end

  @doc """
  Save a response back to the cache
  """
  @spec put(state, binary(), any()) :: state()

  # Cache all reads
  def put(cache, <<@atecc508a_op_read, _::binary>> = request, response) do
    Map.put(cache, request, response)
  end

  # Cache the response to getting a public key
  def put(cache, <<@atecc508a_op_genkey, 0, _key_id::little-16>> = request, response) do
    Map.put(cache, request, response)
  end

  # Don't cache random numbers
  def put(cache, <<@atecc508a_op_random, _::binary>>, _response), do: cache

  # Flush the cache on everything else:
  #   writes, locks, etc.
  #
  # This is overkill, but safe.
  def put(_cache, _request, _response), do: %{}
end
