defmodule MasakiStackoverflow.Controller.User do
  use SolomonLib.Controller

  def index(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    #%{_id: id} = conn.request.path_matches
    query_params = [:query, :sort, :limit, :skip]
    |> Enum.each(fn param -> {param, Map.get(request.query_params, param)} end)
    |> Enum.into(%{})
    query = struct(Dodai.RetrieveUserListRequestQuery, query_params)
    req   = Dodai.RetrieveUserListRequest.new(group_id, root_key, query)
    res   = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.RetrieveUserListSuccess{body: body} ->
        render_page(conn, 201, [body: body])
      %Dodai.ValidationError{} ->
        render_page(conn, 400, [error: "Invalid parameter."])
      %Dodai.AuthenticationIDAlreadyTaken{} ->
        render_page(conn, 409, [error: "The given authentication ID is already taken."])
    end
    render_page(conn, 200, [])
  end

  def create(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"email" => email, "password" => password} = request.body
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    req_body = %Dodai.CreateUserRequestBody{email: email, password: password}
    req      = Dodai.CreateUserRequest.new(group_id, root_key, req_body)
    res      = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.CreateUserSuccess{} ->
        %Dodai.Model.User{session: session} = Dodai.Model.User.from_response(res)
        conn
        |> put_resp_cookie("user_credential", session.key)
        |> put_resp_cookie("email", email)
        |> render_page(201, [redirect_path: "/question"])
      %Dodai.ValidationError{} ->
        render_page(conn, 400, [error: "Invalid parameter."])
      %Dodai.AuthenticationIDAlreadyTaken{} ->
        render_page(conn, 409, [error: "The given authentication ID is already taken."])
    end
  end

  defp render_page(conn, status, params) do
    render(conn, status, "signup", Keyword.merge([email: nil, error: nil], params))
  end
end