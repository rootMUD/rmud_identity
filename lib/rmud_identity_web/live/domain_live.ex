defmodule RmudIdentityWeb.DomainLive do
  alias RmudIdentity.RmudIdentityHandler
  alias W
  alias RmudIdentity.Contracts.RmudInteractor
  alias RmudIdentity.RmudAccounts

  use RmudIdentityWeb, :live_view

  @price Decimal.new("100000000000000000000")

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       modal: false,
       form: to_form(%{}, as: :form),
       form_register: to_form(%{}, as: :form_register),
       slide_over: false,
       pagination_page: 1,
       active_tab: :live,
       show_domain_status: 0
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
        <center><.h1>RMUD Unique Domain</.h1>
        <br>
        <.h5>
          ꃔ Get the UNIQUE domain in RootMUDverse ꃔ
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
          <br><br>
          <.p>Domain you want❤️❤️❤️:</.p>
          <br>
          <div style="display: flex; justify-content: center; align-items: center; gap: 10px;">
            <.text_input form={f} field={:domain} placeholder="LeeDuckGo" value={assigns[:form_now]["domain"]} style="width:300px"/>
            <.h5 style="margin: 0; align-self: center;">
                <span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500">
                .rootmud.app
                </span>
            </.h5>
            &nbsp;&nbsp;&nbsp;&nbsp;

            <.button color="success" label="Search!" variant="shadow"/>

          </div>
        </.form>
          <br>
          <%= case @show_domain_status  do %>
          <%= 0 -> %>
          <%= 1 -> %>
             <.p>The Domain length small than 3 is not avaiable yet!</.p>
            <%= 2 -> %>
                <.p>This Domain is resigtered yet!</.p>
                
                <.p>The owner is: </.p>
                <.h5 style="margin: 0; align-self: center;">
                    <span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500">
                    <%= assigns[:acct].rmud_address %>
                    </span>
                </.h5>
            <%= 3 -> %>
                <.p>Congratulations! This Domain is available!</.p>
                <.form
                let={f}
                for={@form_register}
                id="code-loader-form"
                phx_submit="submit_form_register"
            >
                <br><br>
                <.p>
                    <b>Pay 100 $RMUD to 0x73c7448760517E3E6e416b2c130E3c6dB2026A1d</b>
                    <a href="https://google.com" style="text-decoration: underline;" target="_blank">(How🤔?)</a>
                </.p>
                <.p>&</.p>
                <.p>
                    <b>Ensure your addr has $RMUD more than 3000!</b>
                </.p>
                <.p>&</.p>
                <.p>
                    <b>Register RMUD ID first</b>
                </.p>
                <.p>Then Paste your tx here:</.p>
                <br>
                    <.text_input form={f} field={:tx_id} placeholder="0x..." style="width:600px"/>
                <br>
                <.button color="secondary" label="CLIAM YoUr Unique RMUD Domain!❤️" variant="shadow"/>
                <br>
                </.form>
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
