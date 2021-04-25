defmodule WebCrawler do
  def crawl(url) do
    %{domain: domain, path: path} = parse_url(url)

    crawl(domain, %{path => :unfetched}, MapSet.new([]))
  end

  defp crawl(domain, site_map, already_fetched_paths) do
    case find_next_path_to_http_get(site_map) do
      :not_found ->
        Application.get_env(:web_crawler, :result_module).parse_result(domain, site_map)

      {:ok, path} ->
        links_from_path = get_linked_paths(domain, path, already_fetched_paths)

        site_map = build_updated_site_map(site_map, path, links_from_path, already_fetched_paths)

        crawl(domain, site_map, MapSet.put(already_fetched_paths, path))
    end
  end

  defp build_updated_site_map(site_map, path, links_from_path, already_fetched_paths) do
    {site_map, _} =
      build_updated_site_map(
        site_map,
        path,
        links_from_path,
        already_fetched_paths,
        {%{}, :not_updated_yet}
      )

    site_map
  end

  defp build_updated_site_map(site_map, path, links_from_path, already_fetched_paths, acc) do
    Enum.reduce(site_map, acc, fn
      {^path, :unfetched}, {new_site_map, :not_updated_yet} ->
        {Map.put(new_site_map, path, links_from_path), :updated}

      {^path, :unfetched}, {new_site_map, :updated} ->
        {Map.put(new_site_map, path, :fetched), :updated}

      {^path, :fetched}, {new_site_map, update_status} ->
        {Map.put(new_site_map, path, :fetched), update_status}

      {other_path, %{} = nested_sitemap}, {new_site_map, update_status} ->
        {updated_nested_sitemap, update_status} =
          build_updated_site_map(
            nested_sitemap,
            path,
            links_from_path,
            already_fetched_paths,
            {%{}, update_status}
          )

        {Map.put(new_site_map, other_path, updated_nested_sitemap), update_status}

      {other_path, _}, {new_site_map, update_status} ->
        fetched_status =
          if MapSet.member?(already_fetched_paths, other_path) do
            :fetched
          else
            :unfetched
          end

        {Map.put(new_site_map, other_path, fetched_status), update_status}
    end)
  end

  defp find_next_path_to_http_get(site_map) do
    find_next_path_to_http_get(site_map, {:cont, :not_found})
  end

  defp find_next_path_to_http_get(site_map, acc) do
    Enum.reduce_while(site_map, acc, fn
      {path, :unfetched}, _acc ->
        {:halt, {:ok, path}}

      {_path, :fetched}, _acc ->
        {:cont, :not_found}

      {_path, nested_site_map}, acc ->
        case find_next_path_to_http_get(nested_site_map, acc) do
          {:ok, path} -> {:halt, {:ok, path}}
          :not_found -> {:cont, :not_found}
          {:cont, :not_found} -> {:cont, :not_found}
        end
    end)
  end

  defp get_linked_paths(domain, path, already_fetched_paths) do
    url = "https://#{domain}#{path}"
    unless Mix.env() == :test, do: IO.inspect("crawling ... #{url}")

    html = make_http_get_request!(url).body

    ~r|href="([^"]+)"|
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> determine_internal_links(domain, path, already_fetched_paths)
  end

  defp make_http_get_request!(url) do
    Application.get_env(:web_crawler, :http_module).get!(url)
  end

  defp determine_internal_links(links, domain, path, already_fetched_paths) do
    determine_internal_links(links, [], domain, path, already_fetched_paths)
  end

  defp determine_internal_links([], acc, _domain, _url, _already_fetched_paths) do
    Map.new(acc)
  end

  defp determine_internal_links([link | rest], acc, domain, path, already_fetched_paths) do
    acc =
      case parse_link(link, domain) do
        {:internal_link, link} ->
          if link == path or MapSet.member?(already_fetched_paths, link) do
            [{link, :fetched} | acc]
          else
            [{link, :unfetched} | acc]
          end

        :external_link ->
          acc
      end

    determine_internal_links(rest, acc, domain, path, already_fetched_paths)
  end

  defp parse_link(link, domain) do
    %{domain: this_domain, path: path} = parse_url(link)

    case {this_domain, String.starts_with?(path, "/")} do
      {^domain, true} -> {:internal_link, path}
      {nil, true} -> {:internal_link, path}
      _ -> :external_link
    end
  end

  defp parse_url(url) do
    uri = URI.parse(url)

    %{domain: uri.authority, path: uri.path || "/"}
  end
end
