import os
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from app.core.config import settings

class EmailService:
    def __init__(self):
        self.api_key = settings.SENDGRID_API_KEY
        self.from_email = settings.FROM_EMAIL
        self.client = SendGridAPIClient(self.api_key) if self.api_key and self.api_key != "SG_dummy" else None

    def send_password_reset_email(self, email: str, token: str):
        if not self.client:
            print(f"--- EMAIL NOT SENT (NO API KEY) ---")
            print(f"To: {email}")
            print(f"Token: {token}")
            print(f"-----------------------------------")
            return

        # In a real app, this would be a URL pointing to the frontend
        # For now, we'll just send the token as a "code"
        message = Mail(
            from_email=self.from_email,
            to_emails=email,
            subject='Rhockai - Password Reset Request',
            plain_text_content=f'You requested a password reset for your Rhockai account.\n\n'
                               f'Please use the following token in the app to reset your password:\n\n'
                               f'{token}\n\n'
                               f'This token will expire in 15 minutes.\n\n'
                               f'If you did not request this, please ignore this email.'
        )
        try:
            response = self.client.send(message)
            return response.status_code
        except Exception as e:
            print(f"Error sending email: {str(e)}")
            return None

email_service = EmailService()