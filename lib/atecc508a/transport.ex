defmodule ATECC508A.Transport do
  @moduledoc """
  ATECC508A transport behaviour
  """

  @type t :: {module(), any()}

  @callback init(args :: any()) :: {:ok, t()} | {:error, atom()}

  @callback request(
              id :: any(),
              payload :: binary(),
              timeout :: non_neg_integer(),
              response_payload_len :: non_neg_integer()
            ) :: {:ok, binary()} | {:error, atom()}

  @callback transaction(
              id :: any(),
              callback :: (request :: fun() -> {:ok, any()} | {:error, atom()})
            ) :: {:ok, any()} | {:error, atom()}

  @callback detected?(arg :: any) :: boolean()

  @callback info(id :: any()) :: map()

  @doc """
  Send a request to the ATECC508A and wait for a response

  This is the raw request. The transport implementation takes care of adding
  and removing CRCs.
  """
  @spec request(t(), binary(), non_neg_integer(), non_neg_integer()) ::
          {:ok, binary()} | {:error, atom()}
  def request({mod, arg}, payload, timeout, response_payload_len) do
    mod.request(arg, payload, timeout, response_payload_len)
  end

  @doc """
  Run a callback function inside a transaction that doesn't sleep

  Use a transaction when multiple requests need to be sent without putting the
  chip to sleep. For example, when a value needs to be stored in SRAM and then
  acted on, since sleeping will clear the SRAM.

  `callback` is a function that provides one argument, `request`, and expects a
  return value of `{:ok, data}` or `{:error, reason}`. `request` is an anonymous
  function whose args follow the public function `ATECC508A.Transport.request/4`,
  except without the first arg (`t()`) since this is provided to `transaction`.

  The success/error tuple returned by the callback function is returned
  by `transaction`.

  ## Example

  ```ex
  {:ok, transport} = ATECC508A.Transport.I2C.init()

  {:ok, signature} =
    ATECC508A.Transport.transaction(transport, fn request ->
      # NONCE command (0x16)
      {:ok, <<0>>} = request.(<<0x16, 0x43, 0, 0, signature_digest::binary>>, 29, 1)
      # SIGN command (0x41)
      request.(<<0x41, 0xA0, 0, 0>>, 115, 64)
    end)
  ```
  """
  @spec transaction(t(), (fun() -> {:ok, any()} | {:error, atom()})) ::
          {:ok, any()} | {:error, atom()}
  def transaction({mod, arg}, callback) do
    mod.transaction(arg, callback)
  end

  @doc """
  Check whether the ATECC508A is present

  The transport implementation should do the minimum work to figure out whether
  an ATECC508A is actually present. This is called by users who are unsure
  whether the device has an ATECC508A and want to check before sending requests
  to it.
  """
  @spec detected?(t()) :: boolean()
  def detected?({mod, arg}) do
    mod.detected?(arg)
  end

  @doc """
  Return information about this transport

  This information is specific to this transport. No fields are required.
  """
  @spec info(t()) :: map()
  def info({mod, arg}) do
    mod.info(arg)
  end
end
