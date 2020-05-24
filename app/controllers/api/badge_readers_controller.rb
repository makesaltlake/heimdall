class Api::BadgeReadersController < Api::ApiController
  authenticate_using BadgeReader
end
