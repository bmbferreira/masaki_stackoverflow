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

defmodule MasakiStackoverflow.CreateKey do
  use Croma.SubtypeOfString, pattern: ~r/answers|comments|answers\.[0-9]+\.comments/
end

defmodule MasakiStackoverflow.UpdateKey do
  use Croma.SubtypeOfString, pattern: ~r/title|body|(answers|comments|answers\.[0-9]+\.comments)\.[0-9]+\.body/
end

defmodule MasakiStackoverflow.DeleteKey do
  use Croma.SubtypeOfString, pattern: ~r/(answers|comments|answers\.[0-9]+\.comments)\.[0-9]+\.visible/
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

  def update(%Conn{request: %Request{body: input}} = conn1) do
    case input do
      %{"operator" => "create", "key" => "answers"} ->
        create_answer(conn1)
      %{"operator" => "create"} ->
        create_comment(conn1)
      %{"operator" => "update", "value" => ""} ->
        json(conn1, 403, [])
      %{"operator" => "update", "key" => "title"} ->
        update_title(conn1)
      %{"operator" => "update", "key" => "body"} ->
        update_body(conn1)
      %{"operator" => "update", "key" => "answers"} ->
        update_answer(conn1)
      %{"operator" => "update"} ->
        update_comment(conn1)
      %{"operator" => "delete", "key" => "answers"} ->
        delete_answer(conn1)
      %{"operator" => "delete"} ->
        delete_comment(conn1)
      _ -> json(conn1, 403, [])
    end
  end

  defp create_answer(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    answer_body = %{"_id" => set_id(), "author" => get_author(), "body" => input["value"], "comments" => [], "visible" => :true}
    create_key = input["key"]
    validate_answer_body(conn1, answer_body, fn conn2, validated_answer_body ->
      validate_create_key(conn2, create_key, fn conn3, validated_create_key ->
        query = %{"$push" => %{validated_create_key => validated_answer_body}}
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn3, 200, [])
      end)
    end)
  end

  defp create_comment(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    comment_body = %{"_id" => set_id(), "author" => get_author(), "body" => input["value"], "visible" => :true}
    create_key = input["key"]
    validate_comment_body(conn1, comment_body, fn conn2, validated_comment_body ->
      validate_create_key(conn2, create_key, fn conn3, validated_create_key ->
        query = %{"$push" => %{validated_create_key => validated_comment_body}}
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn3, 200, [])
      end)
    end)
  end

  defp update_title(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    update_key = input["key"]
    validate_update_key(conn1, update_key, fn conn2, validated_update_key ->
      query = %{"$set" => %{validated_update_key => input["value"]}}
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 200, [])
    end)
  end

  defp update_body(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    update_key = input["key"]
    validate_update_key(conn1, update_key, fn conn2, validated_update_key ->
      query = %{"$set" => %{validated_update_key => input["value"]}}
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 200, [])
    end)
  end

  defp update_answer(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    update_key = input["key"]
    validate_update_key(conn1, update_key, fn conn2, validated_update_key ->
      query = %{"$set" => %{validated_update_key => input["value"]}}
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 200, [])
    end)
  end

  defp update_comment(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    update_key = input["key"]
    validate_update_key(conn1, update_key, fn conn2, validated_update_key ->
      query = %{"$set" => %{validated_update_key => input["value"]}}
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 200, [])
    end)
  end

  defp delete_answer(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    delete_key = input["key"]
    validate_delete_key(conn1, delete_key, fn conn2, validated_delete_key ->
      query = %{"$set" => %{validated_delete_key => :false}}
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 200, [])
    end)
  end

  defp delete_comment(%Conn{request: %Request{body: input}, context: context} = conn1) do
    question_id = conn1.request.path_matches.id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    delete_key = input["key"]
    validate_delete_key(conn1, delete_key, fn conn2, validated_delete_key ->
      query = %{"$set" => %{validated_delete_key => :false}}
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 200, [])
    end)
  end

  defp validate_create_key(conn, key, func) do
    if MasakiStackoverflow.CreateKey.valid?(key) do
      func.(conn, key)
    else
      json(conn, 403, [])
    end
  end

  defp validate_update_key(conn, key, func) do
    if MasakiStackoverflow.UpdateKey.valid?(key) do
      func.(conn, key)
    else
      json(conn, 403, [])
    end
  end

  defp validate_delete_key(conn, key, func) do
    if MasakiStackoverflow.DeleteKey.valid?(key) do
      func.(conn, key)
    else
      json(conn, 403, [])
    end
  end

  defp validate_answer_body(conn, params, func) do
    case MasakiStackoverflow.CreateAnswerBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> json(conn, 403, [])
    end
  end

  defp validate_comment_body(conn, params, func) do
    case MasakiStackoverflow.CreateCommentBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> json(conn, 403, [])
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
