defmodule ATECC508A.Transport.I2CTest do
  use ExUnit.Case

  alias ATECC508A.Transport.I2CServer

  test "package request" do
    message = <<0, 1, 2, 3>>
    message_crc = ATECC508A.CRC.crc(<<7, message::binary>>)
    expected = <<3, 7, message::binary, message_crc::binary>>

    assert IO.iodata_to_binary(I2CServer.package(message)) == expected
  end

  test "unpackage response" do
    message = <<0, 1, 2, 3>>
    message_crc = ATECC508A.CRC.crc(<<7, message::binary>>)
    raw_response = <<7, message::binary, message_crc::binary>>

    assert I2CServer.unpackage(raw_response) == {:ok, message}
  end

  test "unpackage corrupt response" do
    message = <<0, 1, 2, 3>>
    message_crc = <<0, 0>>
    raw_response = <<7, message::binary, message_crc::binary>>

    assert I2CServer.unpackage(raw_response) == {:error, :bad_crc}
  end

  test "unpackage response with extra stuff" do
    message = <<0, 1, 2, 3>>
    message_crc = ATECC508A.CRC.crc(<<7, message::binary>>)
    raw_response = <<7, message::binary, message_crc::binary, 0::size(32)>>

    assert I2CServer.unpackage(raw_response) == {:ok, message}
  end

  test "unpackage short response" do
    raw_response = <<7, 0>>

    assert I2CServer.unpackage(raw_response) == {:error, :short_packet}
  end
end
