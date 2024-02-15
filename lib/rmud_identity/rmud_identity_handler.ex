defmodule RmudIdentity.RmudIdentityHandler do
  alias RmudIdentity.RmudAccounts
  alias Web3AptosEx.Aptos
  alias Web3AptosEx.ModuleHandler.Aptos.Coin.APT
  alias Web3AptosEx.ModuleHandler.Aptos.MoveDID

  require Logger

    @network :randomnet
  @init_amount 10_000_000
  def init_rmud_identity(paid_tx, rmud_address, nick_name) do
    {:ok, client} = Aptos.connect(@network)
    # Generate a acct on Aptos 
    {:ok, acct} = Web3AptosEx.Aptos.generate_keys()
    # transfer a fee to it by admin acct
    private_key = RmudIdentity.RmudAccounts.get_by_type("admin").private_key
    {:ok, admin_acct} = Web3AptosEx.Aptos.generate_keys(private_key)
    {:ok, admin_acct} = Web3AptosEx.Aptos.load_account(client, admin_acct)
    {:ok, payload} = 
        APT.transfer(
            client, 
            admin_acct, 
            acct.address_hex, 
            @init_amount,
            [expire_in_secs: System.system_time(:second) + 3600] # it should be debug later.
            )
    Logger.info("#{inspect(payload)}")
    # Claim MoveDID Automatically
    Process.sleep(2000)
    {:ok, acct} = Web3AptosEx.Aptos.load_account(client, acct)
    {:ok, payload_2} = MoveDID.init(
        client, 
        acct, 
        0, 
        "#{nick_name}'s acct",
        [expire_in_secs: System.system_time(:second) + 3600] # it should be debug later.
    )
    Logger.info("#{inspect(payload_2)}")
    Process.sleep(2000)
    # bind rmud_address to MoveDID
    {:ok, payload_3} = MoveDID.add_addr(
      client,
      acct,
      0,
      rmud_address,
      "",
      ["mapo"],
      "rmud addr",
      "",
      0,
      [expire_in_secs: System.system_time(:second) + 3600] # it should be debug later.
    )
    Logger.info("#{inspect(payload_3)}")
    Process.sleep(2000)
    # get balance
    %{
      coin: %{value: value}
    } = Web3AptosEx.Aptos.get_balance(client, acct.address_hex)
    
    with true <- nil != Map.get(payload, :hash),
            true <- nil != Map.get(payload_2, :hash),
            true <- nil != Map.get(payload_3, :hash) do
        # insert new acct into database
        RmudAccounts.create(%{
            private_key: acct.priv_key_hex,
            aptos_account: acct.address_hex,
            balance: Decimal.new("#{value}"),
            rmud_address: rmud_address,
            paid_tx: paid_tx
        })
    else
        _ -> {:error, "Failed to init rmud identity"}
    end
  end

  def get_did_data(rmud_address) do
    {:ok, client} = Aptos.connect(@network)
    acct = RmudAccounts.get_by_rmud_addr(rmud_address)
    case acct do
        nil ->
            {:error, "this addr did not register RMUD Identity!"}
        acct ->
            {
                :ok, 
                Web3AptosEx.ModuleHandler.Aptos.MoveDID.get_all(client, acct.aptos_account)
            }
    end
  end
end
