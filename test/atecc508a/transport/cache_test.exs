defmodule ATECC508A.Transport.CacheTest do
  use ExUnit.Case

  alias ATECC508A.Transport.Cache

  test "caches reads" do
    req = <<2, 0, 0, 0>>
    resp = {:ok, <<1>>}

    cache = Cache.init()
    assert Cache.get(cache, req) == nil

    cache = Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == resp
  end

  test "cache genkey public key calculation " do
    req = <<0x40, 0, 1, 0>>
    resp = {:ok, <<1, 2, 3, 4, 5>>}

    cache = Cache.init()
    assert Cache.get(cache, req) == nil

    cache = Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == resp
  end

  test "doesn't cache genkey creation" do
    req = <<0x40, 1, 1, 0>>
    resp = {:ok, <<1, 2, 3, 4, 5>>}

    cache = Cache.init()
    assert Cache.get(cache, req) == nil

    cache = Cache.put(cache, req, resp)
    assert Cache.get(cache, req) == nil
  end

  test "writes clear the cache" do
    read_req = <<2, 0, 0, 0>>
    write_req = <<0x12, 0, 0, 0>>
    resp = {:ok, <<1>>}

    cache = Cache.init()
    assert Cache.get(cache, read_req) == nil

    cache = Cache.put(cache, read_req, resp)
    assert Cache.get(cache, read_req) == resp

    cache = Cache.put(cache, write_req, resp)
    assert cache == %{}
  end
end
