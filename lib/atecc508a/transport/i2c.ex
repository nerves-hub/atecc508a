defmodule ATECC508A.Transport.I2C do
  alias ATECC508A.Transport
  require Logger

  @moduledoc """
  Implementation for communicating with ATECC508A parts connected over I2C
  """

  @behaviour Transport

  @default_atecc508a_bus "i2c-1"
  @default_atecc508a_address 0x60

  @type instance :: module()

  @typedoc """
  I2C transports are specified by a bus name like "i2c-1" and
  an I2C address.
  """
  @type i2c_args :: [bus_name: String.t(), address: Circuits.I2C.address()]

  @doc """
  Initialize an I2C transport to an ATECC508A

  Options are:

  * `:bus_name` - "i2c-0", "i2c-1", etc. The default is "i2c-1" which frequently
    works on Raspberry Pis and Beaglebones
  * `:address` - This is the I2C address of the ATECC508A/608A. The default
    is 0x60. It is not common to change this address in Nerves devices.

  If a transport has already been created to the specified ATECC508A, that
  transport will be returned. All commands to the ATECC508A are serialized
  so that they don't interfere with each other.
  """
  @impl Transport
  @spec init(i2c_args()) :: {:ok, Transport.t()} | {:error, atom()}
  def init(args \\ []) do
    bus_name = Keyword.get(args, :bus_name, @default_atecc508a_bus)
    address = Keyword.get(args, :address, @default_atecc508a_address)
    name = process_name(bus_name, address)

    case ATECC508A.Transport.I2CSupervisor.start_child(bus_name, address, name) do
      {:ok, _pid} ->
        {:ok, {__MODULE__, name}}

      {:error, {:already_started, _pid}} ->
        {:ok, {__MODULE__, name}}

      other_error ->
        other_error
    end
  end

  @impl Transport
  @spec detected?(instance()) :: boolean()
  defdelegate detected?(instance), to: ATECC508A.Transport.I2CServer

  @impl Transport
  @spec request(instance(), binary(), non_neg_integer(), non_neg_integer()) ::
          {:error, atom()} | {:ok, binary()}
  defdelegate request(instance, payload, timeout, response_payload_len),
    to: ATECC508A.Transport.I2CServer

  @impl Transport
  @spec transaction(instance(), (fun() -> {:ok, any()} | {:error, atom()})) ::
          {:ok, any()} | {:error, atom()}
  defdelegate transaction(instance, callback), to: ATECC508A.Transport.I2CServer

  @impl Transport
  @spec info(instance()) :: map()
  defdelegate info(instance), to: ATECC508A.Transport.I2CServer

  defp process_name(bus_name, address) do
    Module.concat([ATECC508A.Transport.I2C, bus_name, to_string(address)])
  end
end
