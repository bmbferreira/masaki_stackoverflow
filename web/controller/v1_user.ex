defmodule MasakiStackoverflow.Controller.V1.User do
  use SolomonLib.Controller

  def create(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    redirect = request.query_params.redirect
    %{"email" => email, "password" => password} = request.body
    req_body = %Dodai.CreateUserRequestBody{email: email, password: password}
    req      = Dodai.CreateUserRequest.new(group_id, root_key, req_body)
    res      = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.CreateUserSuccess{body: body} ->
        conn
        |> put_resp_cookie("user_credential", body.session.key)
        |> put_resp_cookie("email", email)
        |> json(201, [redirect: redirect])
      %{code: code, name: name, description: description} ->
        json(conn, code, [error: name <> ": " <> description, redirect: redirect])
    end
  end

  def login(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    redirect = request.query_params.redirect
    %{"email" => email, "password" => password} = request.body
    req_body = %Dodai.UserLoginRequestBody{email: email, password: password}
    req      = Dodai.UserLoginRequest.new(group_id, root_key, req_body)
    res      = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.UserLoginSuccess{body: body} ->
        conn
        |> put_resp_cookie("user_credential", body.session.key)
        |> put_resp_cookie("email", email)
        |> json(200, [redirect: redirect])
      %{code: code, name: name, description: description} ->
        json(conn, code, [error: name <> ": " <> description, redirect: redirect])
    end
  end

  def logout(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    redirect = request.query_params.redirect
    %{_id: id} = request.path_matches
    req      = Dodai.UserLogoutRequest.new(group_id, id, root_key, req_body)
    res      = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.UserLogoutSuccess{} ->
        json(conn, 204, [redirect: redirect])
      %{code: code, name: name, description: description} ->
        json(conn, code, [error: name <> ": " <> description, redirect: redirect])
    end
  end

  def update(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    %{_id: id} = request.path_matches
    req_body = %Dodai.UpdateUserRequestBody{data: request.body}
    req      = Dodai.UpdateUserRequest.new(group_id, id, root_key, req_body)
    res      = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.UpdateUserSuccess{} ->
        json(conn, 201, [])
      %{code: code, name: name, description: description} ->
        json(conn, code, [error: name <> ": " <> description])
    end
  end

  def delete(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    redirect = request.query_params.redirect
    %{_id: id} = request.path_matches
    req      = Dodai.DeleteUserRequest.new(group_id, id, root_key)
    res      = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.DeleteUserSuccess{} ->
        json(conn, 204, [redirect: redirect])
      %{code: code, name: name, description: description} ->
        render(conn, code, "error", [error: name <> ": " <> description, redirect: redirect])
    end
  end
end
