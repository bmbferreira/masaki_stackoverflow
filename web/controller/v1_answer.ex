use Croma

defmodule MasakiStackoverflow.Controller.V1.Answer do
  use SolomonLib.Controller
  alias SolomonLib.Request

  @collection_name "answer"

  def create(%Conn{request: %Request{body: body}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    question_id  = conn1.request.path_matches.question_id
    answer_body = %{"body" => body["value"], "parent_id" => question_id, "comments" => []}
    validate_answer_body(conn1, answer_body, fn conn2, validated_answer_body ->
      query   = %Dodai.CreateDedicatedDataEntityRequestBody{data: Map.from_struct(validated_answer_body)}
      request = Dodai.CreateDedicatedDataEntityRequest.new(group_id, @collection_name, root_key, query)
      %Dodai.CreateDedicatedDataEntitySuccess{body: answer} = Sazabi.G2gClient.send(context, app_id, request)
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$push" => %{"answers" => answer["_id"]}}}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, "question", question_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 201, %{"_id" => answer["_id"]})
    end)
  end

  defp validate_answer_body(conn, params, func) do
    case MasakiStackoverflow.CreateAnswerBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> json(conn, 403, %{})
    end
  end

  def update(%Conn{request: %Request{body: input}, context: context} = conn) do
    answer_id   = conn.request.path_matches.answer_id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    case input do
      %{"value" => ""   } ->
        json(conn, 403, %{})
      %{"value" => value} ->
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$set" => %{"body" => value}}}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, answer_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, %{})
    end
  end

  def delete(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    question_id  = conn.request.path_matches.question_id
    answer_id = conn.request.path_matches.answer_id
    query = %Dodai.DeleteDedicatedDataEntityRequestQuery{}
    request = Dodai.DeleteDedicatedDataEntityRequest.new(group_id, @collection_name, answer_id, root_key, query)
    %Dodai.DeleteDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$pull" => %{"answers" => answer_id}}}
    request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, "question", question_id, root_key, body)
    %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    json(conn, 204, %{})
  end
end
