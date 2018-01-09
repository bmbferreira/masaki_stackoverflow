defmodule MasakiStackoverflow.Controller.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @index_success_res_body %Dodai.RetrieveDedicatedDataEntityListSuccess{
    status_code: 200,
    body: [
      %{
        "_id"       => "5a2f3afa38000038008d0d9e",
        "owner"     => "_root",
        "createdAt" => "2017-12-01T01:00:00+00:00",
        "updatedAt" => "2017-12-01T01:00:00+00:00",
        "sections"  => [],
        "version"   => 0,
        "data"      => %{"title" => "title123", "author" => "user456", "body" => "body789", "answers" => [], "comments" => []}
      },
      %{
        "_id"       => "5a2f64f33900003900070025",
        "owner"     => "_root",
        "createdAt" => "2017-12-01T01:00:01+00:00",
        "updatedAt" => "2017-12-01T01:00:01+00:00",
        "sections"  => [],
        "version"   => 0,
        "data"      => %{"title" => "TITLE124", "author" => "USER248", "body" => "BODY4816", "answers" => [], "comments" => []}
      }
    ]
  }
  @show_success_res_body %Dodai.RetrieveDedicatedDataEntitySuccess{
    status_code: 200,
    body: %{
      "_id"       => "5a430cb23900003900091afe",
      "owner"     => "_root",
      "sections"  => [],
      "createdAt" => "2017-12-27T03:00:02+00:00",
      "updatedAt" => "2017-12-27T05:55:46+00:00",
      "version"   => 2,
      "data"      => %{
        "title"     => "title1",
        "body"      => "body1",
        "author"    => "author1",
        "answers"   => [
          %{
            "visible"  => :true,
            "_id"      => "author11-2018-01-26T08:47:07.916233Z",
            "author"   => "author11",
            "body"     => "body11",
            "comments" => [
              %{
                "visible" => :true,
                "_id"     => "author111-2018-02-26T08:47:07.916233Z",
                "author"  => "author111",
                "body"    => "body111"
              },
              %{
                "visible" => :true,
                "_id"     => "author112-2018-03-26T08:47:07.916233Z",
                "author"  => "author112",
                "body"    => "body112"
              },
              %{
                "visible" => :false,
                "_id"     => "author113-2018-04-26T08:47:07.916233Z",
                "author"  => "author113",
                "body"    => "body113"
              }
            ]
          },
          %{
            "visible"  => :true,
            "_id"      => "author12-2018-05-26T08:47:07.916233Z",
            "author"   => "author12",
            "body"     => "body12",
            "comments" => [
              %{
                "visible" => :true,
                "_id"     => "author121-2018-06-26T08:47:07.916233Z",
                "author"  => "author121",
                "body"    => "body121"
              },
              %{
                "visible" => :true,
                "_id"     => "author122-2018-07-26T08:47:07.916233Z",
                "author"  => "author122",
                "body"    => "body122"
              },
              %{
                "visible" => :false,
                "_id"     => "author123-2018-08-26T08:47:07.916233Z",
                "author"  => "author123",
                "body"    => "body123"
              }
            ]
          },
          %{
            "visible"  => :false,
            "_id"      => "author13-2018-09-26T08:47:07.916233Z",
            "author"   => "author13",
            "body"     => "body13",
            "comments" => [
              %{
                "visible" => :true,
                "_id"     => "author131-2018-10-26T08:47:07.916233Z",
                "author"  => "author131",
                "body"    => "body131"
              },
              %{
                "visible" => :true,
                "_id"     => "author132-2018-11-26T08:47:07.916233Z",
                "author"  => "author132",
                "body"    => "body132"
              },
              %{
                "visible" => :false,
                "_id"     => "author133-2018-12-26T08:47:07.916233Z",
                "author"  => "author133",
                "body"    => "body133"
              }
            ]
          }
        ],
        "comments" => [
          %{
            "visible" => :true,
            "_id"     => "author101-2019-01-26T08:47:07.916233Z",
            "author"  => "author101",
            "body"    => "body101"
          },
          %{
            "visible" => :true,
            "_id"     => "author102-2019-02-26T08:47:07.916233Z",
            "author"  => "author102",
            "body"    => "body102"
          },
          %{
            "visible" => :false,
            "_id"     => "author103-2019-03-26T08:47:07.916233Z",
            "author"  => "author103",
            "body"    => "body103"
          }
        ]
      }
    }
  }

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
      assert String.contains?(body, data["author"])
      assert String.contains?(body, data["body"])
    end)
  end

  test "show should render every item recursively as HTML" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, %{} ->
      @show_success_res_body
    end)
    question = @show_success_res_body.body["data"]
    question_id = @show_success_res_body.body["_id"]
    response = Req.get("/question/#{question_id}", %{}, [params: %{"locale" => "ja"}])
    assert response.status == 200
    assert response.headers["content-type"] == "text/html"
    body = response.body
    assert String.starts_with?(body, "<!DOCTYPE html>")
    assert String.contains?(body, question["title"])
    assert String.contains?(body, question["author"])
    assert String.contains?(body, question["body"])
    Enum.each(question["comments"], fn comment ->
      assert !comment["visible"] || String.contains?(body, comment["author"])
      assert !comment["visible"] || String.contains?(body, comment["body"])
    end)
    Enum.each(question["answers"], fn answer ->
      assert !answer["visible"] || String.contains?(body, answer["author"])
      assert !answer["visible"] || String.contains?(body, answer["body"])
      Enum.each(answer["comments"], fn comment ->
        assert !answer["visible"] || !comment["visible"] || String.contains?(body, comment["author"])
        assert !answer["visible"] || !comment["visible"] || String.contains?(body, comment["body"])
      end)
    end)
  end
end
