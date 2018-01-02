# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController because it doesn't need to
class AlaveteliPro::StripeWebhooksController < ApplicationController

  before_action :read_event_notification, :check_for_event_type, :filter_hooks

  class UnhandledStripeWebhookError < StandardError ; end

  def receive
    begin
      case @stripe_event.type
      when 'customer.subscription.deleted'
        customer_id = @stripe_event.data.object.customer
        if account = ProAccount.find_by(stripe_customer_id: customer_id)
          account.user.remove_role(:pro)
        end
      when 'invoice.payment_succeeded'
        charge_id = @stripe_event.data.object.charge
        charge = Stripe::Charge.retrieve(charge_id)
        charge.description = AlaveteliConfiguration.pro_site_name
        charge.save
      else
        raise UnhandledStripeWebhookError.new(@stripe_event.type)
      end
    rescue UnhandledStripeWebhookError => e
      notify_exception(e)
    end

    # send a 200 ok to acknowlege receipt of the webhook
    # https://stripe.com/docs/webhooks#responding-to-a-webhook
    render json: {}, status: 200
  end

  private

  def read_event_notification
    payload = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = AlaveteliConfiguration.stripe_webhook_secret
    @stripe_event = nil

    begin
      @stripe_event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload, reject the webhook
      notify_exception(e)
      render json: { error: e.message }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature, reject the webhook
      notify_exception(e)
      render json: { error: e.message }, status: 401
      return
    end
  end

  def check_for_event_type
    unless @stripe_event.respond_to?(:type)
      e = NoMethodError.new("undefined method `type' for " \
                            "#{@stripe_event.inspect}")
      # reject the webhook
      notify_exception(e)
      render json: { error: e.message }, status: 400
      return
    end
  end

  def notify_exception(error)
    if send_exception_notifications?
      ExceptionNotifier.notify_exception(error, :env => request.env)
    end
  end

  # ignore any that don't match our plan namespace
  def filter_hooks
    plans = []
    case @stripe_event.data.object.object
    when 'subscription'
      plans = get_plan_names(@stripe_event.data.object.items)
    when 'invoice'
      plans = get_plan_names(@stripe_event.data.object.lines)
    end

    # ignore any plans that don't start with our namespace
    plans.delete_if { |plan| !plan_matches_namespace(plan) }

    if plans.empty?
      # reject it and throw it away, the emails are just noise
      render json: { error: 'Does not appear to be one of our plans' },
             status: 401
      return
    end
  end

  def plan_matches_namespace(plan_name)
    (AlaveteliConfiguration.stripe_namespace == '' ||
     plan_name =~ /^#{AlaveteliConfiguration.stripe_namespace}/)
  end

  def get_plan_names(items)
    items.map { |item| item.plan.name if item.plan }.compact.uniq
  end
end
