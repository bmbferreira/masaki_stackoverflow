defmodule MasakiStackoverflow.SignupTest do
  use ExUnit.Case

  @signup_path "/signup"
  @email       "name@access-company.com"
  @password    "password"

  test "should return 201 if successful" do
    create_user_res = Dodai.CreateUserSuccess.new(201, [], %{email: @email})
    :meck.expect(Sazabi.G2gClient, :send, fn
      _context, _app_id, %Dodai.CreateUserRequest{body: body} ->
        assert body.email    == @email
        assert body.password == @password
        create_user_res
    end)
    res = Req.post_form(@signup_path, [email: @email, password: @password])
    assert res.status == 201
  end

  test "should render HTML with error if input is invalid" do
    [
      {Dodai.ValidationError.new("Invalid parameter."), 400, "Invalid parameter."},
      {Dodai.AuthenticationIDAlreadyTaken.new(),        409, "The given authentication ID is already taken."},
    ] |> Enum.each(fn {response, status, error_message} ->
      :meck.expect(Sazabi.G2gClient, :send, fn(_context, _app_id, _req) -> response end)
      res = Req.post_form(@signup_path, [email: @email, password: @password])
      assert res.status == status
      assert String.contains?(res.body, error_message)
    end)
  end
end
