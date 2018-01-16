use Croma

defmodule MasakiStackoverflow.CreateCommentBody do
  use Croma.Struct, fields: [
    body:        MasakiStackoverflow.NonEmptyString,
    parent_type: MasakiStackoverflow.NonEmptyString,
    parent_id:   MasakiStackoverflow.NonEmptyString
  ],
  recursive_new?: true
end

defmodule MasakiStackoverflow.Controller.V1.Comment do
  use SolomonLib.Controller
  alias SolomonLib.Request

  @collection_name "comment"

  def create(%Conn{request: %Request{body: comment}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    parent_id              = Enum.at(conn1.request.path_info, -2)
    parent_collection_name = Enum.at(conn1.request.path_info, -3)
    comment_body = %{"body" => comment["value"], "parent_id" => parent_id, "parent_type" => parent_collection_name}
    validate_comment_body(conn1, comment_body, fn conn2, validated_comment_body ->
      query   = %Dodai.CreateDedicatedDataEntityRequestBody{data: validated_comment_body}
      request =  Dodai.CreateDedicatedDataEntityRequest.new(group_id, @collection_name, root_key, query)
      %Dodai.CreateDedicatedDataEntitySuccess{body: body} = Sazabi.G2gClient.send(context, app_id, request)
      comment_id = body["_id"]
      body    = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$push" => %{"comments" => comment_id}}}
      request =  Dodai.UpdateDedicatedDataEntityRequest.new(group_id, parent_collection_name, parent_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 201, %{"_id" => comment_id})
    end)
  end

  defp validate_comment_body(conn, params, func) do
    case MasakiStackoverflow.CreateCommentBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> json(conn, 403, %{})
    end
  end

  def update(%Conn{request: %Request{body: input}, context: context} = conn) do
    comment_id = conn.request.path_matches.comment_id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    case input do
      %{"value" => ""   } ->
        json(conn, 403, %{})
      %{"value" => value} ->
        body    = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$set" => %{"body" => value}}}
        request =  Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, comment_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, %{})
    end
  end

  def delete(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    comment_id  = conn.request.path_matches.comment_id
    parent_id              = Enum.at(conn.request.path_info, -3)
    parent_collection_name = Enum.at(conn.request.path_info, -4)
    query   = %Dodai.DeleteDedicatedDataEntityRequestQuery{}
    request =  Dodai.DeleteDedicatedDataEntityRequest.new(group_id, @collection_name, comment_id, root_key, query)
    %Dodai.DeleteDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    body    = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$pull" => %{"comments" => comment_id}}}
    request =  Dodai.UpdateDedicatedDataEntityRequest.new(group_id, parent_collection_name, parent_id, root_key, body)
    %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    json(conn, 204, %{})
  end
end
