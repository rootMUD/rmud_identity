defmodule RmudIdentity.Repo do
  use Ecto.Repo,
    otp_app: :rmud_identity,
    adapter: Ecto.Adapters.Postgres
end
