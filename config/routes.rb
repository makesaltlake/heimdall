Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'home#home'
end

# == Route Map
#
#                                Prefix Verb       URI Pattern                                                                              Controller#Action
#                      new_user_session GET        /admin/login(.:format)                                                                   active_admin/devise/sessions#new
#                          user_session POST       /admin/login(.:format)                                                                   active_admin/devise/sessions#create
#                  destroy_user_session DELETE|GET /admin/logout(.:format)                                                                  active_admin/devise/sessions#destroy
#                     new_user_password GET        /admin/password/new(.:format)                                                            active_admin/devise/passwords#new
#                    edit_user_password GET        /admin/password/edit(.:format)                                                           active_admin/devise/passwords#edit
#                         user_password PATCH      /admin/password(.:format)                                                                active_admin/devise/passwords#update
#                                       PUT        /admin/password(.:format)                                                                active_admin/devise/passwords#update
#                                       POST       /admin/password(.:format)                                                                active_admin/devise/passwords#create
#                       new_user_unlock GET        /admin/unlock/new(.:format)                                                              active_admin/devise/unlocks#new
#                           user_unlock GET        /admin/unlock(.:format)                                                                  active_admin/devise/unlocks#show
#                                       POST       /admin/unlock(.:format)                                                                  active_admin/devise/unlocks#create
#                            admin_root GET        /admin(.:format)                                                                         admin/dashboard#index
#                  admin_certifications GET        /admin/certifications(.:format)                                                          admin/certifications#index
#                                       POST       /admin/certifications(.:format)                                                          admin/certifications#create
#               new_admin_certification GET        /admin/certifications/new(.:format)                                                      admin/certifications#new
#              edit_admin_certification GET        /admin/certifications/:id/edit(.:format)                                                 admin/certifications#edit
#                   admin_certification GET        /admin/certifications/:id(.:format)                                                      admin/certifications#show
#                                       PATCH      /admin/certifications/:id(.:format)                                                      admin/certifications#update
#                                       PUT        /admin/certifications/:id(.:format)                                                      admin/certifications#update
#                                       DELETE     /admin/certifications/:id(.:format)                                                      admin/certifications#destroy
#                       admin_dashboard GET        /admin/dashboard(.:format)                                                               admin/dashboard#index
#              admin_badge_reader_scans GET        /admin/badge_reader_scans(.:format)                                                      admin/badge_reader_scans#index
#               admin_badge_reader_scan GET        /admin/badge_reader_scans/:id(.:format)                                                  admin/badge_reader_scans#show
#                   admin_badge_readers GET        /admin/badge_readers(.:format)                                                           admin/badge_readers#index
#                                       POST       /admin/badge_readers(.:format)                                                           admin/badge_readers#create
#                new_admin_badge_reader GET        /admin/badge_readers/new(.:format)                                                       admin/badge_readers#new
#               edit_admin_badge_reader GET        /admin/badge_readers/:id/edit(.:format)                                                  admin/badge_readers#edit
#                    admin_badge_reader GET        /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#show
#                                       PATCH      /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#update
#                                       PUT        /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#update
#                                       DELETE     /admin/badge_readers/:id(.:format)                                                       admin/badge_readers#destroy
#       admin_certification_instructors GET        /admin/certification_instructors(.:format)                                               admin/certification_instructors#index
#                                       POST       /admin/certification_instructors(.:format)                                               admin/certification_instructors#create
#    new_admin_certification_instructor GET        /admin/certification_instructors/new(.:format)                                           admin/certification_instructors#new
#        admin_certification_instructor GET        /admin/certification_instructors/:id(.:format)                                           admin/certification_instructors#show
#                                       DELETE     /admin/certification_instructors/:id(.:format)                                           admin/certification_instructors#destroy
#   revoke_admin_certification_issuance GET        /admin/certification_issuances/:id/revoke(.:format)                                      admin/certification_issuances#revoke
#                                       POST       /admin/certification_issuances/:id/revoke(.:format)                                      admin/certification_issuances#revoke
#         admin_certification_issuances GET        /admin/certification_issuances(.:format)                                                 admin/certification_issuances#index
#                                       POST       /admin/certification_issuances(.:format)                                                 admin/certification_issuances#create
#      new_admin_certification_issuance GET        /admin/certification_issuances/new(.:format)                                             admin/certification_issuances#new
#     edit_admin_certification_issuance GET        /admin/certification_issuances/:id/edit(.:format)                                        admin/certification_issuances#edit
#          admin_certification_issuance GET        /admin/certification_issuances/:id(.:format)                                             admin/certification_issuances#show
#                                       PATCH      /admin/certification_issuances/:id(.:format)                                             admin/certification_issuances#update
#                                       PUT        /admin/certification_issuances/:id(.:format)                                             admin/certification_issuances#update
#       admin_badge_reader_manual_users GET        /admin/badge_reader_manual_users(.:format)                                               admin/badge_reader_manual_users#index
#                                       POST       /admin/badge_reader_manual_users(.:format)                                               admin/badge_reader_manual_users#create
#    new_admin_badge_reader_manual_user GET        /admin/badge_reader_manual_users/new(.:format)                                           admin/badge_reader_manual_users#new
#   edit_admin_badge_reader_manual_user GET        /admin/badge_reader_manual_users/:id/edit(.:format)                                      admin/badge_reader_manual_users#edit
#        admin_badge_reader_manual_user GET        /admin/badge_reader_manual_users/:id(.:format)                                           admin/badge_reader_manual_users#show
#                                       PATCH      /admin/badge_reader_manual_users/:id(.:format)                                           admin/badge_reader_manual_users#update
#                                       PUT        /admin/badge_reader_manual_users/:id(.:format)                                           admin/badge_reader_manual_users#update
#                                       DELETE     /admin/badge_reader_manual_users/:id(.:format)                                           admin/badge_reader_manual_users#destroy
#                           admin_users GET        /admin/users(.:format)                                                                   admin/users#index
#                                       POST       /admin/users(.:format)                                                                   admin/users#create
#                        new_admin_user GET        /admin/users/new(.:format)                                                               admin/users#new
#                       edit_admin_user GET        /admin/users/:id/edit(.:format)                                                          admin/users#edit
#                            admin_user GET        /admin/users/:id(.:format)                                                               admin/users#show
#                                       PATCH      /admin/users/:id(.:format)                                                               admin/users#update
#                                       PUT        /admin/users/:id(.:format)                                                               admin/users#update
#                                       DELETE     /admin/users/:id(.:format)                                                               admin/users#destroy
#     admin_badge_reader_certifications GET        /admin/badge_reader_certifications(.:format)                                             admin/badge_reader_certifications#index
#                                       POST       /admin/badge_reader_certifications(.:format)                                             admin/badge_reader_certifications#create
#  new_admin_badge_reader_certification GET        /admin/badge_reader_certifications/new(.:format)                                         admin/badge_reader_certifications#new
# edit_admin_badge_reader_certification GET        /admin/badge_reader_certifications/:id/edit(.:format)                                    admin/badge_reader_certifications#edit
#      admin_badge_reader_certification GET        /admin/badge_reader_certifications/:id(.:format)                                         admin/badge_reader_certifications#show
#                                       PATCH      /admin/badge_reader_certifications/:id(.:format)                                         admin/badge_reader_certifications#update
#                                       PUT        /admin/badge_reader_certifications/:id(.:format)                                         admin/badge_reader_certifications#update
#                                       DELETE     /admin/badge_reader_certifications/:id(.:format)                                         admin/badge_reader_certifications#destroy
#                        admin_comments GET        /admin/comments(.:format)                                                                admin/comments#index
#                                       POST       /admin/comments(.:format)                                                                admin/comments#create
#                         admin_comment GET        /admin/comments/:id(.:format)                                                            admin/comments#show
#                                       DELETE     /admin/comments/:id(.:format)                                                            admin/comments#destroy
#                                  root GET        /                                                                                        home#home
#         rails_postmark_inbound_emails POST       /rails/action_mailbox/postmark/inbound_emails(.:format)                                  action_mailbox/ingresses/postmark/inbound_emails#create
#            rails_relay_inbound_emails POST       /rails/action_mailbox/relay/inbound_emails(.:format)                                     action_mailbox/ingresses/relay/inbound_emails#create
#         rails_sendgrid_inbound_emails POST       /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                  action_mailbox/ingresses/sendgrid/inbound_emails#create
#   rails_mandrill_inbound_health_check GET        /rails/action_mailbox/mandrill/inbound_emails(.:format)                                  action_mailbox/ingresses/mandrill/inbound_emails#health_check
#         rails_mandrill_inbound_emails POST       /rails/action_mailbox/mandrill/inbound_emails(.:format)                                  action_mailbox/ingresses/mandrill/inbound_emails#create
#          rails_mailgun_inbound_emails POST       /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                              action_mailbox/ingresses/mailgun/inbound_emails#create
#        rails_conductor_inbound_emails GET        /rails/conductor/action_mailbox/inbound_emails(.:format)                                 rails/conductor/action_mailbox/inbound_emails#index
#                                       POST       /rails/conductor/action_mailbox/inbound_emails(.:format)                                 rails/conductor/action_mailbox/inbound_emails#create
#     new_rails_conductor_inbound_email GET        /rails/conductor/action_mailbox/inbound_emails/new(.:format)                             rails/conductor/action_mailbox/inbound_emails#new
#    edit_rails_conductor_inbound_email GET        /rails/conductor/action_mailbox/inbound_emails/:id/edit(.:format)                        rails/conductor/action_mailbox/inbound_emails#edit
#         rails_conductor_inbound_email GET        /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#show
#                                       PATCH      /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#update
#                                       PUT        /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#update
#                                       DELETE     /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                             rails/conductor/action_mailbox/inbound_emails#destroy
# rails_conductor_inbound_email_reroute POST       /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                      rails/conductor/action_mailbox/reroutes#create
#                    rails_service_blob GET        /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
#             rails_blob_representation GET        /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
#                    rails_disk_service GET        /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
#             update_rails_disk_service PUT        /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
#                  rails_direct_uploads POST       /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create
