defmodule MasakiStackoverflow.Controller.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @question_id     "question-id-3"
  @index_success_res_body %Dodai.RetrieveDedicatedDataEntityListSuccess{
    status_code: 200,
    body: [
      %{
        "_id"       => "question-id-1",
        "owner"     => "question-author-1",
        "createdAt" => "2018-01-01T01:00:00+00:00",
        "updatedAt" => "2018-01-02T01:00:00+00:00",
        "sections"  => [],
        "version"   => 0,
        "data"      => %{
          "title"     => "question-title-1",
          "body"      => "question-body-1",
          "answers"   => ["answer-id-11",   "answer-id-12"],
          "comments"  => ["comment-id-101", "comment-id-102"]
        }
      },
      %{
        "_id"       => "question-id-2",
        "owner"     => "question-author-2",
        "createdAt" => "2018-02-01T01:00:00+00:00",
        "updatedAt" => "2018-02-02T01:00:00+00:00",
        "sections"  => [],
        "version"   => 0,
        "data"      => %{
          "title"     => "question-title-2",
          "body"      => "question-body-2",
          "answers"   => ["answer-id-21",   "answer-id-22"],
          "comments"  => ["comment-id-201", "comment-id-202"]
        }
      }
    ]
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
  @show_success_comments [
    %Dodai.RetrieveDedicatedDataEntitySuccess{
      status_code: 200,
      body: %{
        "_id"       => "comment-id-5",
        "owner"     => "comment-author-5",
        "sections"  => [],
        "createdAt" => "2018-05-01T00:00:00+00:00",
        "updatedAt" => "2018-05-02T00:00:00+00:00",
        "version"   => 0,
        "data"      => %{
          "body"        => "comment-body-5",
          "parent_type" => "question",
          "parent_id"   => @question_id
        }
      }
    },
    %Dodai.RetrieveDedicatedDataEntitySuccess{
      status_code: 200,
      body: %{
        "_id"       => "comment-id-6",
        "owner"     => "comment-author-6",
        "sections"  => [],
        "createdAt" => "2018-06-01T00:00:00+00:00",
        "updatedAt" => "2018-06-02T00:00:00+00:00",
        "version"   => 0,
        "data"      => %{
          "body"        => "comment-body-6",
          "parent_type" => "answer",
          "parent_id"   => "answer-id-4"
        }
      }
    }
  ]

  test "index should render every item as HTML" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, %{} ->
      @index_success_res_body
    end)
    response = Req.get("/question", %{}, [params: %{"locale" => "ja"}])
    assert response.status == 200
    assert response.headers["content-type"] == "text/html"
    body = response.body
    assert String.starts_with?(body, "<!DOCTYPE html>")
    Enum.each(@index_success_res_body.body, fn %{"data" => data} ->
      assert String.contains?(body, data["title"])
      assert String.contains?(body, data["body"])
    end)
  end

  test "show should render every item as HTML" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      case request.data_collection_name do
        "question" -> @show_success_questions
        "answer"   -> @show_success_answers
        "comment"  -> @show_success_comments
      end
      |> Enum.filter(fn %{body: %{"_id" => document_id}} -> document_id == request.id end)
      |> Enum.at(0)
    end)
    response = Req.get("/question/#{@question_id}", %{}, [params: %{"locale" => "ja"}])
    assert response.status == 200
    assert response.headers["content-type"] == "text/html"
    body = response.body
    assert String.starts_with?(body, "<!DOCTYPE html>")
    Enum.each(@show_success_questions, fn question ->
      assert String.contains?(body, question.body["owner"])
      assert String.contains?(body, question.body["data"]["title"])
      assert String.contains?(body, question.body["data"]["body"])
      Enum.each(question.body["data"]["answers"], fn answer_id ->
        answer = Enum.filter(@show_success_answers, fn answer -> answer.body["_id"] == answer_id end)
        |> Enum.at(0)
        assert String.contains?(body, answer.body["owner"])
        assert String.contains?(body, answer.body["data"]["body"])
        Enum.each(answer.body["data"]["comments"], fn comment_id ->
          comment = Enum.filter(@show_success_comments, fn comment -> comment.body["_id"] == comment_id end)
          |> Enum.at(0)
          assert String.contains?(body, comment.body["owner"])
          assert String.contains?(body, comment.body["data"]["body"])
        end)
      end)
      Enum.each(question.body["data"]["comments"], fn comment_id ->
        comment = Enum.filter(@show_success_comments, fn comment -> comment.body["_id"] == comment_id end)
        |> Enum.at(0)
        assert String.contains?(body, comment.body["owner"])
        assert String.contains?(body, comment.body["data"]["body"])
      end)
    end)
  end
end
