# SPDX-FileCopyrightText: 2025 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Host do
  @moduledoc """
  Implementations of useful operations for the host CPU to perform.

  This is mainly things like constructing a message correctly for hashing.
  """

  @atecc508a_op_nonce 0x16

  @doc """
  Generate a random binary of the specified length.
  """
  @spec rand(bytes :: non_neg_integer()) :: binary()
  def rand(bytes) do
    :crypto.strong_rand_bytes(bytes)
  end

  @doc """
  Generate hash using SHA-256.
  """
  @spec digest(binary()) :: binary()
  def digest(msg) do
    :crypto.hash(:sha256, msg)
  end

  @doc """
  Generate a nonce from a random input.

  This matches the nonce implementation of the device.

  It takes an input from the device RNG, the random input the host used to seed the RNG, and the nonce mode.

  It returns a digest.
  """
  @spec random_nonce(binary(), binary(), binary()) :: binary()
  def random_nonce(<<rng::32-bytes>>, <<rand::20-bytes>>, <<nonce_mode::1-bytes>>) do
    digest(
      <<rng::32-bytes, rand::20-bytes, @atecc508a_op_nonce::8, nonce_mode::1-bytes, 0x00::8>>
    )
  end

  @doc """
  CheckMac operation on the host.

  This is used for the ClientResp parameter when authorizing a key using
  CheckMac.

  This implementation does not use the extra bytes of the serial number.

  Returns a map of the constructed message, the digest and the OtherData
  used when building the message.
  """
  @spec checkmac(binary(), binary(), binary()) :: %{
          msg: binary(),
          digest: binary(),
          other: binary()
        }
  def checkmac(
        <<_::32-bytes>> = key,
        <<_::32-bytes>> = nonce,
        <<sn0_1::2-bytes, _sn2_3::2-bytes, _sn4_7::4-bytes, sn8::1-bytes>>
      ) do
    msg = <<
      key::32-bytes,
      nonce::32-bytes,
      0::size(4 * 8),
      0::size(8 * 8),
      0::size(3 * 8),
      sn8::1-bytes,
      0::size(4 * 8),
      sn0_1::2-bytes,
      0::size(2 * 8)
    >>

    %{msg: msg, digest: digest(msg), other: <<0::size(13 * 8)>>}
  end

  @doc """
  MAC operation on the host.

  This implementation does not use the extra bytes of the serial number.

  Returns a map of the constructed message, the digest and the OtherData
  used when building the message.
  """
  @spec mac(
          key :: binary(),
          nonce :: binary(),
          opcode :: binary(),
          mode :: binary(),
          param2 :: binary(),
          serial_number :: binary()
        ) :: %{
          msg: binary(),
          digest: binary()
        }
  def mac(
        <<_::32-bytes>> = key,
        <<_::32-bytes>> = nonce,
        <<_::1-bytes>> = opcode,
        <<_::1-bytes>> = mode,
        <<_::2-bytes>> = param2,
        <<sn0_1::2-bytes, _sn2_3::2-bytes, _sn4_7::4-bytes, sn8::1-bytes>>
      ) do
    msg =
      <<key::32-bytes, nonce::32-bytes, opcode::1-bytes, mode::1-bytes, param2::2-bytes,
        0::size(8 * 8), 0::size(3 * 8), sn8::1-bytes, 0::size(4 * 8), sn0_1::2-bytes,
        0::size(2 * 8)>>

    IO.inspect(byte_size(msg))

    %{
      msg: msg,
      digest: digest(msg)
    }
  end
end
