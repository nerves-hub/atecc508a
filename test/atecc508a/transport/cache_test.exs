# SPDX-FileCopyrightText: 2019 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Alex McLain
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Transport.CacheTest do
  use ExUnit.Case

  alias ATECC508A.Transport.Cache

  test "caches reads" do
    req = <<2, 0, 0, 0>>
    resp = {:ok, <<1, 2, 3, 4>>}

    {:ok, cache} = Cache.start_link()
    assert Cache.get(cache, req) == nil

    Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == resp
  end

  test "doesn't cache failed reads" do
    req = <<2, 0, 0, 0>>
    resp = {:ok, <<1>>}

    {:ok, cache} = Cache.start_link()
    assert Cache.get(cache, req) == nil

    Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == nil
  end

  test "cache genkey public key calculation" do
    req = <<0x40, 0, 1, 0>>

    resp =
      {:ok,
       <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
         25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
         47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64>>}

    {:ok, cache} = Cache.start_link()
    assert Cache.get(cache, req) == nil

    Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == resp
  end

  test "doesn't cache genkey creation" do
    req = <<0x40, 1, 1, 0>>

    resp =
      {:ok,
       <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
         25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
         47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64>>}

    {:ok, cache} = Cache.start_link()
    assert Cache.get(cache, req) == nil

    Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == nil
  end

  test "doesn't cache genkey failures" do
    req = <<0x40, 0, 1, 0>>
    resp = {:ok, <<1>>}

    {:ok, cache} = Cache.start_link()
    assert Cache.get(cache, req) == nil

    Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == nil
  end

  test "writes clear the cache" do
    read_req = <<2, 0, 0, 0>>
    read_resp = {:ok, <<1, 2, 3, 4>>}
    write_req = <<0x12, 0, 0, 0>>
    write_resp = {:ok, <<0>>}

    {:ok, cache} = Cache.start_link()
    assert Cache.get(cache, read_req) == nil

    Cache.put(cache, read_req, read_resp)
    assert Cache.get(cache, read_req) == read_resp

    Cache.put(cache, write_req, write_resp)
    assert Cache.get(cache, write_req) == nil
    assert Cache.get(cache, read_req) == nil
  end
end
