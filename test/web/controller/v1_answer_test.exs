defmodule MasakiStackoverflow.Controller.V1.AnswerTest do
  use SolomonLib.Test.ControllerTestCase

  @question_id "question-id-1"
  @answer_id   "answer-id-2"
  @create_answer_input         %{"value" => "answer-body-1"}
  @create_answer_invalid_input %{"value" => ""}
  @update_answer_input         %{"value" => "answer-body-2"}
  @update_answer_invalid_input %{"value" => ""}
  @create_answer_success %Dodai.CreateDedicatedDataEntitySuccess{
    status_code: 201,
    body: %{
      "_id"       => @answer_id,
      "owner"     => "answer-author-1",
      "sections"  => [],
      "createdAt" => "2018-01-01T00:00:00+00:00",
      "updatedAt" => "2018-01-01T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "parent_id" => @question_id,
        "body"      => @create_answer_input["value"],
        "comments"  => []
      }
    }
  }
  @question_with_answer_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @question_id,
      "owner"     => "question-author-1",
      "sections"  => [],
      "createdAt" => "2017-01-01T00:00:00+00:00",
      "updatedAt" => "2018-01-01T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "title"    => "title",
        "body"     => "body",
        "answers"  => [@answer_id],
        "comments" => []
      }
    }
  }
  @update_answer_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @answer_id,
      "owner"     => "answer-author-2",
      "sections"  => [],
      "createdAt" => "2018-02-01T00:00:00+00:00",
      "updatedAt" => "2018-02-02T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "parent_id" => @question_id,
        "body"      => @update_answer_input["value"],
        "comments"  => []
      }
    }
  }
  @question_without_answer_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @question_id,
      "owner"     => "question-author-3",
      "sections"  => [],
      "createdAt" => "2018-03-01T00:00:00+00:00",
      "updatedAt" => "2018-03-02T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "title"     => "question-title-3",
        "body"      => "question-body-3",
        "answers"   => [],
        "comments"  => []
      }
    }
  }

  test "create should return 403, if invalid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.post_json("/v1/question/#{@question_id}/answer", @create_answer_invalid_input).status == 403
  end

  test "create should return 201, if valid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      case request do
        %Dodai.CreateDedicatedDataEntityRequest{} -> @create_answer_success
        %Dodai.UpdateDedicatedDataEntityRequest{} -> @question_with_answer_success
      end
    end)
    assert Req.post_json("/v1/question/#{@question_id}/answer", @create_answer_input).status == 201
  end

  test "update should modify contents and return 200" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.UpdateDedicatedDataEntityRequest{} = request
      @update_answer_success
    end)
    assert Req.put_json("/v1/question/#{@question_id}/answer/#{@answer_id}", @update_answer_input).status == 200
  end

  test "update should return 403, if input is invalid" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.put_json("/v1/question/#{@question_id}/answer/#{@answer_id}", @update_answer_invalid_input).status == 403
  end

  test "delete should return 204" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      case request do
        %Dodai.DeleteDedicatedDataEntityRequest{} -> %Dodai.DeleteDedicatedDataEntitySuccess{}
        %Dodai.UpdateDedicatedDataEntityRequest{} -> @question_without_answer_success
      end
    end)
    assert Req.delete("/v1/question/#{@question_id}/answer/#{@answer_id}", %{}, []).status == 204
  end
end
