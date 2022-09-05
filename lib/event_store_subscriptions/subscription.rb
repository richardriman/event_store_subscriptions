# frozen_string_literal: true

module EventStoreSubscriptions
  class Subscription
    include WaitForFinish
    ThreadNotDeadError = Class.new(StandardError)

    attr_accessor :runner
    attr_reader :client, :setup, :state, :position
    private :runner, :runner=

    # @param position [EventStoreSubscriptions::SubscriptionPosition, EventStoreSubscriptions::SubscriptionRevision]
    # @param client [EventStoreClient::GRPC::Client]
    # @param setup [EventStoreSubscriptions::SubscriptionSetup]
    def initialize(position:, client:, setup:)
      @position = position
      @client = client
      @setup = setup
      @state = ObjectState.new
      @runner = nil
    end

    # Start listening for the events
    # @return [EventStoreSubscriptions::Subscription] returns self
    def listen
      self.runner ||=
        Thread.new do
          Thread.current.abort_on_exception = false
          state.running!
          client.subscribe_to_stream(
            *setup.args,
            **adjusted_kwargs,
            &setup.blk
          )
        rescue StandardError => e
          state.last_error = e
          state.dead!
          raise
        end
      self
    end

    # Stop listening for the events. This command is async - the result is not immediate. In order
    # to wait for the runner fully stopped - use #wait_for_finish method.
    # @return [EventStoreSubscriptions::Subscription] returns self
    def stop_listening
      return self unless state.running?

      state.halting!
      stopping_at = Time.now.utc
      Thread.new do
        loop do
          # Give Subscription up to 5 seconds for graceful shutdown
          if Time.now.utc - stopping_at > 5
            runner&.exit
          end
          unless runner&.alive?
            state.stopped!
            self.runner = nil
            break
          end
          sleep 0.1
        end
      end
      self
    end

    # Removes all properties of object and freezes it. You can't delete currently running
    #   Subscription though. You must stop it first.
    # @return [EventStoreSubscriptions::Subscription] frozen object
    # @raise [EventStoreSubscriptions::ThreadNotDeadError] raises this error in case runner Thread
    #   is still alive for some reason. Normally this should never happen.
    def delete
      if runner&.alive?
        raise ThreadNotDeadError, "Can not delete alive Subscription #{self.inspect}"
      end

      instance_variables.each do |var|
        instance_variable_set(var, nil)
      end
      freeze
    end

    private

    # Wraps original handler into our own handler to provide extended functional.
    # @param original_handler [#call]
    # @return [Proc]
    def handler(original_handler)
      proc do |result|
        Thread.current.exit unless state.running?

        position.update(result.success)
        result = EventStoreClient::GRPC::Shared::Streams::ProcessResponse.new.call(
          result.success,
          *process_response_args
        )
        original_handler.call(result)
      end
    end

    # Calculates "skip_deserialization" and "skip_decryption" arguments for the ProcessResponse
    # class. Since we overridden original handler - we need to calculate correct values of arguments
    # to process the response by our own. This method implements the same behavior
    # the event_store_client gem implements(EventStoreClient::GRPC::Client#subscribe_to_stream
    # method).
    # @return [Array<Boolean>]
    def process_response_args
      skip_deserialization =
        if setup.kwargs.key?(:skip_deserialization)
          setup.kwargs[:skip_deserialization]
        else
          client.config.skip_deserialization
        end
      skip_decryption =
        if setup.kwargs.key?(:skip_decryption)
          setup.kwargs[:skip_decryption]
        else
          client.config.skip_decryption
        end
      [skip_deserialization, skip_decryption]
    end

    # Override keyword arguments, provided by dev in EventStoreSubscriptions::Subscriptions#create
    # or EventStoreSubscriptions::Subscriptions#create_for_all methods. This is needed to provide
    # our own handler and to override the starting position of the given stream.
    # @return [Hash]
    def adjusted_kwargs
      kwargs = setup.dup.kwargs
      kwargs.merge!(handler: handler(kwargs[:handler]), skip_deserialization: true)
      return kwargs unless position.present?

      kwargs.merge!(options: position.to_option)
      kwargs
    end
  end
end
