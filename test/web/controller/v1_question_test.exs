defmodule MasakiStackoverflow.Controller.V1.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @create_input          %{"title" => "question-title-1", "body" => "question-body-1"}
  @create_invalid_input [%{"title" => "",                 "body" => "question-body-1"},
                         %{"title" => "question-title-1", "body" => ""}]
  @update_input          %{"value" => "question-body-2"}
  @update_invalid_input  %{"value" => ""}
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
  @show_success_questions [
    %Dodai.RetrieveDedicatedDataEntitySuccess{
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
          "answers"   => ["answer-id-4"],
          "comments"  => ["comment-id-5"]
        }
      }
    }
  ]
  @show_success_answers [
    %Dodai.RetrieveDedicatedDataEntitySuccess{
      status_code: 200,
      body: %{
        "_id"       => "answer-id-4",
        "owner"     => "answer-author-4",
        "sections"  => [],
        "createdAt" => "2018-04-01T00:00:00+00:00",
        "updatedAt" => "2018-04-02T00:00:00+00:00",
        "version"   => 0,
        "data"      => %{
          "body"      => "answer-body-4",
          "parent_id" => @question_id,
          "comments"  => ["comment-id-6"]
        }
      }
    }
  ]

  test "create should return 403, if invalid values were sent" do
    :meck.expect(Sazabi.G2gClient, :send, fn _, _, _ -> assert false end)
    Enum.each(@create_invalid_input, fn input ->
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
      case request do
        %Dodai.DeleteDedicatedDataEntityRequest{}   -> %Dodai.DeleteDedicatedDataEntitySuccess{}
        %Dodai.RetrieveDedicatedDataEntityRequest{} ->
          case request.data_collection_name do
            "question" -> @show_success_questions
            "answer"   -> @show_success_answers
          end
          |> Enum.filter(fn %{body: %{"_id" => document_id}} -> document_id == request.id end)
          |> Enum.at(0)
      end
    end)
    assert Req.delete("/v1/question/#{@question_id}", %{}, []).status == 204
  end
end
