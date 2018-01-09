defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router

  get  "/question",    Question,    :index
  post "/v1/question", V1.Question, :create
end
