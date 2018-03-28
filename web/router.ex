defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router

  post    "/v1/user"           , V1.User, :create
  post    "/v1/user/:id/login" , V1.User, :login
  post    "/v1/user/:id/logout", V1.User, :logout
  put     "/v1/user/:id"       , V1.User, :update
  delete  "/v1/user/:id"       , V1.User, :delete

  get    "/user",          User,      :index
  post   "/user",          User,      :create

  get    "/question",        Question,    :index
  get    "/question/:id",    Question,    :show
  post   "/v1/question",     V1.Question, :create
  put    "/v1/question/:id", V1.Question, :update
  delete "/v1/question/:id", V1.Question, :delete
end
