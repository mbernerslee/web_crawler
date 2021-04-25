defmodule WebCrawlerTest do
  use ExUnit.Case, async: true

  @doc """
  see WebCrawler.HTTPMock for what happens when these tests make an HTTP get
  """

  describe "crawl/1" do
    test "build sitemap for a very simple site" do
      assert %{domain: "simple_site.com", site_map: %{"/" => %{"/" => :fetched}}} ==
               WebCrawler.crawl("http://simple_site.com/")

      assert %{
               domain: "simple_site.com",
               site_map: %{
                 "/links_to_fwd_slash_only" => %{"/" => %{"/" => :fetched}}
               }
             } == WebCrawler.crawl("http://simple_site.com/links_to_fwd_slash_only")
    end

    test "external links are ignored" do
      assert %{
               domain: "simple_site.com",
               site_map: %{
                 "/external_link_only" => %{}
               }
             } == WebCrawler.crawl("http://simple_site.com/external_link_only")

      assert %{
               domain: "simple_site.com",
               site_map: %{
                 "/mix_of_internal_and_external_links" => %{"/dead_end" => %{}}
               }
             } == WebCrawler.crawl("http://simple_site.com/mix_of_internal_and_external_links")
    end

    test "given a complicated site, only maps each link once, to avoid infinitely following circular links" do
      assert %{
               domain: "farm.io",
               site_map: %{
                 "/" => %{
                   "/animals" => %{
                     "/animals/mammals" => %{
                       "/animals/mammals/goat" => %{
                         "/animals/mammals" => :fetched,
                         "/animals/mammals/goat" => :fetched
                       },
                       "/animals/mammals/pig" => %{
                         "/animals/mammals" => :fetched,
                         "/animals/mammals/pig" => :fetched
                       }
                     },
                     "/animals/birds" => %{
                       "/animals/birds/red_kite" => %{"/animals/birds/red_kite" => :fetched}
                     }
                   },
                   "/berners_fave_animal" => %{"/animals/birds/red_kite" => :fetched}
                 }
               }
             } ==
               WebCrawler.crawl("http://farm.io/")

      assert %{
               domain: "farm.io",
               site_map: %{
                 "/secret_link_one" => %{
                   "/secret_link_one" => :fetched,
                   "/secret_link_two" => %{
                     "/secret_link_one" => :fetched,
                     "/secret_link_two" => :fetched
                   }
                 }
               }
             } ==
               WebCrawler.crawl("http://farm.io/secret_link_one")
    end

    test "returns the same output with or without a trailing / in the URL" do
      assert WebCrawler.crawl("http://simple_site.com/") ==
               WebCrawler.crawl("http://simple_site.com")
    end
  end
end
