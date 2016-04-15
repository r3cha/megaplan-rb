module Megaplan

  class Deal < Api

    class << self

      def class_endpoint
        "/BumsTradeApiV01/Deal/"
      end

      def find(client, query)
        scope = list(client)
        @arr = scope['deals']
        super
      end

      def programs(client, query = {})
        custom_get(client, "/BumsTradeApiV01/Program/list.api", query)
      end

      def list_fields(client, query = {})
        custom_get(client, "/BumsTradeApiV01/Deal/listFields.api", query)['Fields']
      end

    end
  end

end
