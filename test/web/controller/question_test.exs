defmodule MasakiStackoverflow.Controller.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @success_res_body %Dodai.RetrieveDedicatedDataEntityListSuccess{
    status_code: 200,
    body: [
      %{
        "_id"       => "5a2f3afa38000038008d0d9e",
        "owner"     => "_root",
        "createdAt" => "2017-12-01T01:00:00+00:00",
        "updatedAt" => "2017-12-01T01:00:00+00:00",
        "sections"  => [],
        "version"   => 0,
        "data"      => %{"title" => "title123", "author" => "user456", "body" => "body789"},
      },
      %{
        "_id"       => "5a2f64f33900003900070025",
        "owner"     => "_root",
        "createdAt" => "2017-12-01T01:00:01+00:00",
        "updatedAt" => "2017-12-01T01:00:01+00:00",
        "sections"  => [],
        "version"   => 0,
        "data"      => %{"title" => "TITLE124", "author" => "USER248", "body" => "BODY4816"},
      }
    ]
  }
  @form_input_map %{title: "title987", author: "author765", body: "body432"}

  test "index should render every item as HTML" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, %{} ->
      @success_res_body
    end)
    response = Req.get("/question", %{}, [params: %{"locale" => "ja"}])
    assert response.status == 200
    assert response.headers["content-type"] == "text/html"
    body = response.body
    assert String.starts_with?(body, "<!DOCTYPE html>")
    Enum.each(@success_res_body.body, fn %{"data" => data} ->
      Map.values(data)
      |> Enum.each(fn value ->
        assert String.contains?(body, value)
      end)
    end)
  end

  test "create should fail if invalid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.post_form("/question", [title: "",      author: "author", body: "body"]).status == 302
    assert Req.post_form("/question", [title: "title", author: "",       body: "body"]).status == 302
    assert Req.post_form("/question", [title: "title", author: "author", body: ""    ]).status == 302
  end

  test "create should succeed if valid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.CreateDedicatedDataEntityRequest{body: %Dodai.CreateDedicatedDataEntityRequestBody{data: @form_input_map}} = request
      Dodai.CreateDedicatedDataEntitySuccess.new(201, [], "")
    end)
    assert Req.post_form("/question", Map.to_list(@form_input_map)).status == 302
  end
end
