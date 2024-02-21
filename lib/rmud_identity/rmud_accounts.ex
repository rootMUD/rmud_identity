defmodule RmudIdentity.RmudAccounts do
  use Ecto.Schema
  import Ecto.Changeset
  alias RmudIdentity.RmudAccounts, as: Ele
  alias RmudIdentity.Repo

  schema "rmud_account" do
    # field :encrypted_private_key, :string
    field :private_key, :string
    field :aptos_account, :string
    field :balance, :decimal, default: Decimal.new("0")
    field :rmud_address, :string
    field :paid_tx, :string
    field :domain, :string
    field :type, :string, default: "normal"
    field :paid_tx_domain, :string
    # remeber to add a new payment tx, and one acct only could have one DOMAIN now.
    timestamps()
  end

  def get_all() do
    Repo.all(Ele)
  end

  def get_by_id(id) do
    Repo.get_by(Ele, id: id)
  end

  def get_by_domain(domain) do
    Repo.get_by(Ele, domain: domain)
  end

  def get_by_rmud_addr(addr) do
    Repo.get_by(Ele, rmud_address: addr)
  end

  def get_by_aptos_addr(addr) do
    Repo.get_by(Ele, aptos_account: addr)
  end

  def get_by_type(type) do
    Repo.get_by(Ele, type: type)
  end

  def create(attrs \\ %{}) do
    %Ele{}
    |> Ele.changeset(attrs)
    |> Repo.insert()
  end

  def update(%Ele{} = ele, attrs) do
    ele
    |> changeset(attrs)
    |> Repo.update()
  end

  def delete_by_id(id) do
    ele = Repo.get!(Ele, id)
    Repo.delete(ele)
  end

  def changeset(%Ele{} = ele) do
    Ele.changeset(ele, %{})
  end

  @doc false
  def changeset(%Ele{} = ele, attrs) do
    ele
    |> cast(attrs, [:private_key, :aptos_account, :rmud_address, :balance, :type, :paid_tx, :domain, :paid_tx_domain])
  end

  # +------------+
  # | Spec Funcs |
  # +------------+

  defp encrypt_private_key(changeset) do
    private_key = get_field(changeset, :private_key)
    case private_key do
      nil -> changeset
      _ ->
        secret_key_base = Application.get_env(:rmud_identity, :secret_key_base) |> Base.decode64!()
        encrypted_private_key = :crypto.block_encrypt(:aes_ecb, secret_key_base, private_key)
        put_change(changeset, :encrypted_private_key, encrypted_private_key)
    end
  end

end

