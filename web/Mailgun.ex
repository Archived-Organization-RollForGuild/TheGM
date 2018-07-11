defmodule Thegm.Mailgun do
  import Bamboo.Email

  def email_confirmation_email(email, code) do
    base = Application.get_env(:thegm, :web_url)
    case File.read("resources/activation_email.html") do
      {:ok, body} ->
        new_email(
          to: email,
          from: "no-reply@rollforguild.com",
          subject: "Roll For Guild: Email Verification",
          html_body: String.replace(body, "[[link]]", base <> "/confirmation/" <> code)
        )
    end
  end

  def email_change_email(email, code) do
    base = Application.get_env(:thegm, :web_url)
    case File.read("resources/activation_email.html") do
      {:ok, body} ->
        body = String.replace(body, "[[link]]", base <> "/email-update-confirmation/" <> code)

        new_email(
          to: email,
          from: "no-reply@rollforguild.com",
          subject: "Roll For Guild: Email Address Change",
          html_body: body
        )
    end
  end

  def email_rollback_email(email, username, code) do
    base = Application.get_env(:thegm, :web_url)
    case File.read("resources/email_rollback_email.html") do
      {:ok, body} ->
        body = String.replace(body, "[[username]]", username)
        body = String.replace(body, "[[link]]", base <> "/email-rollback/" <> code)

        new_email(
          to: email,
          from: "no-reply@rollforguild.com",
          subject: "Roll For Guild: Email Address Change",
          html_body: body
        )
    end
  end

  def email_password_reset(email, code) do
    base = Application.get_env(:thegm, :web_url)
    case File.read("resources/password_reset_email.html") do
      {:ok, body} ->
        new_email(
          to: email,
          from: "no-reply@rollforguild.com",
          subject: "Roll For Guild: Password Reset Requested",
          html_body: String.replace(body, "[[link]]", base <> "/reset/" <> code)
        )
    end
  end
end
# credo:disable-for-this-file
