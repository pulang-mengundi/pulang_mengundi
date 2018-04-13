class RequestsController < ApplicationController
  def index
    @requests = policy_scope(Request).without_disabled.where('remaining_balance > ?', 0)

    @search_state_seat = params.dig(:search, :state_seat)
    if @search_state_seat.present?
      if ElectoralDistrict::STATES.include?(@search_state_seat)
        @requests = @requests.where(to_state: @search_state_seat)
      else
        @requests = @requests.where(to_city: @search_state_seat)
      end
    end

    @bank_name = params.dig(:search, :bank_name)
    if @bank_name.present?
      @requests = @requests.where(bank_name: @bank_name)
    end

    @search_order = params.dig(:search, :order)
    if @search_order.present?
      if @search_order == 'Highest Balance'
        @requests = @requests.order(remaining_balance: :desc)
      elsif @search_order == 'Lowest Balance'
        @requests = @requests.order(remaining_balance: :asc)
      else
        @requests = @requests.order("RANDOM()")
      end
    else
      @requests = @requests.order("RANDOM()")
    end

    @requests = @requests.paginate(:page => params[:page], :per_page => 50)

    @total_number_of_requests = Request.count
    @total_amount_pledged = Pledge.requester_received.sum(:amount)
  end

  def new
    @request = Request.new
    authorize @request
  end

  def create
    @request = current_user.build_request(request_params)
    authorize @request
    if @request.save
      flash[:success] = 'Request created'
      redirect_to [@request, :thank_you_screens]
    else
      flash[:danger] = @request.errors.full_messages.join("; ")
      render :new
    end
  end

  def show
    @request = Request.find(params[:id])
    authorize(@request)
    @requester = @request.requester

    @disputes = Dispute.where(pledge_id: @request.pledges.pluck(:id))
    @pledge = Pledge.new
  end

  def edit
    @request = Request.find(params[:id])
    authorize @request
  end

  def update
    @request = Request.find(params[:id])
    authorize @request
    if @request.update(request_params)
      flash[:success] = 'Request updated'
      redirect_to @request
    else
      flash[:danger] = @request.errors.full_messages.join("; ")
      render :new
    end
  end

  private
    def request_params
      params.require(:request).permit(:bank_name, :account_number, 
        :account_name, :transport_type, :to_state, :to_city, 
        :description, :travelling_fees, :target_amount, :itinerary, 
        :travel_company, supporting_documents: [])
    end
end