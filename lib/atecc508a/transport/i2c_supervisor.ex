defmodule ATECC508A.Transport.I2CSupervisor do
  @moduledoc false
  use DynamicSupervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec start_child(binary() | charlist(), Circuits.I2C.address(), atom()) ::
          DynamicSupervisor.on_start_child()
  def start_child(bus_name, address, name) do
    spec = {ATECC508A.Transport.I2CServer, [bus_name, address, name]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
