defmodule ATECC508A.Request do
  @moduledoc """
  This module knows how to send requests to the ATECC508A.
  """

  alias ATECC508A.Transport

  @type zone :: :config | :otp | :data
  @type slot :: 0..15
  @type block :: 0..3
  @type offset :: 0..7
  @type access_size :: 4 | 32
  @type access_data :: <<_::32>> | <<_::256>>
  @type addr :: 0..65535

  @typedoc """
  A transaction is a tuple with the binary to send, how long to
  wait in milliseconds for the response and the size of payload to
  expect to read for the response.
  """
  @type transaction :: {binary(), non_neg_integer(), non_neg_integer()}

  @atecc508a_op_read 0x02
  @atecc508a_op_write 0x12
  @atecc508a_op_nonce 0x16
  @atecc508a_op_genkey 0x40
  @atecc508a_op_lock 0x17
  @atecc508a_op_random 0x1B
  @atecc508a_op_sign 0x41
  @atecc508a_op_ecdh 0x43

  # See https://github.com/MicrochipTech/cryptoauthlib/blob/master/lib/calib/calib_execution.c
  # for command max execution times. I'm not sure why they are different from the
  # datasheet. Since this library is compatible with the ECC608A, the longer time is
  # used.

  @spec to_config_addr(0..127) :: addr()
  def to_config_addr(byte_offset)
      when byte_offset >= 0 and byte_offset < 128 and rem(byte_offset, 4) == 0 do
    div(byte_offset, 4)
  end

  @spec to_config_addr(block(), offset()) :: addr()
  def to_config_addr(block, offset)
      when is_integer(block) and is_integer(offset) and
             block >= 0 and block < 4 and
             offset >= 0 and offset < 8 do
    block * 8 + offset
  end

  @spec to_otp_addr(0..127) :: addr()
  def to_otp_addr(byte_offset), do: to_config_addr(byte_offset)

  @spec to_otp_addr(block(), offset()) :: addr()
  def to_otp_addr(block, offset) when is_integer(block) and is_integer(offset),
    do: to_config_addr(block, offset)

  @spec to_data_addr(slot(), 0..416) :: addr()
  def to_data_addr(slot, byte_offset)
      when slot >= 0 and slot < 16 and byte_offset >= 0 and byte_offset < 416 and
             rem(byte_offset, 4) == 0 do
    word_offset = div(byte_offset, 4)
    offset = rem(word_offset, 8)
    block = div(word_offset, 8)
    to_data_addr(slot, block, offset)
  end

  @spec to_data_addr(slot(), block(), offset()) :: addr()
  def to_data_addr(slot, block, offset)
      when is_integer(slot) and is_integer(block) and is_integer(offset) and
             slot >= 0 and slot < 16 and
             block >= 0 and block < 13 and
             offset >= 0 and offset < 8 do
    block * 256 + slot * 8 + offset
  end

  @doc """
  Create a read message
  """
  @spec read_zone(Transport.t(), zone(), addr(), access_size()) ::
          {:ok, binary()} | {:error, atom()}
  def read_zone(transport, zone, addr, length) do
    payload =
      <<@atecc508a_op_read, length_flag(length)::1, 0::5, zone_index(zone)::2, addr::little-16>>

    transport
    |> transport_request(payload, 5, length)
  end

  @doc """
  Create a write message
  """
  @spec write_zone(Transport.t(), zone(), addr(), access_data()) :: :ok | {:error, atom()}
  def write_zone(transport, zone, addr, data) do
    len = byte_size(data)

    payload =
      <<@atecc508a_op_write, length_flag(len)::1, 0::5, zone_index(zone)::2, addr::little-16,
        data::binary>>

    transport
    |> transport_request(payload, 45, 1)
    |> return_status()
  end

  @doc """
  Create a genkey request message.
  """
  @spec genkey(Transport.t(), slot(), boolean()) :: {:ok, binary()} | {:error, atom()}
  def genkey(transport, key_id, create_key?) do
    mode2 = if create_key?, do: 1, else: 0
    mode3 = 0
    mode4 = 0

    payload =
      <<@atecc508a_op_genkey, 0::3, mode4::1, mode3::1, mode2::1, 0::2, key_id::little-16>>

    transport
    |> transport_request(payload, 653, 64)
  end

  @doc """
  Create a message to lock a zone.
  """
  @spec lock_zone(Transport.t(), zone(), ATECC508A.crc16()) :: :ok | {:error, atom()}
  def lock_zone(transport, zone, zone_crc) do
    # Need to calculate the CRC of everything written in the zone to be
    # locked for this to work.

    # See Table 9-31 - Mode Encoding
    mode = if zone == :config, do: 0, else: 1
    payload = <<@atecc508a_op_lock, mode, zone_crc::binary>>

    transport
    |> transport_request(payload, 35, 1)
    |> return_status()
  end

  @doc """
  Lock a specific slot.
  """
  @spec lock_slot(Transport.t(), slot()) :: :ok | {:error, atom()}
  def lock_slot(transport, slot) do
    # Need to calculate the CRC of everything written in the zone to be
    # locked for this to work.

    # See Table 9-31 - Mode Encoding
    mode = <<0::size(2), slot::size(4), 2::size(2)>>
    payload = <<@atecc508a_op_lock, mode::binary, 0::size(16)>>

    transport
    |> transport_request(payload, 35, 1)
    |> return_status()
  end

  @doc """
  Request a random number.
  """
  @spec random(Transport.t()) :: {:ok, binary()} | {:error, atom()}
  def random(transport) do
    payload = <<@atecc508a_op_random, 0, 0, 0>>

    transport
    |> transport_request(payload, 23, 32)
  end

  @doc """
  Sign a SHA256 digest.
  """
  @spec sign_digest(Transport.t(), slot(), binary()) ::
          {:ok, binary()} | {:error, atom()}
  def sign_digest(transport, key_id, digest) do
    Transport.transaction(transport, fn request ->
      # See Table 11-33 - Mode Encoding
      nonce_mode = <<1::size(2), 0::size(1), 0::size(3), 3::size(2)>>

      request.(<<@atecc508a_op_nonce, nonce_mode::binary, 0::size(16), digest::binary>>, 29, 1)
      |> interpret_result()
      |> case do
        {{:ok, _}, _retry} ->
          # See Table 11-50 - Mode Encoding
          sign_mode = <<5::size(3), 0::size(4), 0::size(1)>>

          request.(<<@atecc508a_op_sign, sign_mode::binary, key_id::little-16>>, 115, 64)

        {error, _retry} ->
          error
      end
    end)
  end

  @doc """
  Calculates ECDH secret.
  """
  @spec ecdh(Transport.t(), binary()) :: {:ok, binary()} | {:error, atom()}
  def ecdh(transport, raw_pub_key) do
    payload = <<@atecc508a_op_ecdh, 0, 0, 0, raw_pub_key::binary>>

    transport_request(transport, payload, 998, 32)
  end

  defp zone_index(:config), do: 0
  defp zone_index(:otp), do: 1
  defp zone_index(:data), do: 2

  defp length_flag(32), do: 1
  defp length_flag(4), do: 0

  @spec transport_request(
          transport :: Transport.t(),
          payload :: binary(),
          timeout :: non_neg_integer(),
          response_payload_len :: non_neg_integer(),
          request_timeout :: non_neg_integer()
        ) :: {:ok, binary()} | {:error, atom()}
  defp transport_request(
         transport,
         payload,
         timeout,
         response_payload_len,
         request_timeout \\ 1000
       ) do
    give_up_time = System.monotonic_time(:millisecond) + request_timeout

    retry_request_with_timeout(
      transport,
      payload,
      timeout,
      response_payload_len,
      give_up_time
    )
  end

  defp retry_request_with_timeout(
         transport,
         payload,
         timeout,
         response_payload_len,
         give_up_time
       ) do
    {result, retry?} =
      transport
      |> Transport.request(payload, timeout, response_payload_len)
      |> interpret_result()

    if retry? do
      Process.sleep(100)

      if System.monotonic_time(:millisecond) > give_up_time,
        do: {:error, {:no_more_retries, result}},
        else:
          retry_request_with_timeout(
            transport,
            payload,
            timeout,
            response_payload_len,
            give_up_time
          )
    else
      result
    end
  end

  defp interpret_result({:ok, data}) when byte_size(data) > 1 do
    {{:ok, data}, false}
  end

  defp interpret_result({:error, reason}), do: {{:error, reason}, true}
  defp interpret_result({:ok, <<0x00>>}), do: {{:ok, <<0x00>>}, false}
  defp interpret_result({:ok, <<0x01>>}), do: {{:error, :checkmac_or_verify_miscompare}, false}
  defp interpret_result({:ok, <<0x03>>}), do: {{:error, :parse_error}, true}
  defp interpret_result({:ok, <<0x05>>}), do: {{:error, :ecc_fault}, true}
  defp interpret_result({:ok, <<0x07>>}), do: {{:error, :self_test_error}, false}
  defp interpret_result({:ok, <<0x08>>}), do: {{:error, :health_test_error}, false}
  defp interpret_result({:ok, <<0x0F>>}), do: {{:error, :execution_error}, false}
  defp interpret_result({:ok, <<0x11>>}), do: {{:error, :no_wake}, true}
  defp interpret_result({:ok, <<0xEE>>}), do: {{:error, :watchdog_about_to_expire}, true}
  defp interpret_result({:ok, <<0xFF>>}), do: {{:error, :crc_error}, true}
  defp interpret_result({:ok, <<unknown>>}), do: {{:error, {:unexpected_status, unknown}}, true}

  defp return_status({:ok, _}), do: :ok
  defp return_status(other), do: other
end
