# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Alex McLain
# SPDX-FileCopyrightText: 2022 Jon Carstens
# SPDX-FileCopyrightText: 2023 Connor Rigby
# SPDX-FileCopyrightText: 2024 Serhii Lukianov
# SPDX-FileCopyrightText: 2025 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Request do
  @moduledoc """
  This module knows how to send requests to the ATECC508A.
  """

  alias ATECC508A.Transport
  alias ATECC508A.Host

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
  @atecc508a_op_mac 0x08
  @atecc508a_op_write 0x12
  @atecc508a_op_nonce 0x16
  @atecc508a_op_genkey 0x40
  @atecc508a_op_lock 0x17
  @atecc508a_op_random 0x1B
  @atecc508a_op_sign 0x41
  @atecc508a_op_ecdh 0x43
  @atecc508a_op_sha 0x47
  @atecc508a_op_info 0x30
  @atecc508a_op_checkmac 0x28

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
    # The timeout for writing was increased due to timeouts on ATECC608A and ATECC608B devices
    |> transport_request(payload, 100, 1)
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
    # The timeout for locking was increased due to timeouts on ATECC608A and ATECC608B devices
    |> transport_request(payload, 100, 1)
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

          # datasheet has typical values, recommendation for ATECC608 is up to +50ms
          # we measured 129ms working for 500 attempts without failing
          # 129 base + 50 margin = 179 ms is hopefully plenty
          request.(<<@atecc508a_op_sign, sign_mode::binary, key_id::little-16>>, 179, 64)

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

  def set_temp_key(transport, bytes) do
    # 1-byte nonce
    nonce_mode = <<
      # tempkey
      0::2,
      # 32 bytes
      0::1,
      # must be zero
      0::3,
      # pass-through mode
      3::2
    >>

    transport_request(
      transport,
      <<@atecc508a_op_nonce, nonce_mode::binary, 0::size(16), bytes::binary>>,
      100,
      1
    )
  end

  def sha(transport, data) do
    init_mode = <<
      0::2,
      0::3,
      0::3
    >>

    init_request = <<@atecc508a_op_sha::8, init_mode::binary, 0::size(16)>>

    fin_mode = <<
      1::1,
      1::1,
      0::3,
      2::3
    >>

    fin_request = <<@atecc508a_op_sha, fin_mode::binary, 0::size(16), data::binary>>

    Transport.transaction(transport, fn r ->
      with {{:ok, <<0>>}, _} <- r.(init_request, 500, 1) |> interpret_result() do
        r.(fin_request, 500, 32)
      end
    end)
  end

  @doc """
  Get persistent latch value.

  Used for verifying the state of authorization.

  Returns `{:ok, <<1,0,0,0>>}` if latch is set. Returns `{:ok, <<0,0,0,0>>}` if latch is not set. An error tuple is returned if the command fails.
  """
  @spec get_latch(Transport.t()) :: {:ok, binary()} | {:error, atom()}
  def get_latch(transport) do
    payload = <<@atecc508a_op_info, 4, 0, 0>>

    # Timeout is arbitrary
    transport_request(transport, payload, 200, 4)
  end

  @doc """
  Perform a transaction to authenticate volatile key protection using an activation key.

  This takes the key slot holding the activation key (likely to be slot 1) and the activation key.

  The transaction steps are:
  - Generate a nonce inside the device sourced by the device RNG and a seed from the host. This returns the RNG output.
  - Generate the identical nonce on the host based on the RNG and seed.
  - Generate the CheckMac digest on the host using the activation key and produce a digest.
  - Send the digest into the device CheckMac command to verify the activation key. This authorizes the transaction.
  - Set the persistent latch to enable the protected keys.

  Return :ok for success. Returns an error tuple indicating failure.
  """
  @spec auth_volatile_key(Transport.t(), slot(), binary()) ::
          :ok | {:error, atom()} | {:error, binary()}
  def auth_volatile_key(transport, key_id, key) do
    {:ok, <<sn0_3::4-bytes, _::4-bytes, sn4_8::5-bytes, _::binary>>} =
      read_zone(transport, :config, 0, 32)

    serial_number = sn0_3 <> sn4_8

    result =
      Transport.transaction(transport, fn request ->
        nonce_mode = <<
          # target -> TempKey
          0::2,
          # 32 bytes
          0::1,
          # must be zero
          0::3,
          # Generate random nonce
          0::2
        >>

        checkmac_mode = <<
          # must be zero
          0::5,
          # TempKey.sourceFlag = Rand (0)
          0::1,
          # Use key from keyId (must be zero for volatile key authorization)
          0::1,
          # Use nonce from TempKey
          1::1
        >>

        <<latch_req::4-bytes>> = <<@atecc508a_op_info, 4, 0::6, 3::2, 0::8>>

        <<_::20-bytes>> = rand = Host.rand(20)

        # First nonce generates a random nonce to TempKey, sets TempKey.SourceFlag = Rand
        # and returns the random value
        nonce_req_seed = <<@atecc508a_op_nonce, nonce_mode::binary, 0::1, 0::15, rand::binary>>

        with {:ok, <<rng::32-bytes>>} <- request.(nonce_req_seed, 100, 32),
             <<nonce::32-bytes>> <- Host.random_nonce(rng, rand, nonce_mode) do
          %{digest: digest, other: other} = Host.checkmac(key, nonce, serial_number)

          <<check_req::81-bytes>> =
            <<@atecc508a_op_checkmac, checkmac_mode::1-bytes, key_id::little-16, 0::256,
              digest::32-bytes, other::binary>>

          with {:check, {:ok, <<0>>}} <- {:check, request.(check_req, 1000, 1)},
               {:latch, {:ok, <<1::8, 0::24>>}} <- {:latch, request.(latch_req, 998, 4)} do
            {:ok, <<1>>}
          else
            {:check, {:ok, <<1>>}} -> {:error, :checkmac_mismatch}
            {:latch, {:ok, <<0, 0, 0, 0>>}} -> {:error, :latch_failed_to_set}
            {:check, {:error, err}} -> {:error, err}
            {:latch, {:error, err}} -> {:error, err}
          end
        end
      end)

    case result do
      {:ok, <<1>>} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Generate a MAC deterministically using a given input.

  Combines the key in a slot, some internal values and an input value to produce a digest.

  This is primarily implemented as it can be used to verify the behavior of the device and
  whether a key is disabled by the persistent latch or not.

  Returns the digest if successful, otherwise an error tuple.
  """
  @spec mac_deterministic(
          transport :: Transport.t(),
          key_id :: non_neg_integer(),
          input :: binary()
        ) ::
          {:ok, binary()} | {:error, term()}
  def mac_deterministic(transport, key_id, <<_::32-bytes>> = input) do
    Transport.transaction(transport, fn request ->
      nonce_mode = <<
        # tempkey
        0::2,
        # 32 bytes
        0::1,
        # must be zero
        0::3,
        # pass-through mode
        3::2
      >>

      mac_mode = <<
        # must be zero
        0::1,
        # don't do the extra OtherData serial thing
        0::1,
        # must be zero
        0::3,
        # target SourceFlag.Input
        1::1,
        # Use key from keyId (must be zero for volatile key authorization)
        0::1,
        # Use nonce from TempKey
        1::1
      >>

      nonce_req = <<@atecc508a_op_nonce, nonce_mode::binary, 0::size(16), input::binary>>
      mac_req = <<@atecc508a_op_mac, mac_mode::binary, key_id::little-16>>

      with {:ok, <<0>>} <- request.(nonce_req, 100, 1),
           {:ok, <<digest::32-bytes>>} <- request.(mac_req, 500, 32) do
        {:ok, digest}
      end
    end)
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
