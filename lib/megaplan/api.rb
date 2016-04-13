module Megaplan
  require 'forwardable'

  class Api

    extend Forwardable
    def_delegators 'self.class', :resource_path, :bad_response, :parsed_body

    attr_reader :endpoint, :login, :password

    def initialize(attrs = {})
      @endpoint = attrs[:endpoint]
      @login    = attrs[:login]
      @password = attrs[:password]
    end

    def authenticate
      response = HTTParty.get(auth_path, :query => auth_params)
      if response.success?
        parsed_body(response)["data"]
      else
        bad_response(response, parsed_body(response), auth_params)
      end
    end

    def auth_params
      require 'digest/md5'
      { Login: login, Password: Digest::MD5.hexdigest(password) }
    end

    def auth_path
      "https://" + initial_path + "/BumsCommonApiV01/User/authorize.api"
    end

    def initial_path
      "#{endpoint}.megaplan.ru"
    end

    def get_headers(path)
      attrs = authenticate
      secret_key = attrs['SecretKey']
      date = Time.now.rfc2822
      { "Date"=> date,
        "Accept"=> "application/json",
        "Content-Type" => "application/json",
        "X-Authorization" => "#{attrs['AccessId']}:#{create_signature(secret_key, date, path)}"
      }
    end

    def create_signature(key, date, path)
      require 'cgi'
      require 'openssl'

      data = "GET\n\napplication/json\n#{date}\n#{path}"
      Base64.strict_encode64(OpenSSL::HMAC.hexdigest('sha1', key, data))
    end

    class << self

      def parsed_body(res)
        JSON.parse(res.body) rescue {}
      end

      def to_query(params)
        params.to_a.map { |x| "#{x[0]}=#{x[1]}" }.join("&")
      end

      def query_path(path, query)
        path + (query.any? ? "?#{to_query(query)}" : "")
      end

      def list(client, query = {})
        path = resource_path(client, 'list.api', query)
        headers = client.get_headers(path.gsub('https://', ''))
        response = HTTParty.get(path, :headers => headers)

        if response.success?
          parsed_body(response)
        else
          parsed_body(response)
          #bad_response(response, parsed_body(response), auth_params)
        end
      end

      def save(client, query = {})
        path = resource_path(client, 'save.api', query)
        headers = client.get_headers(path.gsub('https://', ''))
        response = HTTParty.get(path, :headers => headers)

        if response.success?
          parsed_body(response)
        else
          bad_response(response, parsed_body(response), headers)
        end
      end

      def delete(client, query = {})
        path = resource_path(client, 'delete.api', query)
        headers = client.get_headers(path.gsub('https://', ''))
        response = HTTParty.get(path, :headers => headers)

        if response.success?
          parsed_body(response)
        else
          bad_response(response, parsed_body(response), headers)
        end
      end

      def resource_path(client, action_path, query = {})
        class_name = name.split('::').inject(Object) do |mod, class_name|
                      mod.const_get(class_name)
                     end
        class_endpoint = class_name.class_endpoint
        url = "https://#{client.initial_path}" << class_endpoint << action_path
        query_path(url, query)
      end

      def bad_response(response, parsed_body, params={})
        puts params.inspect

        if response.class == HTTParty::Response
          raise HTTParty::ResponseError, response
        end
        raise StandardError, (parsed_body['status']['message'] rescue 'unknown error')
      end
    end

  end

end
