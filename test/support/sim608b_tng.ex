# SPDX-FileCopyrightText: 2022 Digit
# SPDX-FileCopyrightText: 2024 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Sim608BTNG do
  @moduledoc """
  A module that returns values extracted from a Trust and Go (ATECC608B-TNGTLS) development kit
  Used to test certificate decompression.
  """

  @spec device_cert() :: binary()
  def device_cert() do
    # Read from slot 10
    <<225, 151, 170, 38, 210, 208, 172, 148, 171, 77, 236, 194, 48, 85, 79, 86, 17, 205, 83, 174,
      36, 173, 26, 226, 115, 126, 162, 214, 158, 202, 162, 173, 37, 208, 92, 14, 110, 165, 28, 96,
      62, 90, 91, 132, 224, 76, 171, 81, 38, 198, 189, 179, 124, 137, 6, 161, 89, 96, 108, 52,
      130, 176, 36, 175, 165, 172, 156, 44, 0, 48, 160, 0>>
  end

  @spec genkey() :: binary()
  def genkey() do
    <<211, 48, 184, 178, 237, 228, 213, 2, 223, 72, 181, 74, 47, 41, 204, 121, 249, 1, 229, 148,
      253, 107, 249, 45, 235, 109, 24, 122, 199, 127, 45, 187, 177, 96, 39, 154, 74, 32, 167, 230,
      227, 80, 127, 151, 58, 173, 67, 145, 155, 239, 45, 28, 153, 178, 156, 21, 51, 35, 223, 205,
      153, 16, 103, 105>>
  end

  @spec signer_cert() :: binary()
  def signer_cert() do
    # Read from slot 12
    <<236, 201, 73, 152, 143, 97, 145, 48, 185, 39, 115, 34, 149, 140, 253, 169, 125, 155, 10,
      140, 184, 243, 120, 148, 188, 196, 115, 233, 212, 122, 64, 135, 33, 35, 213, 162, 86, 107,
      137, 161, 89, 188, 138, 141, 229, 34, 131, 206, 22, 181, 51, 123, 42, 37, 153, 175, 228,
      215, 94, 250, 7, 62, 214, 17, 150, 58, 159, 44, 0, 16, 160, 0>>
  end

  @spec signer_pubkey() :: binary()
  def signer_pubkey() do
    # Read from slot 11
    <<0, 0, 0, 0, 46, 186, 27, 42, 208, 183, 62, 78, 68, 114, 94, 12, 9, 52, 141, 64, 146, 160,
      139, 215, 168, 183, 97, 155, 253, 199, 165, 110, 178, 5, 75, 220, 0, 0, 0, 0, 163, 56, 240,
      13, 198, 77, 236, 29, 132, 180, 179, 110, 198, 36, 38, 189, 76, 147, 64, 36, 79, 168, 83,
      226, 53, 208, 83, 192, 93, 246, 126, 244>>
  end

  @spec mac() :: binary()
  def mac() do
    # Read from slot 5
    <<69, 56, 69, 66, 49, 66, 50, 48, 50, 48, 50, 55>>
  end

  @spec serial_number() :: binary()
  def serial_number() do
    # Read from the configuration zone
    <<1, 35, 162, 63, 41, 249, 54, 106, 1>>
  end
end
