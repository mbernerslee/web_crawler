defmodule WebCrawler.HTTPMock do
  @the_fake_web %{
    "simple_site.com" => %{
      "/" => ~s|<a href=\"/\">myself</a>|,
      "/dead_end" => ~s|<h1>NO LINKS HERE</h1>|,
      "/links_to_fwd_slash_only" => ~s|<a href=\"/\">link</a>|,
      "/external_link_only" => ~s|<a href=\"www.external-link.com/\">link</a>|,
      "/mix_of_internal_and_external_links" =>
        ~s|<a href=\"www.external-link.com/\">link</a><a href=\"/dead_end\">link</a>|
    },
    "farm.io" => %{
      "/" => "<a href=\"/animals\">link</a><a href=\"/berners_fave_animal\">link</a>",
      "/berners_fave_animal" => "<a href=\"/animals/birds/red_kite\">link</a>",
      "/animals" => "<a href=\"/animals/mammals\">link</a><a href=\"/animals/birds\">link</a>",
      "/animals/mammals" =>
        "<a href=\"/animals/mammals/pig\">link</a><a href=\"/animals/mammals/goat\">link</a>",
      "/animals/mammals/pig" =>
        "<a href=\"/animals/mammals/pig\">link</a><a href=\"/animals/mammals\">link</a>",
      "/animals/mammals/goat" =>
        "<a href=\"/animals/mammals/goat\">link</a><a href=\"/animals/mammals\">link</a>",
      "/animals/birds" => "<a href=\"/animals/birds/red_kite\">link</a>",
      "/animals/birds/red_kite" => "<a href=\"/animals/birds/red_kite\">link</a>",
      "/secret_link_one" =>
        "<a href=\"/secret_link_one\">link</a><a href=\"/secret_link_two\">link</a>",
      "/secret_link_two" =>
        "<a href=\"/secret_link_one\">link</a><a href=\"/secret_link_two\">link</a>"
    }
  }

  def get!(url) do
    %{authority: domain, path: path} = URI.parse(url)

    get!(url, @the_fake_web[domain], path)
  end

  defp get!(url, website, nil), do: get!(url, website, "/")

  defp get!(url, website, path) do
    if body = website[path] do
      %HTTPoison.Response{body: body, status_code: 200, request_url: url}
    else
      raise "THATS NOT ON THE INTERNET!"
    end
  end
end
