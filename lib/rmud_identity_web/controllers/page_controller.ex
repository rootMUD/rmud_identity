defmodule RmudIdentityWeb.PageController do
  use RmudIdentityWeb, :controller

  def home(conn, _params) do
    render(conn, :home, active_tab: :home)
  end
end
