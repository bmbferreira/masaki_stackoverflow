SolomonLib.Test.Config.init()
SolomonLib.Test.GearConfigHelper.set_config(
  %{
    "app_id"   => "a_12345678",
    "group_id" => "g_12345678",
    "root_key" => "rkey_123456789012345",
  }
)

defmodule Req do
  use SolomonLib.Test.HttpClient
end

defmodule Socket do
  use SolomonLib.Test.WebsocketClient
end
