use Croma
import Croma.TypeGen

defmodule MasakiStackoverflow.NonEmptyString do
  use Croma.SubtypeOfString, pattern: ~r/.+/
end

defmodule MasakiStackoverflow.CreateCommentBody do
  use Croma.Struct, fields: [
    body:        MasakiStackoverflow.NonEmptyString,
    parent_type: MasakiStackoverflow.NonEmptyString,
    parent_id:   MasakiStackoverflow.NonEmptyString
  ],
  recursive_new?: true
end

defmodule MasakiStackoverflow.CreateAnswerBody do
  use Croma.Struct, fields: [
    body:      MasakiStackoverflow.NonEmptyString,
    parent_id: MasakiStackoverflow.NonEmptyString,
    comments:  list_of(MasakiStackoverflow.NonEmptyString)
  ],
  recursive_new?: true
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
    method = conn1.request.method
    id = conn1.request.path_matches
    type = Enum.at(conn1.request.path_info, -1)
    case {method, id, type, input} do
      {:post,   %{},                          _,         %{"value" => ""}} ->
        json(conn1, 403, [])
      {:post,   %{},                          "comment", %{"value" => _value}} ->
        create_comment(conn1)
      {:post,   %{},                          "answer",  %{"value" => _value}} ->
        create_answer(conn1)
      {:put,    %{},                          _,         %{"value" => ""}} ->
        json(conn1, 403, [])
      {:put,    %{comment_id:  _comment_id},  _,         %{"value" => _value}} ->
        update_comment(conn1)
      {:put,    %{answer_id:  _answer_id},    _,         %{"value" => _value}} ->
        update_answer(conn1)
      {:put,    %{question_id: _question_id}, _,         %{"value" => _value}} ->
        update_body(conn1)
      {:delete, %{comment_id: _comment_id},   _,         %{}} ->
        delete_comment(conn1)
      {:delete, %{answer_id:  _answer_id},    _,         %{}} ->
        delete_answer(conn1)
      _ -> json(conn1, 403, [])
    end
  end

  defp create_answer(%Conn{request: %Request{body: answer}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    question_id  = conn1.request.path_matches.question_id
    answer_body = %{"body" => answer["value"], "parent_id" => question_id, "comments" => []}
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

  defp create_comment(%Conn{request: %Request{body: comment}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    parent_id = Enum.at(conn1.request.path_info, -2)
    parent_type = Enum.at(conn1.request.path_info, -3)
    comment_body = %{"body" => comment["value"], "parent_id" => parent_id, "parent_type" => parent_type}
    validate_comment_body(conn1, comment_body, fn conn2, validated_comment_body ->
      query   = %Dodai.CreateDedicatedDataEntityRequestBody{data: validated_comment_body}
      request = Dodai.CreateDedicatedDataEntityRequest.new(group_id, @collection_name, root_key, query)
      %Dodai.CreateDedicatedDataEntitySuccess{body: body} = Sazabi.G2gClient.send(context, app_id, request)
      comment_id = body["_id"]
      body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$push" => %{"comments" => comment_id}}}
      request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, validated_comment_body.parent_type, validated_comment_body.parent_id, root_key, body)
      %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 201, %{"_id" => comment_id})
    end)
  end

  def update_body(%Conn{request: %Request{body: input}, context: context} = conn) do
    question_id = conn.request.path_matches.question_id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    case input do
      %{"value" => ""}    ->
        json(conn, 403, %{})
      %{"value" => value} ->
        query = %{"$set" => %{"body" => value}}
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: query}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, "question", question_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, %{})
    end
  end

  defp update_answer(%Conn{request: %Request{body: input}, context: context} = conn) do
    answer_id = conn.request.path_matches.answer_id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    case input do
      %{"value" => ""   } ->
        json(conn, 403, %{})
      %{"value" => value} ->
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$set" => %{"body" => value}}}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, "answer", answer_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, %{})
    end
  end

  defp update_comment(%Conn{request: %Request{body: input}, context: context} = conn) do
    comment_id = conn.request.path_matches.comment_id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    case input do
      %{"value" => ""   } ->
        json(conn, 403, %{})
      %{"value" => value} ->
        body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$set" => %{"body" => value}}}
        request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, "comment", comment_id, root_key, body)
        %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
        json(conn, 200, %{})
    end
  end

  defp delete_answer(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    question_id  = conn.request.path_matches.question_id
    answer_id = conn.request.path_matches.answer_id
    query = %Dodai.DeleteDedicatedDataEntityRequestQuery{}
    request = Dodai.DeleteDedicatedDataEntityRequest.new(group_id, "answer", answer_id, root_key, query)
    %Dodai.DeleteDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$pull" => %{"answers" => answer_id}}}
    request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, "question", question_id, root_key, body)
    %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    json(conn, 204, %{})
  end

  defp delete_comment(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    comment_id = conn.request.path_matches.comment_id
    parent_id = Enum.at(conn.request.path_info, -3)
    parent_type = Enum.at(conn.request.path_info, -4)
    query = %Dodai.DeleteDedicatedDataEntityRequestQuery{}
    request = Dodai.DeleteDedicatedDataEntityRequest.new(group_id, "comment", comment_id, root_key, query)
    %Dodai.DeleteDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    body = %Dodai.UpdateDedicatedDataEntityRequestBody{data: %{"$pull" => %{"comments" => comment_id}}}
    request = Dodai.UpdateDedicatedDataEntityRequest.new(group_id, parent_type, parent_id, root_key, body)
    %Dodai.UpdateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    json(conn, 204, %{})
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

  def delete(%Conn{context: context} = conn) do
    question_id = conn.request.path_matches.question_id
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    query = %Dodai.DeleteDedicatedDataEntityRequestQuery{}
    request = Dodai.DeleteDedicatedDataEntityRequest.new(group_id, @collection_name, question_id, root_key, query)
    %Dodai.DeleteDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
    json(conn, 204, [])
  end
end
