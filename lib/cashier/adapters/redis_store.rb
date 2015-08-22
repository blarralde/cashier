module Cashier
  module Adapters
    class RedisStore
      def self.redis
        @@redis
      end

      def self.redis=(redis_instance)
        @@redis = if redis_instance.is_a? ConnectionPool
          redis_instance
        else
          ConnectionPool.new do
            redis_instance
          end
        end
      end

      def self.redis_pool
        @@redis
      end

      def self.store_fragment_in_tag(fragment, tag)
        redis_pool.with do |pool|
          pool.sadd(tag, fragment)
        end
      end

      def self.store_tags(tags)
        redis_pool.with do |pool|
          tags.each { |tag| pool.sadd(Cashier::CACHE_KEY, tag) }
        end
      end

      def self.remove_tags(tags)
        redis_pool.with do |pool|
          tags.each { |tag| pool.srem(Cashier::CACHE_KEY, tag) }
        end
      end

      def self.tags
        redis_pool.with do |pool|
          pool.smembers(Cashier::CACHE_KEY) || []
        end
      end

      def self.get_fragments_for_tag(tag)
        redis_pool.with do |pool|
          pool.smembers(tag) || []
        end
      end

      def self.delete_tag(tag)
        redis_pool.with do |pool|
          pool.del(tag)
        end
      end

      def self.clear
        remove_tags(tags)
        redis_pool.with do |pool|
          redis.del(Cashier::CACHE_KEY)
        end
      end

      def self.keys
        tags.inject([]) { |arry, tag| arry += get_fragments_for_tag(tag) }.compact
      end
    end
  end
end
