defmodule MasakiStackoverflow.Controller.V1.CommentTest do
  use SolomonLib.Test.ControllerTestCase

  @question_id "question-id-1"
  @answer_id   "answer-id-2"
  @comment_id  "comment-id-3"
  @create_question_comment_input %{"value" => "comment-body-1", "parent_id" => @question_id, "parent_type" => "question"}
  @create_answer_comment_input   %{"value" => "comment-body-2", "parent_id" => @answer_id,   "parent_type" => "answer"}
  @create_comment_invalid_input %{"value" => ""}
  @update_comment_input         %{"value" => "comment-body-3"}
  @update_comment_invalid_input %{"value" => ""}
  @create_question_comment_success %Dodai.CreateDedicatedDataEntitySuccess{
    status_code: 201,
    body: %{
      "_id"       => @comment_id,
      "owner"     => "comment-author-1",
      "sections"  => [],
      "createdAt" => "2018-01-01T00:00:00+00:00",
      "updatedAt" => "2018-01-01T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "body"        => @create_question_comment_input["value"],
        "parent_type" => "question",
        "parent_id"   => @question_id
      }
    }
  }
  @create_answer_comment_success %Dodai.CreateDedicatedDataEntitySuccess{
    status_code: 201,
    body: %{
      "_id"       => @comment_id,
      "owner"     => "comment-author-2",
      "sections"  => [],
      "createdAt" => "2018-02-01T00:00:00+00:00",
      "updatedAt" => "2018-02-01T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "body"        => @create_answer_comment_input["value"],
        "parent_type" => "answer",
        "parent_id"   => @answer_id
      }
    }
  }
  @question_with_comment_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @question_id,
      "owner"     => "question-author-1",
      "sections"  => [],
      "createdAt" => "2017-01-01T00:00:00+00:00",
      "updatedAt" => "2018-01-01T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "body"     => "question-body",
        "answers" => [],
        "comments" => [@comment_id]
      }
    }
  }
  @answer_with_comment_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @answer_id,
      "owner"     => "answer-author-2",
      "sections"  => [],
      "createdAt" => "2017-02-01T00:00:00+00:00",
      "updatedAt" => "2018-02-01T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "body"     => "answer-body",
        "parent_id" => "question-id",
        "comments" => [@comment_id]
      }
    }
  }
  @update_question_comment_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @comment_id,
      "owner"     => "comment-author-3",
      "sections"  => [],
      "createdAt" => "2018-03-01T00:00:00+00:00",
      "updatedAt" => "2018-03-02T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "body"        => @update_comment_input["value"],
        "parent_type" => "question",
        "parent_id"   => @question_id
      }
    }
  }
  @update_answer_comment_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @comment_id,
      "owner"     => "comment-author-4",
      "sections"  => [],
      "createdAt" => "2018-04-01T00:00:00+00:00",
      "updatedAt" => "2018-04-02T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "body"        => @update_comment_input["value"],
        "parent_type" => "answer",
        "parent_id"   => @answer_id
      }
    }
  }
  @question_without_comment_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 204,
    body: %{
      "_id"       => @question_id,
      "owner"     => "question-author-5",
      "sections"  => [],
      "createdAt" => "2018-05-01T00:00:00+00:00",
      "updatedAt" => "2018-05-02T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "title"     => "question-title-5",
        "body"      => "question-body-5",
        "answers"   => [],
        "comments"  => []
      }
    }
  }
  @answer_without_comment_success %Dodai.UpdateDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => @answer_id,
      "owner"     => "answer-author-6",
      "sections"  => [],
      "createdAt" => "2018-06-01T00:00:00+00:00",
      "updatedAt" => "2018-06-02T00:00:00+00:00",
      "version"   => 0,
      "data"      => %{
        "body"      => "answer-body-6",
        "parent_id" => "question-id-6",
        "comments"  => []
      }
    }
  }

  test "create should return 403, if invalid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.post_json("/v1/question/#{@question_id}/comment", @create_comment_invalid_input).status == 403
    assert Req.post_json("/v1/question/#{@question_id}/answer/#{@answer_id}/comment", @create_comment_invalid_input).status == 403
  end

  test "create should return 201, if valid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      case request do
        %Dodai.CreateDedicatedDataEntityRequest{} -> @create_question_comment_success
        %Dodai.UpdateDedicatedDataEntityRequest{} -> @question_with_comment_success
      end
    end)
    assert Req.post_json("/v1/question/#{@question_id}/comment", @create_question_comment_input).status == 201
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      case request do
        %Dodai.CreateDedicatedDataEntityRequest{} -> @create_answer_comment_success
        %Dodai.UpdateDedicatedDataEntityRequest{} -> @answer_with_comment_success
      end
    end)
    assert Req.post_json("/v1/question/#{@question_id}/answer/#{@answer_id}/comment", @create_answer_comment_input).status == 201
  end

  test "update should modify contents and return 200" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.UpdateDedicatedDataEntityRequest{} = request
      @update_question_comment_success
    end)
    assert Req.put_json("/v1/question/#{@question_id}/comment/#{@comment_id}", @update_comment_input).status == 200
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.UpdateDedicatedDataEntityRequest{} = request
      @update_answer_comment_success
    end)
    assert Req.put_json("/v1/question/#{@question_id}/answer/#{@answer_id}/comment/#{@comment_id}", @update_comment_input).status == 200
  end

  test "update should return 403, if input is invalid" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    assert Req.put_json("/v1/question/#{@question_id}/comment/#{@comment_id}", @update_comment_invalid_input).status == 403
    assert Req.put_json("/v1/question/#{@question_id}/answer/#{@answer_id}/comment/#{@comment_id}", @update_comment_invalid_input).status == 403
  end

  test "delete should return 204" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      case request do
        %Dodai.DeleteDedicatedDataEntityRequest{} -> %Dodai.DeleteDedicatedDataEntitySuccess{}
        %Dodai.UpdateDedicatedDataEntityRequest{} -> @question_without_comment_success
      end
    end)
    assert Req.delete("/v1/question/#{@question_id}/comment/#{@comment_id}").status == 204
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      case request do
        %Dodai.DeleteDedicatedDataEntityRequest{} -> %Dodai.DeleteDedicatedDataEntitySuccess{}
        %Dodai.UpdateDedicatedDataEntityRequest{} -> @answer_without_comment_success
      end
    end)
    assert Req.delete("/v1/question/#{@question_id}/answer/#{@answer_id}/comment/#{@comment_id}").status == 204
  end
end
