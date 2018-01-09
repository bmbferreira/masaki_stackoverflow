defmodule MasakiStackoverflow.Controller.V1.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @form_input_map %{title: "title987", author: "author765", body: "body432"}

  test "create should fail if invalid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.post_form("/v1/question", [title: "",      author: "author", body: "body"]).status == 403
    assert Req.post_form("/v1/question", [title: "title", author: "",       body: "body"]).status == 403
    assert Req.post_form("/v1/question", [title: "title", author: "author", body: ""    ]).status == 403
  end

  test "create should succeed if valid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.CreateDedicatedDataEntityRequest{body: %Dodai.CreateDedicatedDataEntityRequestBody{data: @form_input_map}} = request
      Dodai.CreateDedicatedDataEntitySuccess.new(201, [], "")
    end)
    assert Req.post_form("/v1/question", Map.to_list(@form_input_map)).status == 201
  end
end
