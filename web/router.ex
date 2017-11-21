defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router

  get "/hello2", Hello2, :hello2
end
