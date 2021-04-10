Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # helper to scope routes to a controller. useful where you would use
  # `resource` but don't actually want any of the default routes `resource`
  # will give you.
  def controller_namespace(name)
    scope path: name, controller: name, as: name do
      yield
    end
  end

  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  post '/webhooks/stripe', to: 'webhooks/stripe#webhook'
  post '/webhooks/waiverforever', to: 'webhooks/waiver_forever#webhook'

  get '/nfc/bins/:id', to: 'nfc#bin', as: :nfc_bin

  namespace :api do
    controller_namespace :badge_writers do
      get :firmware_blob
      get :wireless_credentials
      post :program
    end
    controller_namespace :badge_readers do
      get :access_list
      get :binary_access_list
      get :firmware_blob
      get :wireless_credentials
      post :record_scans
      post :record_binary_scan
    end
  end

  # Fallback route: direct all other routes to the frontend app
  get '*path', to: 'frontend#frontend'
  root to: 'frontend#frontend'
end

# == Route Map
#
#                                   Prefix Verb       URI Pattern                                                                              Controller#Action
#                         new_user_session GET        /admin/login(.:format)                                                                   active_admin/devise/sessions#new
#                             user_session POST       /admin/login(.:format)                                                                   active_admin/devise/sessions#create
#                     destroy_user_session DELETE|GET /admin/logout(.:format)                                                                  active_admin/devise/sessions#destroy
#                        new_user_password GET        /admin/password/new(.:format)                                                            active_admin/devise/passwords#new
#                       edit_user_password GET        /admin/password/edit(.:format)                                                           active_admin/devise/passwords#edit
#                            user_password PATCH      /admin/password(.:format)                                                                active_admin/devise/passwords#update
#                                          PUT        /admin/password(.:format)                                                                active_admin/devise/passwords#update
#                                          POST       /admin/password(.:format)                                                                active_admin/devise/passwords#create
#                          new_user_unlock GET        /admin/unlock/new(.:format)                                                              active_admin/devise/unlocks#new
#                              user_unlock GET        /admin/unlock(.:format)                                                                  active_admin/devise/unlocks#show
#                                          POST       /admin/unlock(.:format)                                                                  active_admin/devise/unlocks#create
#                               admin_root GET        /admin(.:format)                                                                         admin/dashboard#index
#  regenerate_api_token_admin_badge_reader POST       /admin/badge_readers/:id/regenerate_api_token(.:format)                                  admin/badge_readers#regenerate_api_token
#      reveal_api_token_admin_badge_reader GET        /admin/badge_readers/:id/reveal_api_token(.:format)                                      admin/badge_readers#reveal_api_token
#   request_manual_open_admin_badge_reader POST       /admin/badge_readers/:id/request_manual_open(.:format)                                   admin/badge_readers#request_manual_open
#                      admin_badge_readers GET        /admin/badge_readers(.:format)                                                           admin/badge_readers#index
#                                          POST       /admin/badge_readers(.:format)                                                           admin/badge_readers#create
#                   new_admin_badge_reader GET        /admin/badge_readers/new(.:format)                                                       admin/badge_readers#new
#                  edit_admin_badge_reader GET        /admin/badge_readers/:id/edit(.:format)                                                  admin/badge_readers#edit
#                       admin_badge_reader GET        /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#show
#                                          PATCH      /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#update
#                                          PUT        /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#update
#                                          DELETE     /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#destroy
#                        admin_badge_scans GET        /admin/badge_scans(.:format)                                                             admin/badge_scans#index
#                         admin_badge_scan GET        /admin/badge_scans/:id(.:format)                                                         admin/badge_scans#show
#      revoke_admin_certification_issuance GET        /admin/certification_issuances/:id/revoke(.:format)                                      admin/certification_issuances#revoke
#                                          POST       /admin/certification_issuances/:id/revoke(.:format)                                      admin/certification_issuances#revoke
#            admin_certification_issuances GET        /admin/certification_issuances(.:format)                                                 admin/certification_issuances#index
#                                          POST       /admin/certification_issuances(.:format)                                                 admin/certification_issuances#create
#         new_admin_certification_issuance GET        /admin/certification_issuances/new(.:format)                                             admin/certification_issuances#new
#        edit_admin_certification_issuance GET        /admin/certification_issuances/:id/edit(.:format)                                        admin/certification_issuances#edit
#             admin_certification_issuance GET        /admin/certification_issuances/:id(.:format)                                             admin/certification_issuances#show
#                                          PATCH      /admin/certification_issuances/:id(.:format)                                             admin/certification_issuances#update
#                                          PUT        /admin/certification_issuances/:id(.:format)                                             admin/certification_issuances#update
#                     admin_certifications GET        /admin/certifications(.:format)                                                          admin/certifications#index
#                                          POST       /admin/certifications(.:format)                                                          admin/certifications#create
#                  new_admin_certification GET        /admin/certifications/new(.:format)                                                      admin/certifications#new
#                 edit_admin_certification GET        /admin/certifications/:id/edit(.:format)                                                 admin/certifications#edit
#                      admin_certification GET        /admin/certifications/:id(.:format)                                                      admin/certifications#show
#                                          PATCH      /admin/certifications/:id(.:format)                                                      admin/certifications#update
#                                          PUT        /admin/certifications/:id(.:format)                                                      admin/certifications#update
#                                          DELETE     /admin/certifications/:id(.:format)                                                      admin/certifications#destroy
#                          admin_dashboard GET        /admin/dashboard(.:format)                                                               admin/dashboard#index
# admin_delayed_backend_active_record_jobs GET        /admin/delayed_backend_active_record_jobs(.:format)                                      admin/delayed_backend_active_record_jobs#index
#  admin_delayed_backend_active_record_job GET        /admin/delayed_backend_active_record_jobs/:id(.:format)                                  admin/delayed_backend_active_record_jobs#show
#           activate_admin_firmware_bundle POST       /admin/firmware_bundles/:id/activate(.:format)                                           admin/firmware_bundles#activate
#                   admin_firmware_bundles GET        /admin/firmware_bundles(.:format)                                                        admin/firmware_bundles#index
#                                          POST       /admin/firmware_bundles(.:format)                                                        admin/firmware_bundles#create
#                new_admin_firmware_bundle GET        /admin/firmware_bundles/new(.:format)                                                    admin/firmware_bundles#new
#               edit_admin_firmware_bundle GET        /admin/firmware_bundles/:id/edit(.:format)                                               admin/firmware_bundles#edit
#                    admin_firmware_bundle GET        /admin/firmware_bundles/:id(.:format)                                                    admin/firmware_bundles#show
#                                          PATCH      /admin/firmware_bundles/:id(.:format)                                                    admin/firmware_bundles#update
#                                          PUT        /admin/firmware_bundles/:id(.:format)                                                    admin/firmware_bundles#update
#                                          DELETE     /admin/firmware_bundles/:id(.:format)                                                    admin/firmware_bundles#destroy
#                    admin_inventory_areas GET        /admin/inventory_areas(.:format)                                                         admin/inventory_areas#index
#                                          POST       /admin/inventory_areas(.:format)                                                         admin/inventory_areas#create
#                 new_admin_inventory_area GET        /admin/inventory_areas/new(.:format)                                                     admin/inventory_areas#new
#                edit_admin_inventory_area GET        /admin/inventory_areas/:id/edit(.:format)                                                admin/inventory_areas#edit
#                     admin_inventory_area GET        /admin/inventory_areas/:id(.:format)                                                     admin/inventory_areas#show
#                                          PATCH      /admin/inventory_areas/:id(.:format)                                                     admin/inventory_areas#update
#                                          PUT        /admin/inventory_areas/:id(.:format)                                                     admin/inventory_areas#update
#                                          DELETE     /admin/inventory_areas/:id(.:format)                                                     admin/inventory_areas#destroy
#         bulk_create_admin_inventory_bins GET        /admin/inventory_bins/bulk_create(.:format)                                              admin/inventory_bins#bulk_create
#                                          POST       /admin/inventory_bins/bulk_create(.:format)                                              admin/inventory_bins#bulk_create
#  finish_bulk_create_admin_inventory_bins GET        /admin/inventory_bins/finish_bulk_create(.:format)                                       admin/inventory_bins#finish_bulk_create
#                     admin_inventory_bins GET        /admin/inventory_bins(.:format)                                                          admin/inventory_bins#index
#                                          POST       /admin/inventory_bins(.:format)                                                          admin/inventory_bins#create
#                  new_admin_inventory_bin GET        /admin/inventory_bins/new(.:format)                                                      admin/inventory_bins#new
#                 edit_admin_inventory_bin GET        /admin/inventory_bins/:id/edit(.:format)                                                 admin/inventory_bins#edit
#                      admin_inventory_bin GET        /admin/inventory_bins/:id(.:format)                                                      admin/inventory_bins#show
#                                          PATCH      /admin/inventory_bins/:id(.:format)                                                      admin/inventory_bins#update
#                                          PUT        /admin/inventory_bins/:id(.:format)                                                      admin/inventory_bins#update
#                                          DELETE     /admin/inventory_bins/:id(.:format)                                                      admin/inventory_bins#destroy
#               admin_inventory_categories GET        /admin/inventory_categories(.:format)                                                    admin/inventory_categories#index
#                                          POST       /admin/inventory_categories(.:format)                                                    admin/inventory_categories#create
#             new_admin_inventory_category GET        /admin/inventory_categories/new(.:format)                                                admin/inventory_categories#new
#            edit_admin_inventory_category GET        /admin/inventory_categories/:id/edit(.:format)                                           admin/inventory_categories#edit
#                 admin_inventory_category GET        /admin/inventory_categories/:id(.:format)                                                admin/inventory_categories#show
#                                          PATCH      /admin/inventory_categories/:id(.:format)                                                admin/inventory_categories#update
#                                          PUT        /admin/inventory_categories/:id(.:format)                                                admin/inventory_categories#update
#                                          DELETE     /admin/inventory_categories/:id(.:format)                                                admin/inventory_categories#destroy
#           duplicate_admin_inventory_item GET        /admin/inventory_items/:id/duplicate(.:format)                                           admin/inventory_items#duplicate
#                    admin_inventory_items GET        /admin/inventory_items(.:format)                                                         admin/inventory_items#index
#                                          POST       /admin/inventory_items(.:format)                                                         admin/inventory_items#create
#                 new_admin_inventory_item GET        /admin/inventory_items/new(.:format)                                                     admin/inventory_items#new
#                edit_admin_inventory_item GET        /admin/inventory_items/:id/edit(.:format)                                                admin/inventory_items#edit
#                     admin_inventory_item GET        /admin/inventory_items/:id(.:format)                                                     admin/inventory_items#show
#                                          PATCH      /admin/inventory_items/:id(.:format)                                                     admin/inventory_items#update
#                                          PUT        /admin/inventory_items/:id(.:format)                                                     admin/inventory_items#update
#                                          DELETE     /admin/inventory_items/:id(.:format)                                                     admin/inventory_items#destroy
#               admin_paper_trail_versions GET        /admin/paper_trail_versions(.:format)                                                    admin/paper_trail_versions#index
#                admin_paper_trail_version GET        /admin/paper_trail_versions/:id(.:format)                                                admin/paper_trail_versions#show
#                  remove_badge_admin_user POST       /admin/users/:id/remove_badge(.:format)                                                  admin/users#remove_badge
#                   begin_merge_admin_user GET        /admin/users/:id/begin_merge(.:format)                                                   admin/users#begin_merge
#                  review_merge_admin_user GET        /admin/users/:id/review_merge(.:format)                                                  admin/users#review_merge
#                         merge_admin_user POST       /admin/users/:id/merge(.:format)                                                         admin/users#merge
#                merge_complete_admin_user GET        /admin/users/:id/merge_complete(.:format)                                                admin/users#merge_complete
#                              admin_users GET        /admin/users(.:format)                                                                   admin/users#index
#                                          POST       /admin/users(.:format)                                                                   admin/users#create
#                           new_admin_user GET        /admin/users/new(.:format)                                                               admin/users#new
#                          edit_admin_user GET        /admin/users/:id/edit(.:format)                                                          admin/users#edit
#                               admin_user GET        /admin/users/:id(.:format)                                                               admin/users#show
#                                          PATCH      /admin/users/:id(.:format)                                                               admin/users#update
#                                          PUT        /admin/users/:id(.:format)                                                               admin/users#update
#                                          DELETE     /admin/users/:id(.:format)                                                               admin/users#destroy
#                            admin_waivers GET        /admin/waivers(.:format)                                                                 admin/waivers#index
#                        edit_admin_waiver GET        /admin/waivers/:id/edit(.:format)                                                        admin/waivers#edit
#                             admin_waiver GET        /admin/waivers/:id(.:format)                                                             admin/waivers#show
#                                          PATCH      /admin/waivers/:id(.:format)                                                             admin/waivers#update
#                                          PUT        /admin/waivers/:id(.:format)                                                             admin/waivers#update
#                                          DELETE     /admin/waivers/:id(.:format)                                                             admin/waivers#destroy
#           admin_wireless_credential_sets GET        /admin/wireless_credential_sets(.:format)                                                admin/wireless_credential_sets#index
#                                          POST       /admin/wireless_credential_sets(.:format)                                                admin/wireless_credential_sets#create
#        new_admin_wireless_credential_set GET        /admin/wireless_credential_sets/new(.:format)                                            admin/wireless_credential_sets#new
#       edit_admin_wireless_credential_set GET        /admin/wireless_credential_sets/:id/edit(.:format)                                       admin/wireless_credential_sets#edit
#            admin_wireless_credential_set GET        /admin/wireless_credential_sets/:id(.:format)                                            admin/wireless_credential_sets#show
#                                          PATCH      /admin/wireless_credential_sets/:id(.:format)                                            admin/wireless_credential_sets#update
#                                          PUT        /admin/wireless_credential_sets/:id(.:format)                                            admin/wireless_credential_sets#update
#                                          DELETE     /admin/wireless_credential_sets/:id(.:format)                                            admin/wireless_credential_sets#destroy
#                           admin_comments GET        /admin/comments(.:format)                                                                admin/comments#index
#                                          POST       /admin/comments(.:format)                                                                admin/comments#create
#                            admin_comment GET        /admin/comments/:id(.:format)                                                            admin/comments#show
#                                          DELETE     /admin/comments/:id(.:format)                                                            admin/comments#destroy
#                                     root GET        /                                                                                        home#home
#                          webhooks_stripe POST       /webhooks/stripe(.:format)                                                               webhooks/stripe#webhook
#                   webhooks_waiverforever POST       /webhooks/waiverforever(.:format)                                                        webhooks/waiver_forever#webhook
#                            frontend_demo GET        /frontend-demo(.:format)                                                                 frontend#frontend
#                                  nfc_bin GET        /nfc/bins/:id(.:format)                                                                  nfc#bin
#          api_badge_writers_firmware_blob GET        /api/badge_writers/firmware_blob(.:format)                                               api/badge_writers#firmware_blob
#   api_badge_writers_wireless_credentials GET        /api/badge_writers/wireless_credentials(.:format)                                        api/badge_writers#wireless_credentials
#                api_badge_writers_program POST       /api/badge_writers/program(.:format)                                                     api/badge_writers#program
#            api_badge_readers_access_list GET        /api/badge_readers/access_list(.:format)                                                 api/badge_readers#access_list
#     api_badge_readers_binary_access_list GET        /api/badge_readers/binary_access_list(.:format)                                          api/badge_readers#binary_access_list
#          api_badge_readers_firmware_blob GET        /api/badge_readers/firmware_blob(.:format)                                               api/badge_readers#firmware_blob
#   api_badge_readers_wireless_credentials GET        /api/badge_readers/wireless_credentials(.:format)                                        api/badge_readers#wireless_credentials
#           api_badge_readers_record_scans POST       /api/badge_readers/record_scans(.:format)                                                api/badge_readers#record_scans
#     api_badge_readers_record_binary_scan POST       /api/badge_readers/record_binary_scan(.:format)                                          api/badge_readers#record_binary_scan
#            rails_postmark_inbound_emails POST       /rails/action_mailbox/postmark/inbound_emails(.:format)                                  action_mailbox/ingresses/postmark/inbound_emails#create
#               rails_relay_inbound_emails POST       /rails/action_mailbox/relay/inbound_emails(.:format)                                     action_mailbox/ingresses/relay/inbound_emails#create
#            rails_sendgrid_inbound_emails POST       /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                  action_mailbox/ingresses/sendgrid/inbound_emails#create
#      rails_mandrill_inbound_health_check GET        /rails/action_mailbox/mandrill/inbound_emails(.:format)                                  action_mailbox/ingresses/mandrill/inbound_emails#health_check
#            rails_mandrill_inbound_emails POST       /rails/action_mailbox/mandrill/inbound_emails(.:format)                                  action_mailbox/ingresses/mandrill/inbound_emails#create
#             rails_mailgun_inbound_emails POST       /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                              action_mailbox/ingresses/mailgun/inbound_emails#create
#           rails_conductor_inbound_emails GET        /rails/conductor/action_mailbox/inbound_emails(.:format)                                 rails/conductor/action_mailbox/inbound_emails#index
#                                          POST       /rails/conductor/action_mailbox/inbound_emails(.:format)                                 rails/conductor/action_mailbox/inbound_emails#create
#        new_rails_conductor_inbound_email GET        /rails/conductor/action_mailbox/inbound_emails/new(.:format)                             rails/conductor/action_mailbox/inbound_emails#new
#       edit_rails_conductor_inbound_email GET        /rails/conductor/action_mailbox/inbound_emails/:id/edit(.:format)                        rails/conductor/action_mailbox/inbound_emails#edit
#            rails_conductor_inbound_email GET        /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#show
#                                          PATCH      /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#update
#                                          PUT        /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#update
#                                          DELETE     /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#destroy
#    rails_conductor_inbound_email_reroute POST       /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                      rails/conductor/action_mailbox/reroutes#create
#                       rails_service_blob GET        /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
#                rails_blob_representation GET        /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
#                       rails_disk_service GET        /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
#                update_rails_disk_service PUT        /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
#                     rails_direct_uploads POST       /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create
