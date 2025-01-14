class UserMailer < ApplicationMailer
  def email_verification
    @user = params[:user]
    @verification_url = verify_email_url(token: @user.email_verification_token)

    # Attach the logo for the email
    attachments.inline['youtupedia.png'] = File.read(Rails.root.join('app/assets/images/youtupedia.png'))

    mail(
      to: @user.email_address,
      subject: "Please verify your email address"
    )
  end

  def password_reset
    @user = params[:user]
    @reset_url = edit_password_url(token: @user.signed_id(purpose: :password_reset, expires_in: 4.hours))

    # Attach the logo for the email
    attachments.inline['youtupedia.png'] = File.read(Rails.root.join('app/assets/images/youtupedia.png'))

    mail(
      to: @user.email_address,
      subject: "Reset your password"
    )
  end
end
