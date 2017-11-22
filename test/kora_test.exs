defmodule KoraTest do
  use ExUnit.Case
  doctest Kora
  # doctest Kora.Dynamic
  doctest Kora.Mutation

  test "the truth" do
    assert 1 + 1 == 2
  end
end
