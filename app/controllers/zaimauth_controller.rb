require 'json'
require 'oauth'

class ZaimauthController < ApplicationController
  CONSUMER_KEY = Rails.application.credentials.zaim_consumer_key
  CONSUMER_SECRET = Rails.application.credentials.zaim_consumer_secret
  CALLBACK_URL = 'http://localhost/callback'
  API_URL = 'https://api.zaim.net/v2/'

  def top
  end

  def login
    set_consumer
    @request_token = @consumer.get_request_token(oauth_callback: 'http://localhost/callback')
    session[:request_token] = @request_token.token
    session[:request_secret] = @request_token.secret
    redirect_to @request_token.authorize_url(:oauth_callback => 'http://localhost/callback')
  end

  def callback
    if session[:request_token] && params[:oauth_verifier]
      set_consumer
      @oauth_verifier = params[:oauth_verifier]
      @request_token = OAuth::RequestToken.new(@consumer, session[:request_token], session[:request_secret])
      access_token = @request_token.get_access_token(:oauth_verifier => @oauth_verifier)
      session[:access_token] = access_token.token
      session[:access_secret] = access_token.secret
      redirect_to money_path
    else
      logout
    end
  end

  def money
    set_consumer
    @access_token = OAuth::AccessToken.new(@consumer, session[:access_token], session[:access_secret])

    params_money = URI.encode_www_form({
      mode: 'payment',
      start_date: Date.today.to_s,
      end_date: Date.today.to_s
    })

    money = @access_token.get("#{API_URL}home/money?#{params_money}")
    @money_today = JSON.parse(money.body)
    @amount_sum_today = @money_today['money'].inject(0) { |result, n| result + n['amount'] }
  end

  private

  def set_consumer
    @consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET,
                                    site: 'https://api.zaim.net',
                                    request_token_path: '/v2/auth/request',
                                    authorize_url: 'https://auth.zaim.net/users/auth',
                                    access_token_path: '/v2/auth/access')
  end
end
