class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

    def google_oauth2
        handle_auth("Google")
    end

    def twitter2
        handle_auth("Twitter")
    end

    def facebook
        handle_auth("Facebook")
    end

    def linkedin
        handle_auth("LinkedIn")
    end

    private

    def handle_auth(kind)
        @user = User.from_omniauth(request.env["omniauth.auth"])
        if @user.persisted?
            flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: kind
            sign_in_and_redirect @user, event: :authentication
        else
            session["devise.auth_data"] = request.env["omniauth.auth"].except(:extra)
            redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
        end
    end
end
