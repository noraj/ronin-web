#
# ronin-web - A collection of useful web helper methods and commands.
#
# Copyright (c) 2006-2023 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# ronin-web is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ronin-web is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ronin-web.  If not, see <https://www.gnu.org/licenses/>.
#

require 'ronin/web/cli/command'
require 'ronin/support/network/http'

require 'nokogiri'

module Ronin
  module Web
    class CLI
      module Commands
        #
        # Performs XPath/CSS-path queries on a URL or HTML file.
        #
        # ## Usage
        #
        #     ronin-web html [options] {URL | FILE} [XPATH | CSS-path]
        #
        # ## Options
        #
        #     -X, --xpath XPATH                XPath query
        #     -C, --css-path CSSPath           CSS-path query
        #     -M, --meta-tags                  Searches for all <meta ...> tags
        #     -l, --links                      Searches for all <a href="..."> URLs
        #     -S, --style                      Dumps all <style> tags
        #     -s, --stylesheet-urls            Searches for all <link type="text/css" href="..."/> URLs
        #     -J, --javascript                 Dumps all javascript source code
        #     -j, --javascript-urls            Searches for all <script src="..."> URLs
        #     -f, --form-urls                  Searches for all <form action="..."> URLS
        #     -u, --urls                       Dumps all URLs in the page
        #     -F, --first                      Only print the first match
        #     -h, --help                       Print help information
        #
        # ## Arguments
        #
        #     URL | FILE                       The URL or FILE to search
        #     [XPATH | CSS-path]               The XPath or CSS-path query
        #
        class Html < Command

          usage '[options] {URL | FILE} [XPATH | CSS-path]'
          
          option :xpath, short: '-X',
                         value: {type: String, usage: 'XPATH'},
                         desc:  'XPath query' do |xpath|
                           @query = xpath
                         end

          option :css_path, short: '-C',
                            value: {type: String, usage: 'CSSPath'},
                            desc:  'CSS-path query' do |css_path|
                              @query = css_path
                            end

          option :meta_tags, short: '-M',
                             desc: 'Searches for all <meta ...> tags' do
                               @query = '//meta'
                             end

          option :links, short: '-l',
                         desc: 'Searches for all <a href="..."> URLs' do
                           @query = '//a/@href'
                         end

          option :style, short: '-S',
                          desc: 'Dumps all <style> tags' do
                            @query = '//style/text()'
                          end

          option :stylesheet_urls, short: '-s',
                                   desc: 'Searches for all <link type="text/css" href="..."/> URLs' do
                                     @query = '//link[@rel="stylesheet"]/@href'
                                   end

          option :javascript, short: '-J',
                              desc: 'Dumps all javascript source code' do
                                @query = '//script/text()'
                              end

          option :javascript_urls, short: '-j',
                                   desc: 'Searches for all <script src="..."> URLs' do
                                     @query = '//script/@src'
                                   end

          option :form_urls, short: '-f',
                             desc: 'Searches for all <form action="..."> URLS' do
                               @query = '//form/@action'
                             end

          option :urls, short: '-u',
                        desc: 'Dumps all URLs in the page' do
                          @query = '//a/@href | //link/@href | //script/@src | //form/@action'
                        end

          option :first, short: '-F',
                         desc: 'Only print the first match'

          argument :source, required: true,
                            usage: 'URL | FILE',
                            desc:  'The URL or FILE to search'

          argument :query, required: false,
                           usage: 'XPATH | CSS-path',
                           desc: 'The XPath or CSS-path query'

          description 'Performs XPath/CSS-path queries on a URL or HTML file'

          man_page 'ronin-web-html.1'

          #
          # Runs the `ronin-web xpath` command.
          #
          # @param [String] source
          #   The `URL` or `FILE` argument.
          #
          # @param [String, nil] query
          #   The optional XPath or CSS-path argument.
          #
          def run(source,query=@query)
            unless query
              print_error "must specify --xpath, --css-path, or an XPath/CSS-path argument"
              exit -1
            end

            doc   = Nokogiri::HTML(read(source))
            nodes = if options[:first] then [doc.at(query)]
                    else                    doc.search(query)
                    end

            nodes.each do |node|
              puts node
            end
          end

          #
          # Reads a URI or file.
          #
          # @param [String] source
          #   The URI or file path.
          #
          # @return [File, String]
          #   The contents of the URI or file.
          #
          def read(source)
            if source.start_with?('https://') ||
               source.start_with?('http://')
              Support::Network::HTTP.get_body(source)
            else
              File.new(source)
            end
          end

        end
      end
    end
  end
end
