defmodule RmudIdentityWeb.DAOLive do
  alias RmudIdentity.RmudIdentityHandler
  alias W
  alias RmudIdentity.Contracts.RmudInteractor
  alias RmudIdentity.RmudAccounts

  use RmudIdentityWeb, :live_view

  @price Decimal.new("100000000000000000000")
  @addr "0xd6d3624f03beb350ffaf5f070430633dcd04a4a5"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, did_data} = RmudIdentityHandler.get_did_data(@addr)
    {:ok,
     assign(socket,
       modal: false,
       form: to_form(%{}, as: :form),
       form_register: to_form(%{}, as: :form_register),
       slide_over: false,
       pagination_page: 1,
       active_tab: :live,
       show_domain_status: 0,
       did_data: did_data
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

  #   @impl true
  #   def handle_event("changed", %{"form_register" => form_register}, socket) do
  #     {:noreply, assign(socket, form_register_now: form_register)}
  #   end

  @impl true
  def handle_event("submit", %{"form" => %{"domain" => domain}}, socket) do
    domain = String.downcase(domain)
    if String.length(domain) <= 3 do
      {
        :noreply,
        socket
        |> assign(show_domain_status: 1)
      }
    else
      # check if the domain is registered
      case RmudAccounts.get_by_domain(domain) do
        nil ->
          {
            :noreply,
            socket
            |> assign(show_domain_status: 3)
          }

        acct ->
          {
            :noreply,
            socket
            |> assign(
              acct: acct,
              show_domain_status: 2
            )
          }
      end
    end
  end

  @impl true
  def handle_event("submit_form_register", %{"form_register" => %{"tx_id" => tx_id}}, socket) do
    case RmudInteractor.parse_tx(tx_id, @price) do
      {:ok, %{from: rmud_addr}} ->
        balance = RmudInteractor.balance_of(rmud_addr)
        # IO.puts(inspect(balance))

        if not Decimal.lt?(balance, Decimal.new("3000")) do
          register_domain(tx_id, rmud_addr, socket.assigns.form_now["domain"], socket)
        else
          {
            :noreply,
            socket
            |> put_flash(:error, "the $RMUD in this addr is less than 3000!")
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

  def register_domain(tx_id, rmud_addr, domain, socket) do
    # find account in database.
    acct = RmudAccounts.get_by_rmud_addr(String.downcase(rmud_addr))
    if tx_id == acct.paid_tx do
      {
        :noreply,
            socket
            |> put_flash(:error, "this tx has used already!")
      }
    else
      case acct do
        nil ->
          {
            :noreply,
            socket
            |> put_flash(:error, "you should register RMUD ID first")
          }
  
        acct ->
          # check if domain in acct.
          if is_nil(acct.domain) or acct.domain == "" do
              # update did with domain.
              result = RmudIdentityHandler.add_domain_service(
                  tx_id,
                  acct.rmud_address, 
                  String.downcase(domain), 
                  acct, 
                  acct.private_key
              )
              {
              :noreply,
                  socket
                  |> put_flash(:info, "register rmud domain success!")
                  |> assign(show_domain_status: 0)
              }
          else
              {
              :noreply,
                  socket
                  |> put_flash(:error, "this rmud identity has registered domain already!")
              }
          end
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""

      <.container class="mt-10 mb-32">
        <center><.h1>RMUD DAO System</.h1>
        <br>
        <.h5>
            ꄃ Hodl the multi-chain assets by all DAO members. ꄃ
        </.h5>
        <.h5>
            ꄃ 让所有 DAO 成员共同持有全链资产。 ꄃ
        </.h5>
        </center>
          
        <center>
        <br>
        <div style="display: flex; justify-content: center; align-items: center; gap: 10px;">
            <.h5 style="margin: 0; align-self: center;">
                DAO DOMAIN: &nbsp;&nbsp;<span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500">
                    dao.rootmud.app
                </span>
            </.h5>
        </div>
        <br><hr><br>
        <div>
            <.h5 style="margin: 0; align-self: center;">
                DAO INFO
            </.h5>
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
                        "2" -> "BTC"
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
                          "btc" -> live_component @socket, RmudIdentityWeb.BadgeComponent, color: "warning", label: "btc", variant: "outline"
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
                      <.th>Spec Fields</.th>
                    </.tr>
                  </thead>
                  <tbody>
                  <%= for item <- assigns[:did_data][:service_aggregator][:service_details] do %>
                  <!-- %{description: "The unique domain service of rmud", expired_at: "0", spec_fields: "['domain': test]", url: "https://id.rootmud.xyz/domain?addr=0x0", verification_url: ""} -->
                  <.tr>
                    <.td>
                      <%= item.description %>
                    </.td>  
                    <.td>
                      <%= item.url %>
                    </.td>  
                    <.td>
                      <%= item.verification_url %>
                    </.td>
                    <.td>
                      <%= item.spec_fields %>
                    </.td>    
                  </.tr>
                  <% end %>
  
                  </tbody>
                </.table>
            </div>
            <% end %>
          </div>
        <% end %>
        </div>
          

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
