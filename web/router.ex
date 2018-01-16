defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router

  static_prefix "/priv/static"
  get    "/question",        Question,    :index
  get    "/question/:id",    Question,    :show
  post   "/v1/question",     V1.Question, :create
  put    "/v1/question/:id", V1.Question, :update
  delete "/v1/question/:id", V1.Question, :delete
end
