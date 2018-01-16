defmodule MasakiStackoverflow.Controller.Question do
  use SolomonLib.Controller

  @collection_name "question"

  def index(%Conn{context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    # TODO: Pagination into 1000 documents is needed.
    query   = %Dodai.RetrieveDedicatedDataEntityListRequestQuery{query: %{}, sort: %{"createdAt": -1}}
    request =  Dodai.RetrieveDedicatedDataEntityListRequest.new(group_id, @collection_name, root_key, query)
    %Dodai.RetrieveDedicatedDataEntityListSuccess{body: body} = Sazabi.G2gClient.send(context, app_id, request)
    render(conn, 200, "question", [questions: body])
  end

  def show(%Conn{context: context} = conn) do
    question_id = conn.request.path_matches.question_id
    question    = get_document(context, "question", question_id)
    comments    = Enum.map(question["data"]["comments"], fn comment_id -> get_document(context, "comment", comment_id) end)
    answers     = Enum.map(question["data"]["answers"] , fn answer_id ->
      answer   = get_document(context, "answer", answer_id)
      comments = Enum.map(answer["data"]["comments"], fn comment_id -> get_document(context, "comment", comment_id) end)
      Map.put(answer, "data", Map.put(answer["data"], "comments", comments))
    end)
    render(conn, 200, "detail", [
      question_id: question["_id"],
      author:      question["owner"],
      title:       question["data"]["title"],
      body:        question["data"]["body"],
      comments:    comments,
      answers:     answers
    ])
  end

  defp get_document(context, collection_name, id) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    request = Dodai.RetrieveDedicatedDataEntityRequest.new(group_id, collection_name, id, root_key)
    %Dodai.RetrieveDedicatedDataEntitySuccess{body: body} = Sazabi.G2gClient.send(context, app_id, request)
    body
  end
end
