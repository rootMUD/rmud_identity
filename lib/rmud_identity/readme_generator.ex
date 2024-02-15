defmodule RmudIdentity.ReadmeGenerator do

  @badge_colors [
    "brightgreen",
    "green",
    "yellowgreen",
    "yellow",
    "orange",
    "red",
    "lightgrey",
    "blue",
  ]

  @client Tentacat.Client.new()
  # @client Tentacat.Client.new(%{access_token: Constants.get_github_token()})
  def generate(params) do
    daos_handled =
      params.daos_joined_in
      |> handle_daos()
      |> handle_daos_to_str()

    urls_in_list =
        Jason.decode!(params.five_awesome_repos)

    articles_handled =
      params.articles
      |> Jason.decode!()
      |> handle_articles()

    github_handled =
      urls_in_list
      |> split_github_urls()
      |> fetch_repos()
      |> abstract_repos()
      |> handle_repos_to_str(urls_in_list)
    # build the readme raw by params
    "# #{params.name}\n\n"
    |> Kernel.<>(
      "#{params.description}\n\n"
    )
    |> Kernel.<>(
      "## 0x00 Web3 Addresses\n\n"
    )
    |> Kernel.<>(
      "**Eth Address:** \[#{params.eth_addr}\]\(https://zapper.xyz/account/#{params.eth_addr}\)\n\n"
    )
    |> Kernel.<>(
      "**Aptos Address:** \[#{params.aptos_addr}\]"
    )
    |> Kernel.<>(
      "\(https://explorer.aptoslabs.com/account/#{params.aptos_addr}?network=mainnet\)\n\n"
    )
    |> Kernel.<>(
      "## 0x01 Awesome Repos\n\n"
    )
    |> Kernel.<>(
      "#{github_handled}"
    )
    |> Kernel.<>(
      "## 0x02 Articles\n\n"
    )
    |> Kernel.<>(
      "#{articles_handled}"
    )
    |> Kernel.<>(
      "## 0x03 DAOs Joined in\n\n"
    )
    |> Kernel.<>(
      "#{daos_handled}"
    )
    |> Kernel.<>(
    "*Generated by Web3 README Geneator@NonceGeekDAO*"
    )
  end

  def handle_daos(daos_joined_in_str) do
    daos_joined_in_list =
      Jason.decode!(daos_joined_in_str)
    Enum.map(daos_joined_in_list, fn dao_name ->
      gen_badge(dao_name)
    end)
  end

  def handle_daos_to_str(daos_handled) do
    Enum.reduce(daos_handled, "", fn dao, acc ->
      acc <> dao <> "\n\n"
    end)
  end

  def gen_badge("NonceGeekDAO") do
    "[![](https://img.shields.io/badge/NonceGeekDAO-cool--oriented--programming-blue)](https://github.com/NonceGeek)"
  end

  def gen_badge(other_name) do
    rnd_color = gen_rand_color()
    "[![](https://img.shields.io/badge/#{other_name}-#{rnd_color})]()"
  end

  def gen_rand_color(), do: Enum.random(@badge_colors)

  def split_github_urls(urls_in_list) do
    Enum.map(urls_in_list, fn url ->
      {_, [org_name, repo_name]} =
        url
        |> String.split("/")
        |> Enum.split(-2)
      %{
        org_name: org_name,
        repo_name: repo_name
    }
    end)
  end

  def fetch_repos(repos) do
    Enum.map(repos, fn %{org_name: org_name, repo_name: repo_name} ->
      {200, res, _req} =
        Tentacat.Repositories.repo_get(@client, org_name, repo_name)
      ExStructTranslator.to_atom_struct(res)
    end)
  end

  def abstract_repos(repos) do
    Enum.map(repos, fn repo ->
      %{
        topics: repo.topics,
        description: repo.description,
        stars: repo.stargazers_count,
        name: repo.name
      }
    end)
  end

  def handle_repos_to_str(repos, repo_urls) do
    repos
    |> Enum.zip(repo_urls)
    |> Enum.reduce("", fn {%{topics: topics, description: descri, stars: stars, name: name}, url}, acc ->
      acc
      |> Kernel.<>("#### [#{name}](#{url})\n\n")
      |> Kernel.<>("* **description:** #{descri}\n\n")
      |> Kernel.<>("* **stars:** #{stars}\n\n")
      |> Kernel.<>("* **tags:** #{inspect(topics)}\n\n")
      # |> Kernel.<>("---\n\n")
    end)
  end

  def handle_articles(articles) do
    articles
    |> Enum.reduce("", fn article, acc ->
      acc
      |> Kernel.<>("* #{article}\n\n")
    end)
  end
end
