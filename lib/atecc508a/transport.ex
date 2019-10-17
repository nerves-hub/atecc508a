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
