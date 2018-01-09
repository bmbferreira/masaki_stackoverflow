defmodule MasakiStackoverflow.Controller.V1.QuestionTest do
  use SolomonLib.Test.ControllerTestCase

  @create_input %{"title" => "title987", "author" => "author765", "body" => "body432"}
  @update_input  [
    %{"operator" => "create", "key" => "comments",                     "value" => "created-comment-123"},
    %{"operator" => "create", "key" => "answers",                      "value" => "created-answer-234"},
    %{"operator" => "create", "key" => "answers.0.comments",           "value" => "created-comment-345"},
    %{"operator" => "update", "key" => "title",                        "value" => "updated-title-456"},
    %{"operator" => "update", "key" => "body",                         "value" => "updated-body-567"},
    %{"operator" => "update", "key" => "comments.0.body",              "value" => "updated-comment-678"},
    %{"operator" => "update", "key" => "answers.0.body",               "value" => "updated-answer-789"},
    %{"operator" => "update", "key" => "answers.0.comments.0.body",    "value" => "updated-comment-890"},
    %{"operator" => "delete", "key" => "comments.0.visible",           "value" => :false},
    %{"operator" => "delete", "key" => "answers.0.visible",            "value" => :false},
    %{"operator" => "delete", "key" => "answers.0.comments.0.visible", "value" => :false}
  ]

  @success_res_body %Dodai.UpdateDedicatedDataEntitySuccess{
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

  test "update should modify contents and return 200" do
    question = @success_res_body.body["data"]
    question_id = @success_res_body.body["_id"]

    created_comment         = %{"_id" => "123", "visible" => :true, "author" => "author104", "body" => "created-comment-123"}
    created_answer          = %{"_id" => "234", "visible" => :true, "author" => "author14",  "body" => "created-comment-234", "comments" => []}
    created_answer_comment  = %{"_id" => "345", "visible" => :true, "author" => "author114", "body" => "created-comment-345"}
    created_answer_comments = Enum.at(question["answers"], 0)["comments"] |> List.insert_at(-1, created_answer_comment)
    commented_answer        = Enum.at(question["answers"], 0) |> Map.put("comments", created_answer_comments)

    updated_comment         = Enum.at(question["comments"],0) |> Map.put("body", "updated-comment-678")
    updated_answer          = Enum.at(question["answers"], 0) |> Map.put("body", "updated-answer-789")
    updated_answer_comment  = Enum.at(question["answers"], 0)["comments"] |> Enum.at(0) |> Map.put("body", "updated-comment-890")
    updated_answer_comments = Enum.at(question["answers"], 0)["comments"] |> List.replace_at(0, updated_answer_comment)
    recommented_answer      = Enum.at(question["answers"], 0) |> Map.put("comments", updated_answer_comments)

    deleted_comment         = Enum.at(question["comments"],0) |> Map.put("visible", :false)
    deleted_answer          = Enum.at(question["answers"], 0) |> Map.put("visible", :false)
    deleted_answer_comment  = Enum.at(question["answers"], 0)["comments"] |> Enum.at(0) |> Map.put("visible", :false)
    deleted_answer_comments = Enum.at(question["answers"], 0)["comments"] |> List.replace_at(0, deleted_answer_comment)
    uncommented_answer      = Enum.at(question["answers"], 0) |> Map.put("comments", deleted_answer_comments)

    update_result = [
      question |> Map.put("comments", question["comments"] |> List.insert_at(-1, created_comment)),
      question |> Map.put("answers",  question["answers"]  |> List.insert_at(-1, created_answer)),
      question |> Map.put("answers",  question["answers"]  |> List.replace_at(0, commented_answer)),
      question |> Map.put("title",    "updated-title-456"),
      question |> Map.put("body",     "updated-body-567"),
      question |> Map.put("comments", question["comments"] |> List.replace_at(0, updated_comment)),
      question |> Map.put("answers",  question["answers"]  |> List.replace_at(0, updated_answer)),
      question |> Map.put("answers",  question["answers"]  |> List.replace_at(0, recommented_answer)),
      question |> Map.put("comments", question["comments"] |> List.replace_at(0, deleted_comment)),
      question |> Map.put("answers",  question["comments"] |> List.replace_at(0, deleted_answer)),
      question |> Map.put("answers",  question["comments"] |> List.replace_at(0, uncommented_answer))
    ]
    ids =     ["123",       "234",      "345",       "undefined", "undefined", "undefined", "undefined", "undefined", "undefined", "undefined", "undefined"]
    authors = ["author104", "author14", "author114", "undefined", "undefined", "undefined", "undefined", "undefined", "undefined", "undefined", "undefined"]
    List.zip([@update_input, update_result, ids, authors]) |> Enum.each(fn {input, result, id, author} ->
      :meck.expect(MasakiStackoverflow.Controller.V1.Question, :set_id, fn -> id end)
      :meck.expect(MasakiStackoverflow.Controller.V1.Question, :get_author, fn -> author end)
      :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
        assert %Dodai.UpdateDedicatedDataEntityRequest{body: %Dodai.UpdateDedicatedDataEntityRequestBody{}} = request
        %Dodai.UpdateDedicatedDataEntitySuccess{
          status_code: 200,
          body: %{
            "_id"       => question_id,
            "owner"     => "_root",
            "sections"  => [],
            "createdAt" => "2017-12-27T03:00:02+00:00",
            "updatedAt" => "2017-12-27T05:55:46+00:00",
            "version"   => 2,
            "data"      => result
          }
        }
      end)
      assert Req.put_json("/v1/question/#{question_id}", input).status == 200
    end)
  end

  test "delete should return 204" do
    :meck.expect(Sazabi.G2gClient, :send, fn _conn, _app_id, request ->
      assert %Dodai.DeleteDedicatedDataEntityRequest{} = request
      Dodai.DeleteDedicatedDataEntitySuccess.new(204, %{}, %{})
    end)
    assert Req.delete("/v1/question/#{@success_res_body.body["_id"]}", %{}, []).status == 204
  end
end
