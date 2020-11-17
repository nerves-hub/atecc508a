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
    {:atecc508a, "~> 0.2.2"}
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
using an ATECC508A/ATECC608. Take a look at the device configuration section in
the [NervesKey documentation](https://github.com/nerves-hub/nerves_key). That
configuration supports authenticating TLS connections to [Nerves
Hub](https://nerves-hub.org/) and other cloud services. The `NervesKey` library
also makes provisioning the chip much easier that using this library directly.
For integrating with Erlang's TLS stack, see
[nerves_key_pkcs11](https://github.com/nerves-hub/nerves_key_pkcs11).
