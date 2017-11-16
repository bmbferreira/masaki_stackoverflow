defmodule MasakiStackoverflow.Controller.Hello do
  use SolomonLib.Controller

  def hello(conn) do
    MasakiStackoverflow.Gettext.put_locale(conn.request.query_params["locale"] || "en")
    render(conn, 200, "hello", [gear_name: :masaki_stackoverflow])
  end
end
