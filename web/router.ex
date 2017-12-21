defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router

  get  "/question", Question, :index
  post "/question", Question, :create
end
