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

defmodule MasakiStackoverflow.Controller.Question do
  use SolomonLib.Controller
  alias SolomonLib.Request

  @collection_name "question"

  def index(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    # TODO: Pagination into 1000 documents is needed.
    query   = %Dodai.RetrieveDedicatedDataEntityListRequestQuery{query: %{}, sort: %{"updatedAt": -1}}
    request = Dodai.RetrieveDedicatedDataEntityListRequest.new(group_id, @collection_name, root_key, query)
    %Dodai.RetrieveDedicatedDataEntityListSuccess{body: body} = Sazabi.G2gClient.send(context, app_id, request)
    render(conn, 200, "question", [questions: body])
  end

  def create(%Conn{request: %Request{body: params}, context: context} = conn1) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    validate_params(conn1, params, fn conn2, validated_params ->
      query   = %Dodai.CreateDedicatedDataEntityRequestBody{data: Map.from_struct(validated_params)}
      request = Dodai.CreateDedicatedDataEntityRequest.new(group_id, @collection_name, root_key, query)
      %Dodai.CreateDedicatedDataEntitySuccess{} = Sazabi.G2gClient.send(context, app_id, request)
      redirect(conn2, "/question")
    end)
  end

  defp validate_params(conn, params, func) do
    case MasakiStackoverflow.CreateQuestionBody.new(params) do
      {:ok   , validated} -> func.(conn, validated)
      {:error, _        } -> redirect(conn, "/question")
    end
  end
end
