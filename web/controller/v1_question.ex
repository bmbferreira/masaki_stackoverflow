use Croma
import Croma.TypeGen

defmodule MasakiStackoverflow.NonEmptyString do
  use Croma.SubtypeOfString, pattern: ~r/.+/
end

defmodule MasakiStackoverflow.CreateQuestionBody do
  use Croma.Struct, fields: [
    title:    MasakiStackoverflow.NonEmptyString,
    body:     MasakiStackoverflow.NonEmptyString,
    answers:  list_of(MasakiStackoverflow.NonEmptyString),
    comments: list_of(MasakiStackoverflow.NonEmptyString)
  ],
  recursive_new?: true
end

defmodule MasakiStackoverflow.Controller.V1.Question do
  use SolomonLib.Controller
  alias SolomonLib.Request

  @collection_name "question"

  def create(%Conn{request: %Request{body: input}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    question_body = Map.put(input,         "answers",  [])
    question_body = Map.put(question_body, "comments", [])
    validate_question_body(conn1, question_body, fn conn2, validated_question_body ->
      query   = %Dodai.CreateDedicatedDataEntityRequestBody{data: validated_question_body}
      request =  Dodai.CreateDedicatedDataEntityRequest.new(group_id, @collection_name, root_key, query)
      %Dodai.CreateDedicatedDataEntitySuccess{body: response} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 201, %{"_id" => response["_id"]})
    end)
  end

  defp validate_question_body(conn, params, func) do
    case MasakiStackoverflow.CreateQuestionBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> json(conn, 403, %{})
    end
  end

  def update(%Conn{request: %Request{body: input}, context: context} = conn) do
    question_id = conn.request.path_matches.question_id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    case input do
      %{"value" => ""   } ->
        json(conn, 403, %{})
      %{"value" => value} ->
        query   = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$set" => %{"body" => value}}}
        request =  Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, query)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, %{})
    end
  end

  def delete(%Conn{context: context} = conn) do
    question_id = conn.request.path_matches.question_id
    question = get_document(context, "question", question_id)
    Enum.map(question["data"]["comments"], fn comment_id -> delete_document(context, "comment", comment_id) end)
    Enum.map(question["data"]["answers"],  fn answer_id ->
      answer = get_document(context, "answer", answer_id)
      Enum.map(answer["data"]["comments"], fn comment_id -> delete_document(context, "comment", comment_id) end)
      delete_document(context, "answer", answer_id)
    end)
    delete_document(context, "question", question_id)
    json(conn, 204, %{})
  end

  defp get_document(context, collection_name, id) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    request = Dodai.RetrieveDedicatedDataEntityRequest.new(group_id, collection_name, id, root_key)
    %Dodai.RetrieveDedicatedDataEntitySuccess{body: response} = Sazabi.G2gClient.send(context, app_id, request)
    response
  end

  defp delete_document(context, collection_name, id) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    request = Dodai.DeleteDedicatedDataEntityRequest.new(group_id, collection_name, id, root_key)
    %Dodai.DeleteDedicatedDataEntitySuccess{body: response} = Sazabi.G2gClient.send(context, app_id, request)
    response
  end
end
