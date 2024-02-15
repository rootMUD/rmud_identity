defmodule EventHandler do
  alias Utils.Ethereum.EventLog
  alias Utils.Event


  def abi(), do: File.read!("erc20.abi") |> Jason.decode!()
  def handle_event(event) do
    
    %{signature: signature, args: args} = event_decoded = EventLog.decode(
      abi(),
      event.topics,
      event.data
      )
    %{event: signature, params: args}
  end
end
