defmodule WebCrawler.ResultParser.Real do
  def parse_result(domain, site_map) do
    count =
      "."
      |> File.ls!()
      |> Enum.reduce(0, fn filename, count ->
        case Regex.run(~r|web_crawler_output_([0-9]).exs|, filename, capture: :all_but_first) do
          nil ->
            count

          [this_count] ->
            {x, ""} = Integer.parse(this_count)

            Enum.max([count, x + 1])
        end
      end)

    filename = "web_crawler_output_#{count}.exs"

    IO.puts("writing sitemap to #{filename}...")

    File.write!(
      filename,
      "#{
        inspect(%{domain: domain, site_map: site_map},
          limit: :infinity,
          printable_limit: :infinity
        )
      }"
    )

    Mix.Task.run("format", [filename])

    IO.puts("done")
  end
end
