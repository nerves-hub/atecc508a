# ATECC508A

[![CircleCI](https://circleci.com/gh/nerves-hub/atecc508a.svg?style=svg)](https://circleci.com/gh/nerves-hub/atecc508a)
[![Hex version](https://img.shields.io/hexpm/v/atecc508a.svg "Hex version")](https://hex.pm/packages/atecc508a)

The [ATECC508A Crypto Authentication](https://www.microchip.com/wwwproducts/en/ATECC508A)
(or the newer ATECC608A) is the main component of the NervesKey. If your device
needs to authenticate with NervesHub or another cloud service using client-side
SSL, this library could be of interest. The higher level
[NervesKey](https://github.com/nerves-hub/nerves_key) package will likely make
more sense and you're recommended to start there.

## Installation

The package can be installed by adding `atecc508a` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:atecc508a, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/atecc508a](https://hexdocs.pm/atecc508a).

## Quick start

Connect an ATECC508A or ATECC608A to an I2C bus on your device. If this is a new
device, it won't be configured and therefore it can't do much exciting. You can
still read the configuration block, though. Here's a walk-through:

```elixir
iex> {:ok, i2c} = ATECC508A.Transport.I2C.init(bus_name: "i2c-1")
{:ok, {ATECC508A.Transport.I2C, {#Reference<0.713213266.268828681.225043>, 96}}}
iex> ATECC508A.Configuration.read(i2c)
{:ok,
 %ATECC508A.Configuration{
   chip_mode: 0,
   counter0: 4294967295,
   counter1: 4294967295,
   i2c_address: 192,
   i2c_enable: 85,
   key_config: <<51, 0, 51, 0, 51, 0, 28, 0, 28, 0, 28, 0, 28, 0, 28, 0, 60, 0,
     60, 0, 60, 0, 60, 0, 60, 0, 60, 0, 60, 0, 28, 0>>,
   last_key_use: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
   lock_config: 85,
   lock_value: 85,
   otp_mode: 0,
   reserved0: 193,
   reserved1: 0,
   reserved2: 0,
   rev_num: :ecc608a_1,
   rfu: <<0, 0>>,
   selector: 0,
   serial_number: <<1, 35, 185, 8, 198, 142, 22, 255, 238>>,
   slot_config: <<131, 32, 135, 32, 143, 32, 196, 143, 143, 143, 143, 143, 159,
     143, 175, 143, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...>>,
   slot_locked: 65535,
   user_extra: 0,
   x509_format: <<0, 0, 0, 0>>
 }}
```

Most functions in this library end up in `ATECC508A.Request`, but there are many
modules that make working with the device easier elsewhere.

## Device configuration

Figuring out how to configure this devices is perhaps the most consuming part of
using an ATECC508A/ATECC608. This section describes the configuration used on
the [NervesKey](https://github.com/nerves-hub/nerves_key) which is used to
authenticate connections to [Nerves Hub](https://nerves-hub.org/) and other
cloud services. Most users will want to use that library for provisioning
devices. For integrating with Erlang's TLS stack, see
[nerves_key_pkcs11](https://github.com/nerves-hub/nerves_key_pkcs11).

See Table 2-5 in the ATECC508A data sheet for documentation on the configuration
zone.  This software expects the following configuration to be programmed
(unspecified bytes are either not programmable or kept as their
defaults):

Bytes  | Name        | Value  | Description
-------|-------------|--------|------------
14     | I2C_Enable  | 01     | I2C mode
16     | I2C_Address | C0     | I2C address of the module (default)
18     | OTPmode     | AA     | OTP is in read-only mode
19     | ChipMode    | 00     | Default mode
20-51  | SlotConfig  | N/A    | See the next table
92-95  | X509Format  | 00..00 | Unused
96-127 | KeyConfig   | N/A    | See next table

The slots will be programmed as follows. This definition is organized to be
similar to the Microchip Standard TLS Configuration for the used slots to
minimize changes to software. Unused slots are configured so that applications
can use them as they would an EEPROM.

Slot | Description                       | SlotConfig | KeyConfig | Primary properties
-----|-----------------------------------|------------|-----------|-------------------
0    | Device private key                | 87 20      | 33 00     | Private key, read only; lockable
1    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
2    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
3    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
4    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
5    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
6    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
7    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
8    | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable
9    | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable
10   | Device certificate                | 0F 2F      | 3C 00     | Clear read only; lockable
11   | Signer public key                 | 0F 2F      | 30 00     | P256; Clear read only; lockable
12   | Signer certificate                | 0F 2F      | 3C 00     | Clear read only; lockable
13   | Signer serial number+             | 0F 2F      | 3C 00     | Clear read only; lockable
14   | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable
15   | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable

+ The signer serial number slot is currently unused since the signer's cert is
  computed from the public key

The ATECC508A includes a 64 byte OTP (one-time programmable) memory. It has the
following layout:

Bytes  | Name              | Contents
-------|-------------------|--------------------------
0-3    | Magic             | 4e 72 76 73
4-5    | Flags             | TBD. Set to 0
6-15   | Board name        | 10 byte name for the board in ASCII (set unused bytes to 0)
16-31  | Mfg serial number | 16 byte manufacturer-assigned serial number in ASCII (set unused bytes to 0)
32-63  | User              | These are unassigned
