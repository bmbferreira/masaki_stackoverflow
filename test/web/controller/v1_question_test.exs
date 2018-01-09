defmodule MasakiStackoverflow.Controller.V1.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @create_input %{"title" => "title987", "author" => "author765", "body" => "body432"}

  test "create should return 403, if invalid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.post_json("/v1/question", %{"title" => "",      "author" => "author", "body" => "body"}).status == 403
    assert Req.post_json("/v1/question", %{"title" => "title", "author" => "",       "body" => "body"}).status == 403
    assert Req.post_json("/v1/question", %{"title" => "title", "author" => "author", "body" => ""    }).status == 403
  end

  test "create should return 201, if valid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.CreateDedicatedDataEntityRequest{body: %Dodai.CreateDedicatedDataEntityRequestBody{}} = request
      Dodai.CreateDedicatedDataEntitySuccess.new(201, %{}, %{id: "new-id"})
    end)
    assert Req.post_json("/v1/question/", @create_input).status == 201
  end
end
