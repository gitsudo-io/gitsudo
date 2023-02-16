defmodule GitsudoWeb.WebhookControllerTest do
  use GitsudoWeb.ConnCase

  require Logger

  test "installation created event", %{conn: conn} do
    path =
      Path.expand(
        "../../../fixtures/installation-created-webhook-payload.json",
        __ENV__.file
      )

    IO.puts(path)
    params = Jason.decode!(File.read!(path))

    conn =
      build_conn()
      |> Plug.Test.init_test_session(access_token: SecureRandom.hex())
      |> post(~p"/webhook", params)

    assert response(conn, 204)

    Logger.debug(inspect(Gitsudo.Repo.get(Gitsudo.Repositories.Owner, 121_780_924)))

    app_installation = Gitsudo.Repo.get(Gitsudo.GitHub.AppInstallation, 34_222_363)
    Logger.debug(inspect(Map.from_struct(app_installation) |> Map.delete(:__meta__)))
    assert %Gitsudo.GitHub.AppInstallation{id: 34_222_363} = app_installation
  end
end
