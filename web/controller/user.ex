defmodule MasakiStackoverflow.Controller.User do
  use SolomonLib.Controller

  def index(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    query_params = [:query, :sort, :limit, :skip]
    |> Enum.each(fn param -> {param, Map.get(request.query_params, param)} end)
    |> Enum.into(%{})
    query = struct(Dodai.RetrieveUserListRequestQuery, query_params)
    req   = Dodai.RetrieveUserListRequest.new(group_id, root_key, query)
    res   = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.RetrieveUserListSuccess{body: body} ->
        render(conn, 200, "users", [body: body])
      %{code: code, name: name, description: description} ->
        render(conn, code, "users", [error: name <> ": " <> description])
    end
  end

  def show(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    %{_id: id} = request.path_matches
    req   = Dodai.RetrieveUserRequest.new(group_id, id, root_key)
    res   = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.RetrieveUserSuccess{body: body} ->
        render(conn, 200, "user", [body: body])
      %{code: code, name: name, description: description} ->
        render(conn, code, "user", [error: name <> ": " <> description])
    end
  end

  def new(conn) do
    render(conn, 200, "user_new", [])
  end
end
