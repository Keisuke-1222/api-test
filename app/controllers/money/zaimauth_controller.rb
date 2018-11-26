require 'json'
require 'oauth'

class Money::ZaimauthController < ApplicationController
  CONSUMER_KEY = Rails.application.credentials.zaim_consumer_key
  CONSUMER_SECRET = Rails.application.credentials.zaim_consumer_secret
  ACCESS_TOKEN = Rails.application.credentials.zaim_access_token
  ACCESS_SECRET = Rails.application.credentials.zaim_access_secret
  CALLBACK_URL = 'http://localhost/callback'
  API_URL = 'https://api.zaim.net/v2/'

  def top
  end

  def login
    set_consumer
    @request_token = @consumer.get_request_token(oauth_callback: CALLBACK_URL)
    session[:request_token] = @request_token.token
    session[:request_secret] = @request_token.secret
    redirect_to @request_token.authorize_url(:oauth_callback => CALLBACK_URL)
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

  def average
    set_consumer
    @access_token = OAuth::AccessToken.new(@consumer, ACCESS_TOKEN, ACCESS_SECRET)
  end

  def category
    set_consumer
    @access_token = OAuth::AccessToken.new(@consumer, ACCESS_TOKEN, ACCESS_SECRET)

    categories_params = URI.encode_www_form({
      mode: 'payment',
    })

    categories = @access_token.get("#{API_URL}home/category?#{categories_params}")
    @categories = JSON.parse(categories.body)['categories']
  end

  def genres
    set_consumer
    @access_token = OAuth::AccessToken.new(@consumer, ACCESS_TOKEN, ACCESS_SECRET)

    genres_params = URI.encode_www_form({
      genre_id: params[:id]
    })

    genres = @access_token.get("#{API_URL}home/genre?#{genres_params}")
    @genres = JSON.parse(genres.body)['genres'].select { |genre| genre['category_id'] == params[:id].to_i }
  end

  def payment
    payment_params = URI.encode_www_form({
      mapping: 1,
      category_id: 101,
      genre_id: 10101,
      amount: 222,
      date: Date.today.to_s
    })

    payment = @access_token.post("#{API_URL}home/money/payment?#{payment_params}")
  end

  def index
    set_consumer
    @access_token = OAuth::AccessToken.new(@consumer, ACCESS_TOKEN, ACCESS_SECRET)

    message = '3日間の平均'
    if message.include?('平均')
      period = message.delete('^0-9').to_i
      start_date = (Date.today - period + 1).to_s
      end_date = Date.today.to_s
    end

    money_params_food = URI.encode_www_form({
      mode: 'payment',
      # 『食費』のみ抽出する場合はid:101を指定する
      # category_id: 101,
      start_date: start_date,
      end_date: end_date
    })

    money = @access_token.get("#{API_URL}home/money?#{money_params_food}")
    @moneys_all = JSON.parse(money.body)['money']
    @moneys_food = @moneys_all.select { |money| money['category_id'] == 101 }

    @amount_sum = @moneys_all.inject(0) { |result, n| result + n['amount'] }
    @amount_avg = @amount_sum / period
  end

  def answer_from(message)
    if message.include?('平均')
      period = message.delete('^0-9')
      start_date = Date.today.to_s
      end_date = (Date.today - period + 1)
    end

    case message
    when '今日', 'today', 'きょう'
      date = Date.today.to_s
    when '昨日', 'yesterday', 'きのう'
      date = (Date.today - 1).to_s
    when 'おととい', '一昨日'
      dete = (Date.today - 2).to_s
    else
      return 'error'
    end
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
