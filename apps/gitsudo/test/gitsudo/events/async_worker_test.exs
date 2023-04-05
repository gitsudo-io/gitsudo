defmodule Gitsudo.Events.AsyncWorkerTest do
  use Gitsudo.DataCase

  alias Gitsudo.Events.AsyncWorker
  alias Gitsudo.Repo

  require Logger

  test "handle_app_installation_created" do
    path =
      Path.expand(
        "../../../fixtures/installation-created-webhook-payload.json",
        __ENV__.file
      )

    IO.puts(path)
    params = Jason.decode!(File.read!(path))

    AsyncWorker.handle_app_installation_created(params)

    Logger.debug(inspect(Repo.get(Gitsudo.Accounts.Account, 121_780_924)))

    app_installation = Repo.get(Gitsudo.GitHub.AppInstallation, 34_222_363)
    Logger.debug(inspect(app_installation))
    assert %Gitsudo.GitHub.AppInstallation{id: 34_222_363} = app_installation
  end
end
