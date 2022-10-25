# frozen_string_literal: true

module Api
  module V1
    module Admin
      class InvitationsController < ApiController
        before_action only: %i[create] do
          ensure_authorized('ManageUsers')
        end

        # POST /api/v1/admin/invitations
        def create
          params[:invitations][:emails].split(',').each do |email|
            invitation = Invitation.find_or_initialize_by(email:, provider: current_provider).tap do |i|
              i.updated_at = Time.zone.now
              i.save!
            end

            UserMailer.with(
              email:,
              name: current_user.name,
              signup_url: root_url(inviteToken: invitation.token)
            ).invitation_email.deliver_later
          rescue StandardError => e
            logger.error "Failed to send invitation to #{email} - #{e}"
          end

          render_data status: :ok
        rescue StandardError => e
          logger.error "Failed to send invitations to #{params[:invitations][:emails]} - #{e}"
          render_error status: :bad_request
        end
      end
    end
  end
end
