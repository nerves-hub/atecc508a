# SPDX-FileCopyrightText: 2019 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      ATECC508A.Transport.I2CSupervisor
    ]

    opts = [strategy: :one_for_one, name: ATECC508A.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
