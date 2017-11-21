defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router
  get "/hello", Hello, :hello
  get "/hello2", Hello2, :hello2
end
