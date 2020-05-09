class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable,, :registerable, and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable
end
