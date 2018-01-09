defmodule MasakiStackoverflow.Controller.Question do
  use SolomonLib.Controller

  @collection_name "question"

  def index(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    # TODO: Pagination into 1000 documents is needed.
    query   = %Dodai.RetrieveDedicatedDataEntityListRequestQuery{query: %{}, sort: %{"createdAt": -1}}
    request = Dodai.RetrieveDedicatedDataEntityListRequest.new(group_id, @collection_name, root_key, query)
    %Dodai.RetrieveDedicatedDataEntityListSuccess{body: body} = Sazabi.G2gClient.send(context, app_id, request)
    render(conn, 200, "question", [questions: body])
  end
end
