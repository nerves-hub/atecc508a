# SPDX-FileCopyrightText: 2025 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Configuration.Config608 do
  defstruct [
    :serial_number,
    :rev_num,
    :aes_enable,
    :i2c_enable,
    :reserved0,
    :i2c_address,
    :reserved1,
    :count_match,
    :chip_mode,
    :slot_config,
    :counter0,
    :counter1,
    :use_lock,
    :volatile_key_permission,
    :secure_boot,
    :kdflvloc,
    :kdflvstr,
    :reserved2,
    :user_extra,
    :user_extra_add,
    :lock_value,
    :lock_config,
    :slot_locked,
    :chip_options,
    :x509_format,
    :key_config
  ]

  @type t :: %__MODULE__{
          serial_number: binary(),
          rev_num: atom() | binary(),
          aes_enable: non_neg_integer(),
          i2c_enable: non_neg_integer(),
          reserved0: byte(),
          i2c_address: Circuits.I2C.address(),
          reserved1: byte(),
          count_match: non_neg_integer(),
          chip_mode: non_neg_integer(),
          slot_config: <<_::256>>,
          counter0: non_neg_integer(),
          counter1: non_neg_integer(),
          use_lock: binary(),
          volatile_key_permission: %{key: non_neg_integer(), enabled?: boolean()},
          secure_boot: non_neg_integer(),
          kdflvloc: non_neg_integer(),
          kdflvstr: non_neg_integer(),
          reserved2: byte(),
          user_extra: non_neg_integer(),
          user_extra_add: non_neg_integer(),
          lock_value: non_neg_integer(),
          lock_config: non_neg_integer(),
          slot_locked: non_neg_integer(),
          chip_options: non_neg_integer(),
          x509_format: <<_::32>>,
          key_config: <<_::256>>
        }

  def fields do
    [
      serial_number_1: 4,
      rev_num: 4,
      serial_number_2: 5,
      aes_enable: 1,
      i2c_enable: 1,
      reserved0: 1,
      i2c_address: 1,
      reserved1: 1,
      count_match: 1,
      chip_mode: 1,
      slot_config: 32,
      counter0: 8,
      counter1: 8,
      use_lock: 1,
      volatile_key_permission: 1,
      secure_boot: 2,
      kdflvloc: 1,
      kdflvstr: 2,
      reserved2: 9,
      user_extra: 1,
      user_extra_add: 1,
      lock_value: 1,
      lock_config: 1,
      slot_locked: 2,
      chip_options: 2,
      x509_format: 4,
      key_config: 32
    ]
  end

  def bin_fields do
    [
      :serial_number,
      :reserved0,
      :reserved1,
      :reserved2,
      :slot_config,
      :use_lock,
      :reserved2,
      :x509_format,
      :key_config
    ]
  end
end
