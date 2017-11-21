defmodule MasakiStackoverflow.Controller.Hello2 do
  use SolomonLib.Controller

  def hello2(conn) do
    MasakiStackoverflow.Gettext.put_locale(conn.request.query_params["locale"] || "en")
    render(conn, 200, "hello2", [gear_name: :masaki_stackoverflow])
  end
end
