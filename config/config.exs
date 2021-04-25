import Config

config :web_crawler, :http_module, HTTPoison
config :web_crawler, :result_module, WebCrawler.ResultParser.Real

import_config "#{Mix.env()}.exs"
