# frozen_string_literal: true

require 'event_store_client'
require_relative 'event_store_subscriptions/version'
require_relative 'event_store_subscriptions/wait_for_finish'
require_relative 'event_store_subscriptions/subscription'
require_relative 'event_store_subscriptions/subscription_position'
require_relative 'event_store_subscriptions/subscription_revision'
require_relative 'event_store_subscriptions/subscription_setup'
require_relative 'event_store_subscriptions/object_state'
require_relative 'event_store_subscriptions/subscriptions'
require_relative 'event_store_subscriptions/watch_dog'

module EventStoreSubscriptions
  class Error < StandardError; end
end
