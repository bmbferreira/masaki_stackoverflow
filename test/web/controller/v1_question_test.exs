defmodule MasakiStackoverflow.Controller.V1.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @create_input         %{"title" => "question-title-1", "body" => "question-body-1"}
  @create_invalid_input [%{"title" => "", "body" => "question-body-1"}, %{"title" => "question-title-1", "body" => ""}]
  @update_input         %{"value" => "question-body-2"}
  @update_invalid_input %{"value" => ""}
  @question_id "question-id-1"
  @create_success %Dodai.CreateDedicatedDataEntitySuccess{
    status_code: 201,
    body: %{
      "_id"       => @question_id,
      "owner"     => "question-author-1",
      "sections"  => [],
      "createdAt" => "2018-01-01T00:00:00+00:00",
      "updatedAt" => "2018-01-01T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "title"     => @create_input["title"],
        "body"      => @create_input["body"],
        "answers"   => [],
        "comments"  => []
      }
    }
  }
  @update_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @question_id,
      "owner"     => "question-author-2",
      "sections"  => [],
      "createdAt" => "2018-02-01T00:00:00+00:00",
      "updatedAt" => "2018-02-02T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "title"     => "question-title-2",
        "body"      => @update_input["value"],
        "answers"   => [],
        "comments"  => []
      }
    }
  }

  test "create should return 403, if invalid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    @create_invalid_input |> Enum.each(fn input ->
      assert Req.post_json("/v1/question/", input).status == 403
    end)
  end

  test "create should return 201, if valid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.CreateDedicatedDataEntityRequest{} = request
      @create_success
    end)
    assert Req.post_json("/v1/question/", @create_input).status == 201
  end

  test "update should modify body and return 200" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.UpdateDedicatedDataEntityRequest{} = request
      @update_success
    end)
    assert Req.put_json("/v1/question/#{@question_id}", @update_input).status == 200
  end

  test "update should return 403, if input is invalid" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.put_json("/v1/question/#{@question_id}", @update_invalid_input).status == 403
  end

  test "delete should return 204" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.DeleteDedicatedDataEntityRequest{} = request
      Dodai.DeleteDedicatedDataEntitySuccess.new(204, %{}, %{})
    end)
    assert Req.delete("/v1/question/#{@question_id}", %{}, []).status == 204
  end
end
