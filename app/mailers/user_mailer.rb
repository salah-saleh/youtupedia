class UserMailer < ApplicationMailer
  def email_verification
    @user = params[:user]
    @verification_url = verify_email_url(token: @user.email_verification_token)

    mail(
      to: @user.email_address,
      subject: "Please verify your email address"
    )
  end
end
