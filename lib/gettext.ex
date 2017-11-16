use Croma

defmodule MasakiStackoverflow.Gettext do
  use Gettext, otp_app: :masaki_stackoverflow

  defun put_locale(locale :: v[String.t]) :: nil do
    Gettext.put_locale(__MODULE__, locale)
  end
end
