defmodule RmudIdentity.RmudAccounts do
  use Ecto.Schema
  import Ecto.Changeset
  alias RmudIdentity.RmudAccounts, as: Ele
  alias RmudIdentity.Repo

  schema "rmud_account" do
    field :private_key, :string
    field :aptos_account, :string
    field :balance, :decimal, default: Decimal.new("0")
    field :rmud_address, :string
    field :paid_tx, :string
    field :type, :string, default: "normal"

    timestamps()
  end

  def get_all() do
    Repo.all(Ele)
  end

  def get_by_id(id) do
    Repo.get_by(Ele, id: id)
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
    |> cast(attrs, [:private_key, :aptos_account, :rmud_address, :balance, :type, :paid_tx])
  end
end

