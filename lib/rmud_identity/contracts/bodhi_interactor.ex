defmodule RmudIdentity.Contracts.BodhiInteractor do
    @moduledoc """
        the interact with bodhi on op chain.
        > https://mainnet.optimism.io
        > 10
        > https://explorer.optimism.io
    """
    alias Ethereumex.HttpClient
    alias Components.Transaction
    require Logger

    @endpoint "https://mainnet.optimism.io"
    @chain_id 10
    @contract_addr "0x2AD82A4E39Bac43A54DdfE6f94980AAf0D1409eF"
    @arweave_node "https://arweave.net"
    @func %{
        asset_index: "assetIndex()", 
        assets: "assets(uint256)",
        balance_of: "balanceOf(address, uint256)",
        buy: "buy(uint256, uint256)", 
        get_buy_price_after_fee: "getBuyPriceAfterFee(uint256, uint256)",
        create: "create(string)"
    }
    @gas_limit 1_000_000

    def get_module_doc, do: @moduledoc

    # +--------------+
    # | Asset Reader |
    # +--------------+

    def get_buy_price_after_fee(asset_id, amount) do
        amount_raw = 
            "#{amount}"
            |> Decimal.new()
            |> Decimal.mult(1_000_000_000_000_000_000)
            |> Decimal.to_integer()
        data = TypeTranslator.get_data(@func.get_buy_price_after_fee, [asset_id, amount_raw])
        {:ok, raw} = 
            HttpClient.eth_call(
                %{
                data: data,
                to: @contract_addr
            }, 
            "latest", 
            [url: @endpoint, request_timeout: 1000]
            )
        # decode
        [price_raw] = 
        raw
        |> Binary.drop(2)
        |> Base.decode16!(case: :lower)
        |> ABI.TypeDecoder.decode_raw([{:uint, 256}])
        price_raw + 1_500_000_000_000_000
    end

    def balance_of(addr, asset_id) do
        # addr_bin
        addr_bin = TypeTranslator.addr_to_bin(addr)
        # get data
        data = TypeTranslator.get_data(@func.balance_of, [addr_bin, asset_id])
        # get raw response
        {:ok, raw} = 
            HttpClient.eth_call(
                %{
                data: data,
                to: @contract_addr
            }, 
            "latest", 
            [url: @endpoint, request_timeout: 1000]
            )
        # decode
        [balance] = 
            raw
            |> Binary.drop(2)
            |> Base.decode16!(case: :lower)
            |> ABI.TypeDecoder.decode_raw([{:uint, 256}])
        balance
        |> Decimal.div(1_000_000_000_000_000_000)
        # |> Decimal.to_float()
    end
    
    # +------------------+
    # | RAW Data Fetcher |
    # +------------------+

    def get_assets(begin_asset_id, end_asset_id) do
        Enum.map(begin_asset_id..end_asset_id, fn asset_id ->
            get_asset(asset_id)
        end)
    end

    def get_asset_index() do
        data = TypeTranslator.get_data(@func.asset_index, [])
        {:ok, raw} = 
            HttpClient.eth_call(
                %{
                data: data,
                to: @contract_addr
            }, 
            "latest", 
            [url: @endpoint, request_timeout: 1000]
            )
        [index] = 
            raw
            |> Binary.drop(2)
            |> Base.decode16!(case: :lower)
            |> ABI.TypeDecoder.decode_raw([{:uint, 256}])
        index
    end
    def get_asset(asset_id) do
        # get data
        data = TypeTranslator.get_data(@func.assets, [asset_id])
        # get raw response
        {:ok, raw} = 
            HttpClient.eth_call(
                %{
                data: data,
                to: @contract_addr
            }, 
            "latest", 
            [url: @endpoint, request_timeout: 1000]
            )
        # decode
        [asset_id, ar_resource, addr] = 
            raw
            |> Binary.drop(2)
            |> Base.decode16!(case: :lower)
            |> ABI.TypeDecoder.decode_raw([{:uint, 256}, :string, :address])
        addr = "0x" <> Base.encode16(addr, case: :lower)
        [asset_id, ar_resource, addr]
    end

end