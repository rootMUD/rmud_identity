defmodule RmudIdentityWeb.PageLive do
  alias RmudIdentity.RmudIdentityHandler
  alias W
  alias RmudIdentity.Contracts.RmudInteractor
  alias RmudIdentity.RmudAccounts

  use RmudIdentityWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       modal: false,
       form: to_form(%{}, as: :form),
       form_check: to_form(%{}, as: :form_check),
       slide_over: false,
       pagination_page: 1,
       active_tab: :live
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case socket.assigns.live_action do
      :index ->
        {:noreply, assign(socket, modal: false, slide_over: false)}

      :modal ->
        {:noreply, assign(socket, modal: params["size"])}

      :slide_over ->
        {:noreply, assign(socket, slide_over: params["origin"])}

      :pagination ->
        {:noreply, assign(socket, pagination_page: String.to_integer(params["page"]))}
    end
  end

  @impl true
  def handle_event("changed", %{"form" => form}, socket) do
    {:noreply, assign(socket, form_now: form)}
  end

  @impl true
  def handle_event("changed", %{"form_check" => form_check}, socket) do
    {:noreply, assign(socket, form_check_now: form_check)}
  end

  @impl true
  def handle_event("submit", %{"form" => %{"tx_id" => tx_id, "nick_name" => nick_name}}, socket) do
    # check if the tx is valid
    case RmudInteractor.parse_tx(tx_id) do
      {:ok, %{from: rmud_addr}} ->
        # check if the acct in database
        case RmudAccounts.get_by_rmud_addr(rmud_addr) do
          nil ->
            # Claim RMUD ID.
            result = RmudIdentityHandler.init_rmud_identity(tx_id, rmud_addr, nick_name)

            case result do
              {:ok, _} ->
                {
                  :noreply,
                  socket
                  |> put_flash(:info, "created rmud identity success!")
                }

              others ->
                {
                  :noreply,
                  socket
                  |> put_flash(:error, "this address has a rmud indentity already!")
                }
            end

          others ->
            {
              :noreply,
              socket
              |> put_flash(:error, "this address has a rmud indentity already!")
            }
        end

      others ->
        {
          :noreply,
          socket
          |> put_flash(:error, "#{inspect(others)}")
        }
    end
  end

  @impl true
  def handle_event("submit", %{"form_check" => %{"addr" => addr}}, socket) do
    addr = String.downcase(addr)
    result =RmudIdentityHandler.get_did_data(addr)
    # got addr from database.
    case result do
      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(:error, "this addr did not register RMUD Identity!")
        }

      {:ok, did_data} ->
        # fetch the information online.
        # return.
        {
          :noreply,
          socket
          |> assign(
            did_data: did_data
          )
        }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""

      <.container class="mt-10 mb-32">
        <center><.h1>RMUD ID</.h1>
        <br>
        <.h5>
          ꃔ The unique, multi-chain decentralized digital identity in rootMUDverse ꃔ
        </.h5>
        </center>
          
        <center>
        <.form
                  let={f}
                  for={@form}
                  id="code-loader-form"
                  phx_change="changed"
                  phx_submit="submit"
          >
          <.p>
            <b>Pay 10 $RMUD to 0x73c7448760517E3E6e416b2c130E3c6dB2026A1d</b>
            <a href="https://google.com" style="text-decoration: underline;" target="_blank">(How🤔?)</a>
          </.p>
          <.p>Then Paste your tx here:</.p>
          <br>
          <.text_input form={f} field={:tx_id} placeholder="0x..." value={assigns[:form_now]["tx_id"]} style="width:600px"/>
          <br>
          <.p>Nickname:</.p>
          <br>
          <.text_input form={f} field={:nick_name} placeholder="John Snow" value={assigns[:form_now]["nick_name"]} style="width:600px"/>
          <br>
          <.button color="secondary" label="CLIAM RMUD ID❤️" variant="shadow"/>
          <br>
        </.form>
        
        <br><hr><br>
        <.h5>
          Check my RMUD Identity
        </.h5>

        <.form
          let={f_check}
          for={@form_check}
          id="code-loader-form"
          phx_change="changed"
          phx_submit="submit"
        >
        <.p>Paste your address here:</.p>
        <br>
        <.text_input form={f_check} field={:addr} placeholder="0x..."  value={assigns[:form_check_now]["addr"]}  style="width:600px"/>
        <br>
        <.button color="white" label="White" variant="inverted" label="View My RMUD Identity🕶"/>
        <br>
        </.form>
        <br>
        <%= if assigns[:did_data] do %>
          <.h5>Address Aggregator</.h5>
          <!--description: "John Snow's acct", key_addr: "0xcf3b4e8b7dadce73a504d7dc0b263aa40cfe06a5fcd26950f7cbf0f1b7ac1f4c", max_id: "1", modified_counter: "1", type: "0" -->
          <.p><b>description: </b><%= assigns[:did_data][:addr_aggregator][:description] %></.p>
          <.p><b>key_addr: </b><%= assigns[:did_data][:addr_aggregator][:key_addr] %></.p>
          <.p><b>type: </b><%= case assigns[:did_data][:addr_aggregator][:type] do
            "0" -> "Human Being"
            "1" -> "DAO"
            "2" -> "Bot"
            _ -> "Others"
          end%>
          </.p>
          <div class="p-1 mt-5 overflow-auto">
          <.table>
            <thead>
              <.tr>
                <.th>Addr</.th>
                <.th>Addr Type</.th>
                <.th>Description</.th>
                <.th>Chains</.th>
              </.tr>
            </thead>
            <tbody>
              <%= for item <- assigns[:did_data][:addr_aggregator][:addr_details] do %>
              <.tr>
                <.td>
                  <%= item.addr %>
                </.td>
                <.td>
                    <%= case item.addr_type do
                      "0" -> "EVM"
                      "1" -> "Aptos"
                      _ -> "Others"
                    end%>
                </.td>
                <.td>
                  <%= item.description %>
                </.td>
                <.td>
                  <%= for chain <- item.chains do %>
                      <%= case chain do 
                        "mapo" -> live_component @socket, RmudIdentityWeb.BadgeComponent, color: "primary", label: "mapo", variant: "outline"
                        "eth" -> live_component @socket, RmudIdentityWeb.BadgeComponent, color: "secondary", label: "eth", variant: "outline"
                        "op" -> live_component @socket, RmudIdentityWeb.BadgeComponent, color: "white", label: "op", variant: "outline"
                        "polygon" -> live_component @socket, RmudIdentityWeb.BadgeComponent, color: "info", label: "polygon", variant: "outline"
                      end %>
                  <% end %>
                </.td>
              </.tr>
              <% end %>
            </tbody>
          
          </.table>
          <br>
          <%= if not (assigns[:did_data][:service_aggregator][:service_details] == []) do %>
          <.h5>Service Aggregator</.h5>
          <div class="p-1 mt-5 overflow-auto">
              <.table>
                <thead>
                  <.tr>
                    <.th>Description</.th>
                    <.th>URL</.th>
                    <.th>Verification URL</.th>
                  </.tr>
                </thead>
                <tbody>
                </tbody>
              </.table>
          </div>
          <% end %>
        </div>
      <% end %>
      </center>

      </.container>

    """
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: "/live")}
  end

  def handle_event("close_slide_over", _, socket) do
    {:noreply, push_patch(socket, to: "/live")}
  end
end
