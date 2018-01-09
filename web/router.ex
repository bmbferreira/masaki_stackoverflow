defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router

  get  "/question",     Question,    :index
  get  "/question/:id", Question,    :show
  post "/v1/question",  V1.Question, :create
end
