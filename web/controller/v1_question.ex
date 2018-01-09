use Croma

defmodule MasakiStackoverflow.NonEmptyString do
  use Croma.SubtypeOfString, pattern: ~r/.+/
end

defmodule MasakiStackoverflow.CreateQuestionBody do
  use Croma.Struct, fields: [
    title:  MasakiStackoverflow.NonEmptyString,
    author: MasakiStackoverflow.NonEmptyString,
    body:   MasakiStackoverflow.NonEmptyString,
  ],
  recursive_new?: true
end

defmodule MasakiStackoverflow.Controller.V1.Question do
  use SolomonLib.Controller
  alias SolomonLib.Request

  @collection_name "question"

  def create(%Conn{request: %Request{body: params}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    validate_params(conn1, params, fn conn2, validated_params ->
      query   = %Dodai.CreateDedicatedDataEntityRequestBody{data: Map.from_struct(validated_params)}
      request = Dodai.CreateDedicatedDataEntityRequest.new(group_id, @collection_name, root_key, query)
      %Dodai.CreateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      json(conn2, 201, %{})
    end)
  end

  defp validate_params(conn, params, func) do
    case MasakiStackoverflow.CreateQuestionBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> json(conn, 403, [])
    end
  end
end
