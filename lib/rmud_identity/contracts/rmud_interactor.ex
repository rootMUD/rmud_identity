defmodule RmudIdentity.Contracts.RmudInteractor do
  alias Ethereumex.HttpClient

  @endpoint "https://rpc.maplabs.io"
  @contract_addr "0xed8b05159460c900f12075c3b901ca274fd7486f"
  @receipt_money_addr "0x73c7448760517E3E6e416b2c130E3c6dB2026A1d"
  @func %{
    balance_of: "balanceOf(address)"
  }

  def balance_of(addr) do
    # addr_bin
    addr_bin = TypeTranslator.addr_to_bin(addr)
    # get data
    data = TypeTranslator.get_data(@func.balance_of, [addr_bin])
    # get raw response
    {:ok, raw} =
      HttpClient.eth_call(
        %{
          data: data,
          to: @contract_addr
        },
        "latest",
        url: @endpoint,
        request_timeout: 1000
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

  def parse_tx(tx_id, price) do
    try do
      {:ok, receipt} =
        HttpClient.eth_get_transaction_receipt(
          tx_id,
          url: @endpoint,
          request_timeout: 1000
        )

      receipt = ExStructTranslator.to_atom_struct(receipt)

      with true <- "0x1" == Map.get(receipt, :status),
           true <- @contract_addr == Map.get(receipt, :to) do
        event_decoded = handle_receipt(%{logs: Map.get(receipt, :logs)})
        IO.puts(String.downcase(Map.get(event_decoded.params, "to")))

        with true <- "Transfer(address,address,uint256)" == event_decoded.event,
             true <-
               String.downcase(@receipt_money_addr) ==
                 String.downcase(Map.get(event_decoded.params, "to")),
             true <-
               not Decimal.lt?(Decimal.new("#{Map.get(event_decoded.params, "value")}"), price) do
          {:ok, %{from: Map.get(receipt, :from)}}
        else
          _ -> {:error, "the tx is invalid"}
        end
      else
        _ -> {:error, "the tx is failed tx"}
      end
    rescue
      e -> {:error, e}
    end
  end

  def handle_receipt(%{logs: logs}) do
    Enum.map(logs, fn payload ->
      case payload do
        %{address: addr, data: data, topics: topics, logIndex: log_index} ->
          build_event(addr, data, topics, log_index)

        %{address: addr, data: data, topics: topics} ->
          build_event(addr, data, topics, nil)
      end
    end)
    |> Enum.fetch!(0)
  end

  def build_event(addr, data, topics, log_index) do
    event = %{
      address: addr,
      data: data,
      topics: topics,
      log_index: TypeTranslator.hex_to_int(log_index)
    }

    EventHandler.handle_event(event)
  end
end
