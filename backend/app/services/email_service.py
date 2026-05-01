from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from app.core.config import settings

class EmailService:
    def __init__(self):
        self.client = SendGridAPIClient(settings.SENDGRID_API_KEY)
    
    async def send_welcome_email(self, to_email: str, name: str):
        """Send welcome email to new users"""
        message = Mail(
            from_email=settings.FROM_EMAIL,
            to_emails=to_email,
            subject='Welcome to AI Workout Tracker!',
            html_content=f'<h1>Welcome {name}!</h1><p>Start your fitness journey...</p>'
        )
        try:
            self.client.send(message)
        except Exception as e:
            print(f"Email error: {e}")