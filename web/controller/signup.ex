defmodule MasakiStackoverflow.Controller.Signup do
  use SolomonLib.Controller

  def index(conn) do
    render_page(conn, 200, [])
  end

  def create(%SolomonLib.Conn{request: request, context: context} = conn) do
    %{"email" => email, "password" => password} = request.body
    %{"app_id" => app_id, "group_id" => group_id, "root_key" => root_key} = MasakiStackoverflow.get_all_env()
    req = Dodai.CreateUserRequest.new(group_id, root_key, %Dodai.CreateUserRequestBody{email: email, password: password})
    res = Sazabi.G2gClient.send(context, app_id, req)
    case res do
      %Dodai.CreateUserSuccess{} ->
        render_page(conn, 201, [email: email])
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
