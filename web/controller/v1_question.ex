use Croma
import Croma.TypeGen

defmodule MasakiStackoverflow.NonEmptyString do
  use Croma.SubtypeOfString, pattern: ~r/.+/
end

defmodule MasakiStackoverflow.CreateCommentBody do
  use Croma.Struct, fields: [
    _id:     MasakiStackoverflow.NonEmptyString,
    author:  MasakiStackoverflow.NonEmptyString,
    body:    MasakiStackoverflow.NonEmptyString,
    visible: Croma.Boolean
  ],
  recursive_new?: true
end

defmodule MasakiStackoverflow.CreateAnswerBody do
  use Croma.Struct, fields: [
    _id:    MasakiStackoverflow.NonEmptyString,
    author: MasakiStackoverflow.NonEmptyString,
    body:   MasakiStackoverflow.NonEmptyString,
    comments: list_of(MasakiStackoverflow.CreateCommentBody),
    visible: Croma.Boolean
  ],
  recursive_new?: true
end

defmodule MasakiStackoverflow.CreateQuestionBody do
  use Croma.Struct, fields: [
    title:  MasakiStackoverflow.NonEmptyString,
    author: MasakiStackoverflow.NonEmptyString,
    body:   MasakiStackoverflow.NonEmptyString,
    answers: list_of(MasakiStackoverflow.CreateAnswerBody),
    comments: list_of(MasakiStackoverflow.CreateCommentBody)
  ],
  recursive_new?: true
end

defmodule MasakiStackoverflow.Controller.V1.Question do
  use SolomonLib.Controller
  alias SolomonLib.Request

  @collection_name "question"

  def create(%Conn{request: %Request{body: question_body}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    question_body = question_body |> Map.put("answers", []) |> Map.put("comments", [])
    validate_question_body(conn1, question_body, fn conn2, validated_question_body ->
      query   = %Dodai.CreateDedicatedDataEntityRequestBody{data: Map.from_struct(validated_question_body)}
      request = Dodai.CreateDedicatedDataEntityRequest.new(group_id, @collection_name, root_key, query)
      %Dodai.CreateDedicatedDataEntitySuccess{body: body} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 201, %{"id" => body["_id"]})
    end)
  end

  defp validate_question_body(conn, params, func) do
    case MasakiStackoverflow.CreateQuestionBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> json(conn, 403, [])
    end
  end

  def update(%Conn{request: %Request{body: input}, context: context} = conn) do
    question_id = conn.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    case input do
      %{"operator" => "create", "key" => "answers"} ->
        answer_body = %{"_id" => set_id(), "author" => get_author(), "body" => input["value"], "comments" => [], "visible" => :true}
        query = %{"$push" => %{input["key"] => answer_body}}
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, [])
      %{"operator" => "create"} ->
        comment_body = %{"_id" => set_id(), "author" => get_author(), "body" => input["value"], "visible" => :true}
        query = %{"$push" => %{input["key"] => comment_body}}
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, [])
      %{"operator" => "update", "value" => ""} ->
        json(conn, 403, [])
      %{"operator" => "update"} ->
        query = %{"$set" => %{input["key"] => input["value"]}}
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, [])
      %{"operator" => "delete"} ->
        query = %{"$set" => %{input["key"] => :false}}
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, [])
      _ -> json(conn, 403, [])
    end
  end

  def set_id() do
    "author" <> "-" <> (DateTime.utc_now() |> DateTime.to_iso8601())
  end

  def get_author() do
    "author"
  end

  def delete(%Conn{context: context} = conn) do
    question_id = conn.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    query = %Dodai.DeleteDedicatedDataEntityRequestQuery{}
    request = Dodai.DeleteDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, query)
    %Dodai.DeleteDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    json(conn, 204, [])
  end
end
