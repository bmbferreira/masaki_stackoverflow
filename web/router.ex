defmodule MasakiStackoverflow.Router do
  use SolomonLib.Router

  static_prefix "/priv/static"
  get    "/question",              Question, :index
  get    "/question/:question_id", Question, :show

  post   "/v1/question",              V1.Question, :create
  put    "/v1/question/:question_id", V1.Question, :update
  delete "/v1/question/:question_id", V1.Question, :delete

  post   "/v1/question/:question_id/comment",             V1.Question, :update
  put    "/v1/question/:question_id/comment/:comment_id", V1.Question, :update
  delete "/v1/question/:question_id/comment/:comment_id", V1.Question, :update

  post   "/v1/question/:question_id/answer",              V1.Question, :update
  put    "/v1/question/:question_id/answer/:answer_id",   V1.Question, :update
  delete "/v1/question/:question_id/answer/:answer_id",   V1.Question, :update

  post   "/v1/question/:question_id/answer/:answer_id/comment",             V1.Question, :update
  put    "/v1/question/:question_id/answer/:answer_id/comment/:comment_id", V1.Question, :update
  delete "/v1/question/:question_id/answer/:answer_id/comment/:comment_id", V1.Question, :update
end
