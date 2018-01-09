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

  def show(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    question_id = conn.request.path_matches.id
    request = Dodai.RetrieveDedicatedDataEntityRequest.new(group_id, "question", question_id, root_key)
    %Dodai.RetrieveDedicatedDataEntitySuccess{body: question} = Sazabi.G2gClient.send(context, app_id, request)
    comments = question["data"]["comments"]
    answers = question["data"]["answers"] |> Enum.with_index() |> Enum.map(fn{map, index} -> Map.put(map, "index", index) end)

    render(conn, 200, "detail", [
      question_id: question["_id"],
      title:       question["data"]["title"],
      author:      question["data"]["author"],
      body:        question["data"]["body"],
      comments:    comments,
      answers:     answers
    ])
  end
end
