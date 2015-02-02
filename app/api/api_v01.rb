class ApiV01 < Grape::API
  version '0.1', using: :path

  helpers do
    def warden
      env['warden']
    end

    def current_customer(custimer_id = nil)
      @current_user ||= warden.authenticated? && warden.user
      @current_user ||= params[:api_key] && User.find_by(api_key: params[:api_key])
      @current_customer ||= @current_user && (@current_user.admin? && custimer_id ? Customer.find(custimer_id.to_i) : @current_user.customer)
    end

    def authenticate!
      current_customer
      error!('401 Unauthorized', 401) unless @current_user
      error!('402 Payment Required', 402) if @current_customer && @current_customer.end_subscription && @current_customer.end_subscription < Time.now
    end

    def authorize!
    end
  end

  before do
    authenticate!
    authorize!
    ActiveRecord::Base.connection.begin_transaction
  end

  after do
    begin
      ActiveRecord::Base.connection.commit_transaction unless @error
    rescue Exception
      ActiveRecord::Base.connection.rollback_transaction
      raise
    end
  end

  rescue_from :all do |e|
    @error = e
    Rails::logger.error "\n\n#{e.class} (#{e.message}):\n    " + e.backtrace.join("\n    ") + "\n\n"
    error_response({message: e.message})
  end

  mount V01::Customers
  mount V01::Destinations
  mount V01::OrderArrays
  mount V01::Orders
  mount V01::Plannings
  mount V01::Products
  mount V01::Routes
  mount V01::Stores
  mount V01::Tags
  mount V01::Vehicles
  mount V01::Zonings

  # Tools
  mount V01::Geocoder
end
