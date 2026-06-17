import datetime
import os.path
import json

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# If modifying these scopes, delete the file token.json.
SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]


def main():
    if os.environ.get("QUICKSHELL_DISABLE_CALENDAR") == "1":
        print(json.dumps([]))
        return

    """Shows basic usage of the Google Calendar API.
    Prints the start and name of the next 10 events on the user's calendar.
    """
    creds = None
    # The file token.json stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    script_dir = os.path.dirname(os.path.realpath(__file__))
    cache_dir = os.path.expanduser("~/.cache/quickshell")
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)
    
    token_path = os.path.join(cache_dir, "token.json")
    credentials_path = os.path.join(script_dir, "credentials.json")

    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                credentials_path, SCOPES
            )
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open(token_path, "w") as token:
            token.write(creds.to_json())

    try:
        service = build("calendar", "v3", credentials=creds)

        # Call the Calendar API
        today = datetime.date.today()
        time_min = datetime.datetime.combine(today, datetime.time.min).isoformat() + "Z"
        time_max = datetime.datetime.combine(today, datetime.time.max).isoformat() + "Z"

        events_result = (
            service.events()
            .list(
                calendarId="primary",
                timeMin=time_min,
                timeMax=time_max,
                singleEvents=True,
                orderBy="startTime",
            )
            .execute()
        )
        events = events_result.get("items", [])

        output_events = []
        if not events:
            pass
        else:
            for event in events:
                start_time = event["start"].get("dateTime", event["start"].get("date"))
                output_events.append({
                    "summary": event["summary"],
                    "start": start_time,
                    "hangoutLink": event.get("hangoutLink")
                })

        print(json.dumps(output_events, indent=4))
        
    except HttpError as error:
        print(json.dumps({"error": f"An error occurred: {error}"}))

if __name__ == "__main__":
    main()