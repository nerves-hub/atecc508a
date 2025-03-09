# SPDX-FileCopyrightText: 2018 Justin Schneck
#
# SPDX-License-Identifier: Apache-2.0
#
ExUnit.start()

Mox.defmock(ATECC508A.Transport.Mock, for: ATECC508A.Transport)
