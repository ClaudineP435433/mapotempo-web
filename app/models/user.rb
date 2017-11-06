# Copyright © Mapotempo, 2013-2016
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable

  default_scope { order('LOWER(email)') }

  nilify_blanks
  auto_strip_attributes :url_click2call

  belongs_to :reseller
  belongs_to :customer
  belongs_to :layer

  after_initialize :assign_defaults, if: 'new_record?'
  before_validation :assign_defaults_layer, if: 'new_record?'
  before_save :set_time_zone

  validates :customer, presence: true, unless: :admin?
  validates :layer, presence: true
  validates :locale, length: { is: 2 }, format: { with: /(^fr$)|(^en$)/ }, if: -> (user) { user.locale.present? }

  attr_accessor :send_email

  after_create :send_password_email, if: -> (user) { user.send_email.to_i == 1 }
  after_save :send_connection_email, if: -> (user) { user.confirmed_at_changed? && user.confirmed_at_was.nil? }

  include RefSanitizer

  include Confirmable

  scope :for_reseller_id, ->(reseller_id) { where(reseller_id: reseller_id) }
  scope :from_customers_for_reseller_id, ->(reseller_id) { joins(:customer).where(customers: {reseller_id: reseller_id}) }

  amoeba do
    enable

    customize(lambda { |_original, copy|
      def copy.assign_defaults; end

      def copy.assign_defaults_layer; end

      def copy.generate_confirmation_token; end

      copy.email = I18n.l(Time.zone.now, format: '%Y%m%d%H%M%S') + '_' + copy.email
      copy.password = Devise.friendly_token
      copy.confirmation_token = nil
      copy.reset_password_token = nil
      copy.api_key_random
    })
  end

  def self.unities
    [
      %w(Km km),
      %w(Miles mi)
    ]
  end

  def admin?
    !reseller_id.nil?
  end

  def link_phone_number
    if self.url_click2call
      self.url_click2call
    else
      'tel:+{TEL}'
    end
  end

  def api_key_random
    self.api_key = SecureRandom.hex
  end

  def send_password_email
    locale = (self.locale) ? self.locale.to_sym : I18n.locale
    Mapotempo::Application.config.delayed_job_use ? UserMailer.delay.password_message(self, locale) : UserMailer.password_message(self, locale).deliver_now
    self.update! confirmation_sent_at: Time.now
  end

  def send_connection_email
    locale = (self.locale) ? self.locale.to_sym : I18n.locale
    Mapotempo::Application.config.delayed_job_use ? UserMailer.delay.connection_message(self, locale) : UserMailer.connection_message(self, locale).deliver_now
  end

  private

  def set_default_time_zone
    self.time_zone = self.time_zone == 'UTC' ? I18n.t('default_time_zone') : self.time_zone
  end

  def set_time_zone
    set_default_time_zone if self.time_zone.blank?
  end

  def assign_defaults
    set_default_time_zone
    self.api_key || self.api_key_random
  end

  def assign_defaults_layer
     self.layer ||= if admin?
       Layer.order(:id).find_by!(overlay: false)
    else
      customer && customer.profile.layers.order(:id).find_by!(overlay: false)
    end
  end
end
