# SPDX-FileCopyrightText: 2019 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Alex McLain
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Transport.Cache do
  @moduledoc """
  Simple cache for reducing unnecessary traffic to the ATECC508A
  """

  use GenServer

  @type response() :: {:ok, binary()} | {:error, any()}

  @atecc508a_op_read 0x02
  @atecc508a_op_genkey 0x40
  @atecc508a_op_random 0x1B

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc """
  Check the cache for the request
  """
  @spec get(GenServer.server(), binary()) :: response() | nil
  def get(pid, request) do
    GenServer.call(pid, {:get, request})
  end

  @doc """
  Selectively cache responses
  """
  @spec put(GenServer.server(), binary(), response()) :: :ok
  def put(pid, request, response) do
    case triage(request, response) do
      :cache -> GenServer.call(pid, {:put, request, response})
      :flush -> GenServer.call(pid, :flush)
      :ignore -> :ok
    end
  end

  @impl GenServer
  def init(_) do
    cache = %{}
    {:ok, cache}
  end

  @impl GenServer
  def handle_call({:get, request}, _from, cache) do
    result = Map.get(cache, request)
    {:reply, result, cache}
  end

  def handle_call({:put, request, response}, _from, cache) do
    new_cache = Map.put(cache, request, response)
    {:reply, :ok, new_cache}
  end

  def handle_call(:flush, _from, _cache) do
    {:reply, :ok, %{}}
  end

  # Ignore errors outright
  defp triage(_request, {:error, _reason}), do: :ignore

  # Cache all successful reads
  defp triage(<<@atecc508a_op_read, _::binary>>, {:ok, data})
       when byte_size(data) == 4 or byte_size(data) == 32,
       do: :cache

  defp triage(<<@atecc508a_op_read, _::binary>>, _result), do: :ignore

  # Cache successful responses to getting a public key
  defp triage(<<@atecc508a_op_genkey, 0, _key_id::little-16>>, {:ok, data})
       when byte_size(data) == 64,
       do: :cache

  defp triage(<<@atecc508a_op_genkey, 0, _key_id::little-16>>, _result), do: :ignore

  # Don't cache random numbers
  defp triage(<<@atecc508a_op_random, _::binary>>, _result), do: :ignore

  # Flush the cache on everything else:
  #   writes, locks, etc.
  #
  # This is overkill, but safe.
  defp triage(_request, _result), do: :flush
end
