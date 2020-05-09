class HomeController < ApplicationController
  def home
    redirect_to '/admin', status: :see_other
  end
end
