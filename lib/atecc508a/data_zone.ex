defmodule ATECC508A.DataZone do
  @moduledoc """
  This module handles operations on the data zone.
  """

  alias ATECC508A.{Request, Transport}

  @doc """
  Read a slot
  """
  @spec read(Transport.t(), Request.slot()) :: {:ok, binary()} | {:error, atom()}
  def read(transport, slot) do
    do_read(transport, slot, 0, slot_size(slot), [])
  end

  defp do_read(_transport, _slot, _offset, 0, data) do
    result =
      data
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    {:ok, result}
  end

  defp do_read(transport, slot, offset, left, data) when left > 32 do
    addr = Request.to_data_addr(slot, offset)

    case Request.read_zone(transport, :data, addr, 32) do
      {:ok, part} -> do_read(transport, slot, offset + 32, left - 32, [part | data])
      error -> error
    end
  end

  defp do_read(transport, slot, offset, left, data) do
    addr = Request.to_data_addr(slot, offset)

    case Request.read_zone(transport, :data, addr, 4) do
      {:ok, part} -> do_read(transport, slot, offset + 4, left - 4, [part | data])
      error -> error
    end
  end

  @doc """
  Write a slot in the data zone.

  This can use 4 byte writes if the data is not a multiple of 32 bytes. These
  are only allowed under some conditions.  Most notably, 4-byte writes aren't
  allowed when the data zone is UNLOCKED.
  """
  @spec write(Transport.t(), Request.slot(), binary()) :: :ok | {:error, atom()}
  def write(transport, slot, data) do
    check_data_size(slot, data)

    do_write(transport, slot, 0, data)
  end

  @doc """
  Write a slot in the data zone and pad to a multiple of 32-bytes

  This is useful to get around 32-byte write limitations. The padded bytes are
  set to 0.
  """
  @spec write_padded(Transport.t(), Request.slot(), binary()) :: :ok | {:error, atom()}
  def write_padded(transport, slot, data) do
    check_data_size(slot, data)

    # pad the data up to a multiple of 32
    padded_data = pad_to_32(data)

    do_write(transport, slot, 0, padded_data)
  end

  @doc """
  Pad the specified data to the exact size of the slot.
  """
  @spec pad_to_slot_size(Request.slot(), binary()) :: binary()
  def pad_to_slot_size(slot, data) do
    to_pad = slot_size(slot) - byte_size(data)

    cond do
      to_pad == 0 -> data
      to_pad > 0 -> <<data::binary, 0::unit(8)-size(to_pad)>>
    end
  end

  @doc """
  Pad the passed in data to a multiple of 32-bytes

  This is useful when 4-byte writes aren't allowed.
  """
  @spec pad_to_32(binary()) :: binary()
  def pad_to_32(data) do
    case rem(byte_size(data), 32) do
      0 ->
        data

      fraction ->
        pad_count = 32 - fraction
        data <> <<0::size(pad_count)-unit(8)>>
    end
  end

  defp check_data_size(slot, data) do
    byte_size(data) <= slot_size(slot) ||
      raise "Invalid data size (#{byte_size(data)}) for slot #{slot} (#{slot_size(slot)})"
  end

  defp do_write(_transport, _slot, _offset, <<>>), do: :ok

  defp do_write(transport, slot, offset, <<part::32-bytes, rest::binary>>) do
    addr = Request.to_data_addr(slot, offset)

    case Request.write_zone(transport, :data, addr, part) do
      :ok -> do_write(transport, slot, offset + 32, rest)
      error -> error
    end
  end

  defp do_write(transport, slot, offset, <<part::4-bytes, rest::binary>>) do
    addr = Request.to_data_addr(slot, offset)

    case Request.write_zone(transport, :data, addr, part) do
      :ok -> do_write(transport, slot, offset + 4, rest)
      error -> error
    end
  end

  @doc """
  Lock the data and OTP zones.

  The expected contents concatenated together for the non-private key data slots and
  the OTP need to be passed for a CRC calculation. They are not
  written by design. The logic is that this is a final chance before it's too
  late to check that the device is programmed correctly.
  """
  @spec lock(Transport.t(), ATECC508A.crc16()) :: :ok | {:error, atom()}
  def lock(transport, expected_contents) do
    crc = ATECC508A.CRC.crc(expected_contents)

    Request.lock_zone(transport, :data, crc)
  end

  @doc """
  Return the size in bytes of the specified slot.
  """
  @spec slot_size(Request.slot()) :: 36 | 72 | 416
  def slot_size(0), do: 36
  def slot_size(1), do: 36
  def slot_size(2), do: 36
  def slot_size(3), do: 36
  def slot_size(4), do: 36
  def slot_size(5), do: 36
  def slot_size(6), do: 36
  def slot_size(7), do: 36
  def slot_size(8), do: 416
  def slot_size(9), do: 72
  def slot_size(10), do: 72
  def slot_size(11), do: 72
  def slot_size(12), do: 72
  def slot_size(13), do: 72
  def slot_size(14), do: 72
  def slot_size(15), do: 72
end
