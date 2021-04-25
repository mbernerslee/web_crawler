import Config

config :web_crawler, :http_module, WebCrawler.HTTPMock
config :web_crawler, :result_module, WebCrawler.ResultParser.None
