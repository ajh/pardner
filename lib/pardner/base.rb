require 'delegate'

module Pardner
  # A base class for creating an active model that decorate an active record
  # model to add behavior. Common active record persistence methods are
  # available and delegated to the decorated active record instance.
  #
  # To use:
  #
  # 1. create a subclass of Pardner::Base
  # 2. call .pardner_config to configure things
  # 3. override methods, add validations, add callbacks etc to get custom
  #    behavior
  #
  # For example:
  #
  #   class BookDecorator < Pardner::Base
  #     pardner_config Book
  #
  #     after_save :send_email
  #
  #     private
  #
  #     def send_email
  #       BookMailer.saved_book(self).deliver_now
  #     end
  #   end
  #
  class Base < SimpleDelegator
    extend ActiveModel::Callbacks
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    class_attribute :pardner_config

    define_model_callbacks \
      :destroy,
      :save,
      :validation

    # Configure the decorator by calling this. Pass in one or many classes
    # that will be delegated to. Define a block which'll be passed a
    # configuration object to configure more things.
    def self.howdy_pardner(decorated_class)
      self.pardner_config = pardner_config ? pardner_config.deep_dup : Config.new
      pardner_config.decorated_class = decorated_class
      nil
    end

    def initialize(decorated_record)
      __setobj__ decorated_record
    end

    # Returns the decorated record
    def decorated_record
      __getobj__
    end

    # Returns the decorated record deeply, ignoring any nested decorators.
    def decorated_record_deep
      __getobj__.is_a?(Pardner::Base) ? __getobj__.decorated_record_deep : __getobj__
    end

    def self.model_name
      if pardner_config.try(:decorated_class)
        pardner_config.decorated_class.model_name
      else
        super
      end
    end

    def [](attr)
      send(attr)
    end

    def []=(attr, value)
      send("#{attr}=", value)
    end

    def attributes=(attrs = {})
      attrs.each do |attr, value|
        public_send "#{attr}=", value
      end
    end

    def save
      valid? or return false

      status = ActiveRecord::Base.transaction do
        run_callbacks(:save) { super }
      end

      status == true
    end

    def save!
      save or fail InvalidModel, "Validation failed: #{errors.full_messages.join(',')}"
    end

    def destroy
      ActiveRecord::Base.transaction do
        run_callbacks(:destroy) { super }
      end
    end

    def update(attrs = {})
      self.attributes = attrs
      save
    end
    alias_method :update_attributes, :update

    def update!(attrs = {})
      update attrs or
        fail InvalidModel, "Validation failed: #{errors.full_messages.join(',')}"
    end
    alias_method :update_attributes!, :update!

    def valid?
      run_callbacks :validation do
        if super && __getobj__.valid?
          true
        else
          __getobj__.errors.each do |attr, msg|
            errors.add attr, msg
          end

          false
        end
      end
    end

    def persisted?
      decorated_record.persisted?
    end

    def new_record?
      !persisted?
    end
  end
end
